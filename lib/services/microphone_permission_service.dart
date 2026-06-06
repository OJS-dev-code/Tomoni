import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MicrophonePermissionService {
  MicrophonePermissionService._();

  static const String deniedMessage =
      '마이크 접근을 허용해야 AI와 상황극이 가능합니다.';

  /// 마이크 권한을 요청하고 허용 여부를 반환합니다.
  static Future<bool> request() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }

    status = await Permission.microphone.request();
    return status.isGranted;
  }

  static void showDeniedMessage(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(deniedMessage)),
    );
  }
}
