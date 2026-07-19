import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';
import '../../../services/user_data_service.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class SummaryWidget extends StatefulWidget {
  final PageController pageController;
  final Map<String, dynamic> data;

  const SummaryWidget({
    super.key,
    required this.pageController,
    required this.data,
  });

  @override
  State<SummaryWidget> createState() => _SummaryWidgetState();
}

class _SummaryWidgetState extends State<SummaryWidget> {
  bool _isSaving = false;

  Future<void> _completeSetup() async {
    setState(() => _isSaving = true);

    UserDataService().updateAll(widget.data);

    try {
      final token = await AuthService.instance.getIdToken();
      if (token != null) {
        final profile = await ApiService.instance.updateProfile(
          token,
          UserDataService().data,
        );
        ApiService.instance.applyProfileToUserData(profile);
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      }
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('프로필 저장에 실패했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String purposesText = (widget.data['purposes'] as Set<String>).join(', ');
    String hobbiesText = (widget.data['hobbies'] as Set<String>).join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(title: "선택하신 내용을\n확인해주세요"),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryItem(
                    "성별/생년월일",
                    "${widget.data['gender']} / ${widget.data['birthDate']}",
                  ),
                  _buildSummaryItem("일본어 수준", widget.data['level']),
                  _buildSummaryItem("공부 기간", widget.data['duration']),
                  _buildSummaryItem(
                    "학습 목적",
                    purposesText.isEmpty ? "선택 안 함" : purposesText,
                  ),
                  _buildSummaryItem(
                    "관심사",
                    hobbiesText.isEmpty ? "선택 안 함" : hobbiesText,
                  ),
                  _buildSummaryItem("AI 말하기 속도", widget.data['aiSpeed']),
                  _buildSummaryItem("대화 처음부터 보기", widget.data['showContentFromStart']),
                  _buildSummaryItem("한국어 번역", widget.data['showKoreanTranslation']),
                  _buildSummaryItem("한국어 발음", widget.data['showKoreanPronunciation']),
                ],
              ),
            ),
          ),
          StepNavigationButtons(
            pageController: widget.pageController,
            nextText: _isSaving ? "저장 중..." : "시작하기",
            isNextEnabled: !_isSaving,
            onNext: _completeSetup,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
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
