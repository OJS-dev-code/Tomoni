import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';
import '../../../widgets/direct_input_field.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
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
                        return _buildHobbyChip(hobby, isSelected);
                      }),
                      ...customHobbies.map((hobby) {
                        bool isSelected = selectedHobbies.contains(hobby);
                        return _buildCustomHobbyChip(hobby, isSelected);
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),
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

  Widget _buildHobbyChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedHobbies.remove(label);
          } else {
            selectedHobbies.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.lightGrey1),
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

  Widget _buildCustomHobbyChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedHobbies.remove(label);
          } else {
            selectedHobbies.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10, right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.lightGrey1),
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
                  customHobbies.remove(label);
                  selectedHobbies.remove(label);
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
