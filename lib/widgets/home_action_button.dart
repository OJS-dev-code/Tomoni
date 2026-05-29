import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.pastelGreen, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 7,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.pastelGreen,
              fontSize: 26
              ,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
