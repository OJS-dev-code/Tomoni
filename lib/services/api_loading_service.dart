import 'package:flutter/foundation.dart';

/// API 요청 중 상단 LinearProgressIndicator 표시용.
class ApiLoadingService {
  ApiLoadingService._();

  static final ValueNotifier<int> pendingCount = ValueNotifier(0);

  static bool get isActive => pendingCount.value > 0;

  static void begin() {
    pendingCount.value++;
  }

  static void end() {
    if (pendingCount.value > 0) {
      pendingCount.value--;
    }
  }
}
