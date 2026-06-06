import 'package:flutter/foundation.dart';

/// FastAPI base URL.
///
/// - Web / Windows: `http://127.0.0.1:8000`
/// - Android emulator: `http://10.0.2.2:8000`
/// - Physical device: `--dart-define=API_BASE_URL=http://<PC_IP>:8000`
class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }
}
