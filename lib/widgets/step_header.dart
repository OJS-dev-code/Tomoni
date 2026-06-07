import 'package:flutter/material.dart';
//각 step_widget 페이지 상단에 들어가는 큰제목, 안내 문구
//40px 여백, 폰트 스타일 통일

class StepHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const StepHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}
