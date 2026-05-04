import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/custom_button.dart';

class Step5Widget extends StatefulWidget {
  final PageController pageController;

  const Step5Widget({super.key, required this.pageController});

  @override
  _Step5WidgetState createState() => _Step5WidgetState();
}

class _Step5WidgetState extends State<Step5Widget> {
  String aiSpeed = "현지인속도";
  bool showContentFromStart = true;
  bool showKoreanTranslation = true;
  bool showKoreanPronunciation = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "나에게 딱 맞는\n학습 환경을 설정해주세요",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          _buildToggleRow("AI 말하기 속도", ["천천히", "현지인속도"], aiSpeed, (val) => setState(() => aiSpeed = val)),
          const SizedBox(height: 24),
          _buildYesNoToggle("AI 대화 내용 처음부터 보기", showContentFromStart, (val) => setState(() => showContentFromStart = val)),
          const SizedBox(height: 24),
          _buildYesNoToggle("AI 대화 한국어 번역 보기", showKoreanTranslation, (val) => setState(() => showKoreanTranslation = val)),
          const SizedBox(height: 24),
          _buildYesNoToggle("추천 답변 한국어 발음 보기", showKoreanPronunciation, (val) => setState(() => showKoreanPronunciation = val)),
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
                    onPressed: () => widget.pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, List<String> options, String currentValue, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.lightGrey1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: options.map((opt) {
              bool isSelected = currentValue == opt;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.darkGrey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildYesNoToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.lightGrey1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildToggleItem("예", value == true, () => onChanged(true)),
              _buildToggleItem("아니오", value == false, () => onChanged(false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.darkGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
