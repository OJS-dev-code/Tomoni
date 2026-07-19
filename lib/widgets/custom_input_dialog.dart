import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class CustomInputDialog {
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? initialValue,
    String hintText = '',
    Color accentColor = const Color(0xFF807019),
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            cursorColor: AppColors.deepYellow,
            decoration: InputDecoration(
              hintText: hintText,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: accentColor,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(
                  color: AppColors.deepYellow,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: Text(
                '확인',
                style: TextStyle(
                  color: accentColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}