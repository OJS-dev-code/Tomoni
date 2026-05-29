import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
//step_widget 페이지에서 목록에 없는 항목 사용자가 직접 타이핑해서 추가
// 일본어 배우는 목적, 취미와 관심사 등

class DirectInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final String hintText;

  const DirectInputField({
    super.key,
    required this.controller,
    required this.onAdd,
    this.hintText = "직접 입력",
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: AppColors.lightGrey1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightGrey1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightGrey1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          child: const Text("추가"),
        ),
      ],
    );
  }
}
