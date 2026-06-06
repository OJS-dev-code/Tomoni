import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_loading_service.dart';
import 'user_data_service.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  Map<String, String> _authHeaders(String idToken) {
    return {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getProfile(String idToken) async {
    final response = await _send(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/users/profile'),
        headers: _authHeaders(idToken),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiException(
      _extractErrorMessage(response),
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> updateProfile(
    String idToken,
    Map<String, dynamic> data,
  ) async {
    final response = await _send(
      () => http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/users/profile'),
        headers: _authHeaders(idToken),
        body: jsonEncode(_profilePayloadFromUserData(data)),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiException(
      _extractErrorMessage(response),
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _profilePayloadFromUserData(Map<String, dynamic> data) {
    return {
      'gender': data['gender'] ?? '',
      'birthDate': data['birthDate'] ?? '',
      'level': data['level'] ?? '입문',
      'duration': data['duration'] ?? '',
      'purposes': _toStringList(data['purposes']),
      'hobbies': _toStringList(data['hobbies']),
      'aiSpeed': data['aiSpeed'] ?? '현지인 속도로',
      'showContentFromStart': data['showContentFromStart'] ?? '예',
      'showKoreanTranslation': data['showKoreanTranslation'] ?? '예',
      'showKoreanPronunciation': data['showKoreanPronunciation'] ?? '아니오',
    };
  }

  List<String> _toStringList(dynamic value) {
    if (value is Set<String>) {
      return value.toList();
    }
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  void applyProfileToUserData(Map<String, dynamic> profile) {
    UserDataService().updateAll({
      'gender': profile['gender'] ?? '',
      'birthDate': profile['birthDate'] ?? '',
      'level': profile['level'] ?? '입문',
      'duration': profile['duration'] ?? '',
      'purposes': Set<String>.from(profile['purposes'] ?? []),
      'hobbies': Set<String>.from(profile['hobbies'] ?? []),
      'aiSpeed': profile['aiSpeed'] ?? '현지인 속도로',
      'showContentFromStart': profile['showContentFromStart'] ?? '예',
      'showKoreanTranslation': profile['showKoreanTranslation'] ?? '예',
      'showKoreanPronunciation': profile['showKoreanPronunciation'] ?? '아니오',
    });
  }

  bool isProfileComplete(Map<String, dynamic> profile) {
    final gender = profile['gender'] as String? ?? '';
    final duration = profile['duration'] as String? ?? '';
    final purposes = profile['purposes'];
    final hasPurposes = purposes is List && purposes.isNotEmpty ||
        purposes is Set && purposes.isNotEmpty;

    return gender.isNotEmpty && duration.isNotEmpty && hasPurposes;
  }

  String routeAfterAuth(Map<String, dynamic> profile) {
    return isProfileComplete(profile) ? '/main' : '/setup';
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    ApiLoadingService.begin();
    try {
      return await request();
    } on http.ClientException {
      throw ApiException(
        '서버에 연결할 수 없습니다. 백엔드가 실행 중인지 확인해주세요. '
        '(현재 주소: ${ApiConfig.baseUrl})',
      );
    } finally {
      ApiLoadingService.end();
    }
  }

  String _extractErrorMessage(http.Response response) {
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
