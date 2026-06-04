import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';
import '../../../services/user_data_service.dart';

class SummaryWidget extends StatelessWidget {
  final PageController pageController;
  final Map<String, dynamic> data;

  const SummaryWidget({
    super.key, 
    required this.pageController,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    String purposesText = (data['purposes'] as Set<String>).join(', ');
    String hobbiesText = (data['hobbies'] as Set<String>).join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(title: "선택하신 내용을\n확인해주세요"),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryItem("성별/생년월일", "${data['gender']} / ${data['birthDate']}"),
                  _buildSummaryItem("일본어 수준", data['level']),
                  _buildSummaryItem("공부 기간", data['duration']),
                  _buildSummaryItem("학습 목적", purposesText.isEmpty ? "선택 안 함" : purposesText),
                  _buildSummaryItem("관심사", hobbiesText.isEmpty ? "선택 안 함" : hobbiesText),
                  _buildSummaryItem("AI 말하기 속도", data['aiSpeed']),
                  _buildSummaryItem("대화 처음부터 보기", data['showContentFromStart']),
                  _buildSummaryItem("한국어 번역", data['showKoreanTranslation']),
                  _buildSummaryItem("한국어 발음", data['showKoreanPronunciation']),
                ],
              ),
            ),
          ),
          StepNavigationButtons(
            pageController: pageController,
            nextText: "시작하기",
            onNext: () async {
              // 데이터를 서비스에 저장
              UserDataService().updateAll(data);
              
              // 설정 완료 상태 저장
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasCompletedSetup', true);
              
              // 메인 화면으로 이동
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
              }
            },
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
