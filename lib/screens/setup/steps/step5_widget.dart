import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';
import '../../../widgets/direct_input_field.dart';
import '../../../widgets/selectable_chip.dart';
import '../../../widgets/custom_selectable_chip.dart';

class Step5Widget extends StatefulWidget {
  final PageController pageController;
  final Function(Set<String> hobbies) onCompleted;

  const Step5Widget({
    super.key, 
    required this.pageController,
    required this.onCompleted,
  });

  @override
  State<Step5Widget> createState() => _Step5WidgetState();
}

class _Step5WidgetState extends State<Step5Widget> {
  final List<String> hobbies = [
    "여행", "음악", "영화", "게임", "요리", 
    "운동", "독서", "만화/애니", "기술"
  ];
  
  final Set<String> selectedHobbies = {};
  final List<String> customHobbies = [];
  final TextEditingController _inputController = TextEditingController();

  void _addCustomHobby() {
    String text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (hobbies.contains(text) || customHobbies.contains(text)) {
        selectedHobbies.add(text);
      } else {
        customHobbies.add(text);
        selectedHobbies.add(text);
      }
      _inputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepHeader(
                    title: "평소 좋아하는 취미나\n관심사가 무엇인가요?",
                    subtitle: "관심사에 맞는 대화 주제를 추천해드려요 (다중 선택 가능)",
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      ...hobbies.map((hobby) {
                        bool isSelected = selectedHobbies.contains(hobby);
                        return SelectableChip(
                          label: hobby,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedHobbies.remove(hobby);
                              } else {
                                selectedHobbies.add(hobby);
                              }
                            });
                          },
                        );
                      }),
                      ...customHobbies.map((hobby) {
                        bool isSelected = selectedHobbies.contains(hobby);
                        return CustomSelectableChip(
                          label: hobby,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedHobbies.remove(hobby);
                              } else {
                                selectedHobbies.add(hobby);
                              }
                            });
                          },
                          onDelete: () {
                            setState(() {
                              customHobbies.remove(hobby);
                              selectedHobbies.remove(hobby);
                            });
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DirectInputField(
                    controller: _inputController,
                    onAdd: _addCustomHobby,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          StepNavigationButtons(
            pageController: widget.pageController,
            isNextEnabled: selectedHobbies.isNotEmpty,
            onNext: () {
              widget.onCompleted(selectedHobbies);
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
