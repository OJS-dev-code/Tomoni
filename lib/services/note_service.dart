import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/feedback_note.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NoteService {
  NoteService._();

  static final NoteService instance = NoteService._();

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

  Future<List<FeedbackNote>> getNotes({
    required int year,
    required int month,
  }) async {
    final token = await _token();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/notes').replace(
      queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
      },
    );
    final response = await _send(
      () => http.get(uri, headers: _headers(token)),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final notes = body['notes'] as List<dynamic>? ?? [];
    return notes
        .map((item) => FeedbackNote.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FeedbackNote> getNote(String noteId) async {
    final token = await _token();
    final response = await _send(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notes/$noteId'),
        headers: _headers(token),
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    return FeedbackNote.fromJson(
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
