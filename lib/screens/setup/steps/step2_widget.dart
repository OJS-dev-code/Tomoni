import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/custom_button.dart';

class Step2Widget extends StatefulWidget {
  final PageController pageController;

  const Step2Widget({super.key, required this.pageController});

  @override
  _Step2WidgetState createState() => _Step2WidgetState();
}

class _Step2WidgetState extends State<Step2Widget> {
  String? selectedLevel;
  final List<String> levels = ["입문", "초급", "중급", "중상급"];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "일본어 실력이\n어느 정도인가요?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          Column(
            children: levels.map((level) {
              bool isSelected = selectedLevel == level;
              return GestureDetector(
                onTap: () => setState(() => selectedLevel = level),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.lightGrey1,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        level,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.primary)
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: CustomButton(
                      text: "이전",
                      isPrimary: false,
                      onPressed: () => widget.pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: "다음",
                    onPressed: selectedLevel != null
                        ? () => widget.pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
