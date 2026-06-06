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
import 'auth_service.dart';
import 'microphone_permission_service.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;

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

    final granted = await MicrophonePermissionService.request();
    if (!granted) {
      throw ApiException(MicrophonePermissionService.deniedMessage);
    }

    if (!kIsWeb) {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw ApiException(MicrophonePermissionService.deniedMessage);
      }
    }

    final dir = kIsWeb ? null : await getTemporaryDirectory();
    final path = kIsWeb
        ? ''
        : '${dir!.path}/stt_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100),
      path: path,
    );
    _isRecording = true;
  }

  Future<String> stopRecordingAndTranscribe() async {
    if (!_isRecording) {
      throw ApiException('녹음이 시작되지 않았습니다.');
    }

    final path = await _recorder.stop();
    _isRecording = false;

    if (path == null || path.isEmpty) {
      throw ApiException('녹음 파일을 저장하지 못했습니다.');
    }

    final bytes = await _readAudioBytes(path);
    return transcribe(bytes, filename: 'audio.m4a');
  }

  Future<List<int>> _readAudioBytes(String path) async {
    if (kIsWeb) {
      final response = await http.get(Uri.parse(path));
      return response.bodyBytes;
    }
    return File(path).readAsBytes();
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
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw ApiException(_errorMessage(response));
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (body['text'] as String? ?? '').trim();
      if (text.isEmpty) {
        throw ApiException('음성을 인식하지 못했습니다. 다시 말해주세요.');
      }
      return text;
    } on http.ClientException {
      throw ApiException(
        '서버에 연결할 수 없습니다. (현재 주소: ${ApiConfig.baseUrl})',
      );
    } finally {
      ApiLoadingService.end();
    }
  }

  Future<void> playTts(
    String text, {
    double speed = 1.0,
    String? voice,
  }) async {
    if (text.trim().isEmpty) return;

    final token = await _token();
    final payload = <String, dynamic>{
      'text': text,
      'speed': speed,
    };
    if (voice != null && voice.isNotEmpty) {
      payload['voice'] = voice;
    }

    ApiLoadingService.begin();
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
      throw ApiException(
        '서버에 연결할 수 없습니다. (현재 주소: ${ApiConfig.baseUrl})',
      );
    } finally {
      ApiLoadingService.end();
    }

    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final audioUrl = body['audio_url'] as String? ?? '';
    if (audioUrl.isEmpty) {
      throw ApiException('음성 URL을 받지 못했습니다.');
    }

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
    await _player.play();
    await _player.processingStateStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
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
