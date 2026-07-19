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
      "icon": Icons.child_care,
      "iconBgColor": const Color(0xFFDDF4E4),
      "iconColor": const Color(0xFF4E7D57),
    },
    {
      "title": "초급",
      "desc": "기초적이고 친숙한 주제 표현",
      "icon": Icons.menu_book,
      "iconBgColor": const Color(0xFFDDEEFF),
      "iconColor": const Color(0xFF4B74A6),
    },
    {
      "title": "중급",
      "desc": "공통 주제에 대한 회의, 연설 이해",
      "icon": Icons.chat_bubble_outline,
      "iconBgColor": const Color(0xFFFFF1C9),
      "iconColor": const Color(0xFFB8860B),
    },
    {
      "title": "중상급",
      "desc": "복잡한 문법으로 구성된 말 이해",
      "icon": Icons.auto_awesome,
      "iconBgColor": const Color(0xFF4F6B50),
      "iconColor": Colors.white,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: "일본어 실력이\n어느 정도인가요?",
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: levels.map((level) {
                  bool isSelected =
                      selectedLevel == level["title"];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedLevel = level["title"];
                      });
                    },
                    child: Container(
                      margin:
                      const EdgeInsets.only(bottom: 12),
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.deepYellow
                              : Colors.transparent,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                            level["iconBgColor"],
                            child: Icon(
                              level["icon"],
                              color: level["iconColor"],
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level["title"],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  level["desc"],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color:
                                    AppColors.darkGrey,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color:
                              AppColors.deepYellow,
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          StepNavigationButtons(
            pageController: widget.pageController,
            isNextEnabled: selectedLevel != null,
            onNext: () {
              widget.onCompleted(selectedLevel!);

              widget.pageController.nextPage(
                duration:
                const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
        ],
      ),
    );
  }
}
