import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/mistake_pattern.dart';
import 'api_loading_service.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MistakeService {
  MistakeService._();

  static final MistakeService instance = MistakeService._();

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
    ApiLoadingService.begin();
    try {
      return await request();
    } on http.ClientException {
      throw ApiException(
        '서버에 연결할 수 없습니다. (현재 주소: ${ApiConfig.baseUrl})',
      );
    } finally {
      ApiLoadingService.end();
    }
  }

  Future<List<MistakePattern>> getPatterns({int limit = 5}) async {
    final token = await _token();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/mistakes/patterns').replace(
      queryParameters: {'limit': limit.toString()},
    );
    final response = await _send(
      () => http.get(uri, headers: _headers(token)),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final patterns = body['patterns'] as List<dynamic>? ?? [];
    return patterns
        .map((item) => MistakePattern.fromJson(item as Map<String, dynamic>))
        .toList();
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
