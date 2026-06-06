import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Render 콜드 스타트 등 — 헬스체크 성공까지 대기.
class ServerWarmupService {
  ServerWarmupService._();

  static const _maxAttempts = 24;
  static const _retryDelay = Duration(seconds: 5);
  static const _requestTimeout = Duration(seconds: 20);

  static Future<bool> waitUntilReady() async {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final response = await http
            .get(Uri.parse('${ApiConfig.baseUrl}/api/v1/health'))
            .timeout(_requestTimeout);
        if (response.statusCode == 200) {
          return true;
        }
      } on TimeoutException {
        // Render waking up — retry
      } catch (_) {
        // Connection refused / sleep — retry
      }

      if (attempt < _maxAttempts - 1) {
        await Future.delayed(_retryDelay);
      }
    }
    return false;
  }
}
