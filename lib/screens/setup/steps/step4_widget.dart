import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';
import '../../../widgets/direct_input_field.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
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
                        return _buildPurposeChip(purpose, isSelected);
                      }),
                      ...customPurposes.map((purpose) {
                        bool isSelected = selectedPurposes.contains(purpose);
                        return _buildCustomPurposeChip(purpose, isSelected);
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),
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

  Widget _buildPurposeChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) selectedPurposes.remove(label);
          else selectedPurposes.add(label);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepYellow : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? AppColors.deepYellow : AppColors.lightGrey1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPurposeChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) selectedPurposes.remove(label);
          else selectedPurposes.add(label);
        });
      },
      child: Container(
        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10, right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepYellow : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? AppColors.deepYellow : AppColors.lightGrey1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  customPurposes.remove(label);
                  selectedPurposes.remove(label);
                });
              },
              child: Icon(
                Icons.close,
                size: 18,
                color: isSelected ? Colors.white : AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
