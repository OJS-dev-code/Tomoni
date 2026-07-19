import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';
import '../../../widgets/direct_input_field.dart';
import '../../../widgets/selectable_chip.dart';
import '../../../widgets/custom_selectable_chip.dart';

class Step4Widget extends StatefulWidget {
  final PageController pageController;
  final Function(Set<String> purposes) onCompleted;

  const Step4Widget({
    super.key, 
    required this.pageController,
    required this.onCompleted,
  });

  @override
  State<Step4Widget> createState() => _Step4WidgetState();
}

class _Step4WidgetState extends State<Step4Widget> {
  final List<String> purposes = [
    "취미/자기계발",
    "여행",
    "현지생활",
    "취업/비즈니스",
    "시험/자격증(JLPT 등)",
    "덕질(애니/드라마)",
  ];
  
  final Set<String> selectedPurposes = {};
  final List<String> customPurposes = [];
  final TextEditingController _inputController = TextEditingController();

  void _addCustomPurpose() {
    String text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (purposes.contains(text) || customPurposes.contains(text)) {
        selectedPurposes.add(text);
      } else {
        customPurposes.add(text);
        selectedPurposes.add(text);
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
                    title: "일본어를 배우는\n목적이 무엇인가요?",
                    subtitle: "목적에 맞는 맞춤형 대화 상황을 준비해드려요 (다중 선택 가능)",
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      ...purposes.map((purpose) {
                        bool isSelected = selectedPurposes.contains(purpose);
                        return SelectableChip(
                          label: purpose,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedPurposes.remove(purpose);
                              } else {
                                selectedPurposes.add(purpose);
                              }
                            });
                          },
                        );
                      }),
                      ...customPurposes.map((purpose) {
                        bool isSelected = selectedPurposes.contains(purpose);
                        return CustomSelectableChip(
                          label: purpose,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedPurposes.remove(purpose);
                              } else {
                                selectedPurposes.add(purpose);
                              }
                            });
                          },
                          onDelete: () {
                            setState(() {
                              customPurposes.remove(purpose);
                              selectedPurposes.remove(purpose);
                            });
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DirectInputField(
                    controller: _inputController,
                    onAdd: _addCustomPurpose,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          StepNavigationButtons(
            pageController: widget.pageController,
            isNextEnabled: selectedPurposes.isNotEmpty,
            onNext: () {
              widget.onCompleted(selectedPurposes);
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
