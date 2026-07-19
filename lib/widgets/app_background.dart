import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 기본 배경
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF4CC),
                Color(0xFFFFFBF5),
                Color(0xFFE5F8FF),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),

        // 왼쪽 위 노란빛
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 350,
            height: 350,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFFF0A8),
                  Color(0xFFFFF8E1),
                  Color(0x00FFF8E1),
                ],
              ),
            ),
          ),
        ),

        // 오른쪽 아래 하늘빛
        Positioned(
          bottom: -120,
          right: -120,
          child: Container(
            width: 350,
            height: 350,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFDDF7FF),
                  Color(0xFFF5FCFF),
                  Color(0x00F5FCFF),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}