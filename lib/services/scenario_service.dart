import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class SessionEndResult {
  SessionEndResult({
    required this.sessionId,
    required this.status,
    this.noteId,
  });

  final String sessionId;
  final String status;
  final String? noteId;

  factory SessionEndResult.fromJson(Map<String, dynamic> json) {
    return SessionEndResult(
      sessionId: json['sessionId'] as String? ?? '',
      status: json['status'] as String? ?? 'ended',
      noteId: json['noteId'] as String?,
    );
  }
}

class ScenarioSession {
  ScenarioSession({
    required this.sessionId,
    required this.topic,
    required this.goals,
    required this.aiRole,
    required this.userRole,
    required this.location,
    required this.ttsVoice,
    required this.speakerFirst,
    required this.sceneNote,
    this.openingMessage,
  });

  final String sessionId;
  final String topic;
  final List<String> goals;
  final String aiRole;
  final String userRole;
  final String location;
  final String ttsVoice;
  final String speakerFirst;
  final String sceneNote;
  final Map<String, dynamic>? openingMessage;

  bool get isUserFirst => speakerFirst == 'user';

  factory ScenarioSession.fromJson(Map<String, dynamic> json) {
    final opening = json['openingMessage'];
    return ScenarioSession(
      sessionId: json['sessionId'] as String,
      topic: json['topic'] as String,
      goals: List<String>.from(json['goals'] ?? []),
      aiRole: json['aiRole'] as String? ?? '',
      userRole: json['userRole'] as String? ?? '',
      location: json['location'] as String? ?? '',
      ttsVoice: json['ttsVoice'] as String? ?? 'nova',
      speakerFirst: json['speakerFirst'] as String? ?? 'ai',
      sceneNote: json['sceneNote'] as String? ?? '',
      openingMessage: opening is Map<String, dynamic>
          ? Map<String, dynamic>.from(opening)
          : null,
    );
  }
}

class ScenarioService {
  ScenarioService._();

  static final ScenarioService instance = ScenarioService._();

  Future<String> _token() async {
    final token = await AuthService.instance.getIdToken();
    if (token == null) {
      throw ApiException('로그인이 필요합니다.');
    }
    return token;
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on http.ClientException {
      throw ApiException(
        '서버에 연결할 수 없습니다. (현재 주소: ${ApiConfig.baseUrl})',
      );
    }
  }

  Future<List<String>> getTopics() async {
    final token = await _token();
    final response = await _send(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/scenarios/topics'),
        headers: _headers(token),
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<String>.from(body['topics'] ?? []);
  }

  Future<List<String>> getGoals(String topic) async {
    final token = await _token();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/scenarios/goals').replace(
      queryParameters: {'topic': topic},
    );
    final response = await _send(
      () => http.get(uri, headers: _headers(token)),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<String>.from(body['goals'] ?? []);
  }

  Future<Map<String, dynamic>> getSessionPreview({
    required String topic,
    required List<String> goals,
  }) async {
    final token = await _token();
    final response = await _send(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/scenarios/preview'),
        headers: _headers(token),
        body: jsonEncode({'topic': topic, 'goals': goals}),
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<ScenarioSession> startSession({
    required String topic,
    required List<String> goals,
    String? aiGender,
  }) async {
    final token = await _token();
    final body = <String, dynamic>{
      'topic': topic,
      'goals': goals,
    };
    if (aiGender != null && aiGender.isNotEmpty) {
      body['aiGender'] = aiGender;
    }
    final response = await _send(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/scenarios/sessions'),
        headers: _headers(token),
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    return ScenarioSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required String text,
    bool isRecommended = false,
    bool usedHint = false,
    String? hintText,
    String? hintPronunciation,
    String? hintTranslation,
  }) async {
    final token = await _token();
    final body = <String, dynamic>{'text': text};
    if (usedHint) {
      body['usedHint'] = true;
      if (hintText != null && hintText.trim().isNotEmpty) {
        body['hintText'] = hintText.trim();
      }
      if (hintPronunciation != null && hintPronunciation.trim().isNotEmpty) {
        body['hintPronunciation'] = hintPronunciation.trim();
      }
      if (hintTranslation != null && hintTranslation.trim().isNotEmpty) {
        body['hintTranslation'] = hintTranslation.trim();
      }
    }
    final response = await _send(
      () => http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/scenarios/sessions/$sessionId/messages',
        ),
        headers: _headers(token),
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    payload['_isRecommended'] = isRecommended;
    return payload;
  }

  Future<SessionEndResult> endSession(String sessionId) async {
    final token = await _token();
    final response = await _send(
      () => http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/scenarios/sessions/$sessionId/end',
        ),
        headers: _headers(token),
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    return SessionEndResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is String) {
        return detail;
      }
    } catch (_) {}
    return '서버 요청에 실패했습니다. (${response.statusCode})';
  }
}
