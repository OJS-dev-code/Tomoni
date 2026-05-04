import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/custom_button.dart';

class Step4Widget extends StatefulWidget {
  final PageController pageController;

  const Step4Widget({super.key, required this.pageController});

  @override
  _Step4WidgetState createState() => _Step4WidgetState();
}

class _Step4WidgetState extends State<Step4Widget> {
  final List<Map<String, String>> hobbies = [
    {"label": "여행", "emoji": "✈️"},
    {"label": "음악", "emoji": "🎵"},
    {"label": "영화", "emoji": "🎬"},
    {"label": "게임", "emoji": "🎮"},
    {"label": "요리", "emoji": "🍳"},
    {"label": "운동", "emoji": "🏋️"},
    {"label": "독서", "emoji": "📚"},
    {"label": "만화/애니", "emoji": "📺"},
    {"label": "기술", "emoji": "💻"},
    {"label": "비즈니스", "emoji": "👔"},
  ];
  
  final Set<String> selectedHobbies = {};
  final List<String> customHobbies = [];
  final TextEditingController _inputController = TextEditingController();

  void _addCustomHobby() {
    String text = _inputController.text.trim();
    if (text.isNotEmpty && !customHobbies.contains(text) && !hobbies.any((h) => h["label"] == text)) {
      setState(() {
        customHobbies.add(text);
        selectedHobbies.add(text);
        _inputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "평소 좋아하는 취미나\n관심사가 무엇인가요?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      ...hobbies.map((hobby) {
                        bool isSelected = selectedHobbies.contains(hobby["label"]);
                        return _buildHobbyChip(hobby["label"]!, hobby["emoji"]!, isSelected);
                      }),
                      ...customHobbies.map((hobby) {
                        bool isSelected = selectedHobbies.contains(hobby);
                        return _buildCustomHobbyChip(hobby, isSelected);
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            hintText: "직접 입력",
                            hintStyle: const TextStyle(color: AppColors.lightGrey1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightGrey1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightGrey1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addCustomHobby,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        ),
                        child: const Text("추가"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
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
                    onPressed: selectedHobbies.isNotEmpty
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

  Widget _buildHobbyChip(String label, String emoji, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) selectedHobbies.remove(label);
          else selectedHobbies.add(label);
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
          "$emoji $label",
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
          if (isSelected) selectedHobbies.remove(label);
          else selectedHobbies.add(label);
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
