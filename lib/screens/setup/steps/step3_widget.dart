import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/custom_button.dart';

class Step3Widget extends StatefulWidget {
  final PageController pageController;

  const Step3Widget({super.key, required this.pageController});

  @override
  _Step3WidgetState createState() => _Step3WidgetState();
}

class _Step3WidgetState extends State<Step3Widget> {
  int? selectedDurationIndex;
  final List<String> durations = ["일주일", "한달", "3개월", "6개월", "1년 이상"];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "일본어를 공부한 지\n얼마나 되셨나요?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 80),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: AppColors.lightGrey1,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(durations.length, (index) {
                  bool isSelected = selectedDurationIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => selectedDurationIndex = index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.lightGrey1,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 60,
                          child: Text(
                            durations[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
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
                    onPressed: selectedDurationIndex != null
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
