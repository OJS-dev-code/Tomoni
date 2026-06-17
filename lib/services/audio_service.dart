import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../config/api_config.dart';
import 'api_loading_service.dart';
import 'api_service.dart';
import 'audio_blob_reader.dart';
import 'auth_service.dart';
import 'microphone_permission_service.dart';

/// Whisper가 무음·깨진 오디오에서 자주 내는 환각 문구 (웹 STT 오류 시).
const _whisperHallucinationPhrases = [
  'ご視聴ありがとうございました',
  'ご視聴ありがとうございます',
  'ありがとうございました',
  'ありがとうございます',
  'ご清聴ありがとうございました',
  '字幕',
  'Subtitles',
  'Thank you for watching',
];

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  String? _recordingUploadFilename;
  String? _loadedAudioUrl;
  final Map<String, String> _ttsUrlCache = {};
  static const _maxTtsCacheEntries = 50;

  bool get isRecording => _isRecording;

  double speedFromSetting(String aiSpeedSetting) {
    if (aiSpeedSetting.contains('천천히')) {
      return 0.8;
    }
    return 1.0;
  }

  double adjustedSpeedFromSetting(String aiSpeedSetting) {
    if (aiSpeedSetting.contains('천천히')) {
      return 1.2;
    }
    return 0.8;
  }

  Future<String> _token() async {
    final token = await AuthService.instance.getIdToken();
    if (token == null) {
      throw ApiException('로그인이 필요합니다.');
    }
    return token;
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    final granted = kIsWeb
        ? await _recorder.hasPermission()
        : await MicrophonePermissionService.request();
    if (!granted) {
      throw ApiException(MicrophonePermissionService.deniedMessage);
    }

    if (!kIsWeb) {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw ApiException(MicrophonePermissionService.deniedMessage);
      }
    }

    if (kIsWeb) {
      final webSetup = await _webRecordingSetup();
      _recordingUploadFilename = webSetup.uploadFilename;
      await _recorder.start(webSetup.config, path: '');
    } else {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/stt_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingUploadFilename = 'audio.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100),
        path: path,
      );
    }
    _isRecording = true;
  }

  /// Chrome 등 웹 브라우저는 AAC m4a 대신 wav/webm을 사용합니다.
  Future<({RecordConfig config, String uploadFilename})> _webRecordingSetup() async {
    if (await _recorder.isEncoderSupported(AudioEncoder.wav)) {
      return (
        config: const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
        ),
        uploadFilename: 'audio.wav',
      );
    }

    return (
      config: const RecordConfig(sampleRate: 44100),
      uploadFilename: 'audio.webm',
    );
  }

  Future<String> stopRecordingAndTranscribe() async {
    if (!_isRecording) {
      throw ApiException('녹음이 시작되지 않았습니다.');
    }

    final path = await _recorder.stop();
    _isRecording = false;

    if (path == null || path.isEmpty) {
      _recordingUploadFilename = null;
      throw ApiException('녹음 파일을 저장하지 못했습니다.');
    }

    try {
      final bytes = await _readAudioBytes(path);
      if (bytes.length < 1024) {
        throw ApiException('녹음이 너무 짧습니다. 조금 더 길게 말해주세요.');
      }

      final filename = _recordingUploadFilename ??
          (kIsWeb ? 'audio.webm' : 'audio.m4a');
      return transcribe(bytes, filename: filename);
    } finally {
      _recordingUploadFilename = null;
    }
  }

  Future<List<int>> _readAudioBytes(String path) async {
    if (kIsWeb) {
      try {
        return await readRecordingBytes(path);
      } catch (_) {
        throw ApiException('녹음 데이터를 읽지 못했습니다.');
      }
    }
    return File(path).readAsBytes();
  }

  bool _isLikelyWhisperHallucination(String text) {
    final normalized = text.replaceAll(RegExp(r'\s'), '');
    for (final phrase in _whisperHallucinationPhrases) {
      if (normalized.contains(phrase.replaceAll(RegExp(r'\s'), ''))) {
        return true;
      }
    }
    return false;
  }

  Future<String> transcribe(List<int> bytes, {String filename = 'audio.m4a'}) async {
    final token = await _token();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/audio/stt?language=ja');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    ApiLoadingService.begin();
    try {
      final streamed = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw ApiException(_errorMessage(response));
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (body['text'] as String? ?? '').trim();
      if (text.isEmpty) {
        throw ApiException('음성을 인식하지 못했습니다. 다시 말해주세요.');
      }
      if (_isLikelyWhisperHallucination(text)) {
        throw ApiException(
          '음성을 제대로 인식하지 못했습니다. 마이크를 확인하고 다시 말해주세요.',
        );
      }
      return text;
    } on TimeoutException {
      throw ApiException('음성 인식 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.');
    } on http.ClientException {
      throw ApiException('서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      ApiLoadingService.end();
    }
  }

  /// 텍스트·음성 URL 확보 후 재생 직전까지 버퍼링합니다.
  Future<String> prepareAiTts(
    String text, {
    required double speed,
    String? voice,
    String? preloadedAudioUrl,
  }) async {
    if (text.trim().isEmpty) {
      throw ApiException('재생할 텍스트가 없습니다.');
    }

    final cacheKey = _ttsCacheKey(text, speed, voice);
    var audioUrl = preloadedAudioUrl?.trim() ?? '';
    if (audioUrl.isEmpty) {
      audioUrl = _ttsUrlCache[cacheKey] ?? '';
    }
    if (audioUrl.isEmpty) {
      audioUrl = await _requestTtsUrl(text, speed: speed, voice: voice);
    }
    if (audioUrl.isNotEmpty) {
      _rememberTtsUrl(cacheKey, audioUrl);
    }

    await _loadAudioUrl(audioUrl);
    _loadedAudioUrl = audioUrl;
    return audioUrl;
  }

  Future<void> playTts(
    String text, {
    double speed = 1.0,
    String? voice,
    String? preloadedAudioUrl,
  }) async {
    if (text.trim().isEmpty) return;

    final cacheKey = _ttsCacheKey(text, speed, voice);
    var audioUrl = preloadedAudioUrl?.trim() ?? '';
    if (audioUrl.isEmpty) {
      audioUrl = _ttsUrlCache[cacheKey] ?? '';
    }
    if (audioUrl.isEmpty) {
      audioUrl = await _requestTtsUrl(text, speed: speed, voice: voice);
    }
    if (audioUrl.isNotEmpty) {
      _rememberTtsUrl(cacheKey, audioUrl);
    }

    final alreadyLoaded = _loadedAudioUrl == audioUrl &&
        _player.processingState != ProcessingState.idle;
    if (!alreadyLoaded) {
      await _loadAudioUrl(audioUrl);
    } else {
      await _player.seek(Duration.zero);
    }
    _loadedAudioUrl = audioUrl;

    await _player.play();
    await _player.processingStateStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );
  }

  /// 서버에서 받은 TTS URL을 미리 버퍼링합니다 (말풍선 표시 전 호출).
  Future<void> preloadAudioUrl(String audioUrl) async {
    final trimmed = audioUrl.trim();
    if (trimmed.isEmpty) return;
    await _loadAudioUrl(trimmed);
    _loadedAudioUrl = trimmed;
  }

  String _ttsCacheKey(String text, double speed, String? voice) {
    final normalizedVoice = voice?.trim() ?? '';
    return '${text.trim()}|$normalizedVoice|${speed.toStringAsFixed(2)}';
  }

  void _rememberTtsUrl(String cacheKey, String audioUrl) {
    if (_ttsUrlCache.length >= _maxTtsCacheEntries) {
      _ttsUrlCache.remove(_ttsUrlCache.keys.first);
    }
    _ttsUrlCache[cacheKey] = audioUrl;
  }

  Future<String> _requestTtsUrl(
    String text, {
    required double speed,
    String? voice,
  }) async {
    final token = await _token();
    final payload = <String, dynamic>{
      'text': text,
      'speed': speed,
    };
    if (voice != null && voice.isNotEmpty) {
      payload['voice'] = voice;
    }

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/audio/tts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
    } on http.ClientException {
      throw ApiException('서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.');
    }

    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final audioUrl = body['audio_url'] as String? ?? '';
    if (audioUrl.isEmpty) {
      throw ApiException('음성 URL을 받지 못했습니다.');
    }
    return audioUrl;
  }

  Future<void> _loadAudioUrl(String audioUrl) async {
    await _player.stop();
    if (audioUrl.startsWith('data:')) {
      final uri = Uri.parse(audioUrl);
      final bytes = uri.data?.contentAsBytes();
      if (bytes == null || bytes.isEmpty) {
        throw ApiException('음성 데이터를 읽지 못했습니다.');
      }
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'),
        ),
      );
    } else {
      await _player.setUrl(audioUrl);
    }
    await _player.processingStateStream.firstWhere(
      (state) =>
          state == ProcessingState.ready ||
          state == ProcessingState.completed,
    );
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
    _recordingUploadFilename = null;
    await _recorder.dispose();
    await _player.dispose();
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is String) {
        return detail;
      }
    } catch (_) {}
    return '음성 요청에 실패했습니다. (${response.statusCode})';
  }
}
