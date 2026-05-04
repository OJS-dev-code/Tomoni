import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/custom_button.dart';

class SummaryWidget extends StatelessWidget {
  final PageController pageController;

  const SummaryWidget({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "선택하신 내용을\n확인해주세요",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryItem("성별/생년월일", "여성 / 2000.01.01"),
                  _buildSummaryItem("일본어 수준", "초급"),
                  _buildSummaryItem("공부 기간", "3개월"),
                  _buildSummaryItem("관심사", "여행, 음악, 요리, 일본 드라마"),
                  _buildSummaryItem("AI 말하기 속도", "현지인속도"),
                  _buildSummaryItem("대화 처음부터 보기", "예"),
                  _buildSummaryItem("한국어 번역", "예"),
                  _buildSummaryItem("한국어 발음", "아니오"),
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
                      onPressed: () => pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: "시작하기",
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: AppColors.darkGrey)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
