import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';

class Step2Widget extends StatefulWidget {
  final PageController pageController;
  final Function(String level) onCompleted;

  const Step2Widget({
    super.key, 
    required this.pageController,
    required this.onCompleted,
  });

  @override
  State<Step2Widget> createState() => _Step2WidgetState();
}

class _Step2WidgetState extends State<Step2Widget> {
  String? selectedLevel;
  
  final List<Map<String, dynamic>> levels = [
    {
      "title": "입문",
      "desc": "매우 기초적이고 일상적인 표현",
      "color": AppColors.pastelGreen
    },
    {
      "title": "초급",
      "desc": "기초적이고 친숙한 주제 표현",
      "color": AppColors.pastelYellow
    },
    {
      "title": "중급",
      "desc": "공통 주제에 대한 회의, 연설 이해",
      "color": AppColors.heavyYellow
    },
    {
      "title": "중상급",
      "desc": "복잡한 문법으로 구성된 말 이해",
      "color": AppColors.pinkyRed
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(title: "일본어 실력이\n어느 정도인가요?"),
          Column(
            children: levels.map((level) {
              bool isSelected = selectedLevel == level["title"];
              Color levelColor = level["color"];
              
              return GestureDetector(
                onTap: () => setState(() => selectedLevel = level["title"]),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? levelColor : AppColors.lightGrey1,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level["title"],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: levelColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              level["desc"],
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: levelColor)
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          StepNavigationButtons(
            pageController: widget.pageController,
            isNextEnabled: selectedLevel != null,
            onNext: () {
              widget.onCompleted(selectedLevel!);
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
