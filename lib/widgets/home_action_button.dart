import 'package:flutter/material.dart';
import 'package:tomoni/constants/app_constants.dart';

class HomeActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const HomeActionButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
        height: 280,
      decoration: BoxDecoration(
        color: AppColors.deepYellow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              "AI 상황극 시작하기",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "실제 일본인과 대화하듯\n자연스럽게 연습해 보세요.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                AppColors.deepYellow,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(30),
                ),
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "지금 시작하기",
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}