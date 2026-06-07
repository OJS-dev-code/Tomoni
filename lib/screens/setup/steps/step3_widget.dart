import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';

class Step3Widget extends StatefulWidget {
  final PageController pageController;
  final Function(String duration) onCompleted;

  const Step3Widget({
    super.key, 
    required this.pageController,
    required this.onCompleted,
  });

  @override
  State<Step3Widget> createState() => _Step3WidgetState();
}

class _Step3WidgetState extends State<Step3Widget> {
  int? selectedDurationIndex;
  final List<String> durations = [
    "3개월 미만",
    "3개월 ~ 6개월 미만",
    "6개월 ~ 1년 미만",
    "1년 ~ 2년 미만",
    "2년 이상"
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(title: "일본어를 공부한 지\n얼마나 되셨나요?"),
          Expanded(
            child: ListView.builder(
              itemCount: durations.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedDurationIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedDurationIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.deepYellow.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.deepYellow : AppColors.lightGrey1,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.deepYellow : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.deepYellow : AppColors.lightGrey1,
                              width: 2,
                            ),
                          ),
                          child: isSelected 
                            ? const Center(child: Icon(Icons.circle, size: 10, color: Colors.white))
                            : null,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          durations[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.deepYellow : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.deepYellow, size: 20)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          StepNavigationButtons(
            pageController: widget.pageController,
            isNextEnabled: selectedDurationIndex != null,
            onNext: () {
              widget.onCompleted(durations[selectedDurationIndex!]);
              widget.pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
        ],
      ),
    );
  }
}
