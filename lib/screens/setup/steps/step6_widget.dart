import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/custom_toggle.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';

class Step6Widget extends StatefulWidget {
  final PageController pageController;
  final Function(String speed, String start, String trans, String pron) onCompleted;

  const Step6Widget({
    super.key, 
    required this.pageController,
    required this.onCompleted,
  });

  @override
  State<Step6Widget> createState() => _Step6WidgetState();
}

class _Step6WidgetState extends State<Step6Widget> {
  String aiSpeed = "현지인속도";
  String showContentFromStart = "예";
  String showKoreanTranslation = "예";
  String showKoreanPronunciation = "아니오";

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: iconBgColor,
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            onChanged: onChanged,

            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF2F6699),

            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5E5E5),
          ),
        ],
      ),
    );
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
                  const StepHeader(title: "나에게 딱 맞는\n학습 환경을 설정해주세요"),

                  _buildSettingCard(
                    icon: Icons.speed,
                    iconBgColor: const Color(0xFFDDEEFF),
                    iconColor: const Color(0xFF4B74A6),
                    title: "천천히 말하기",
                    subtitle: "음성을 0.8배속으로 재생합니다.",
                    value: aiSpeed == "천천히",
                    onChanged: (value) {
                      setState(() {
                        aiSpeed = value ? "천천히" : "현지인속도";
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildSettingCard(
                    icon: Icons.subtitles_outlined,
                    iconBgColor: const Color(0xFFDDF4E4),
                    iconColor: const Color(0xFF4E7D57),
                    title: "일본어 자막",
                    subtitle: "히라가나와 한자를 표시합니다.",
                    value: showContentFromStart == "예",
                    onChanged: (value) {
                      setState(() {
                        showContentFromStart = value ? "예" : "아니오";
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildSettingCard(
                    icon: Icons.translate,
                    iconBgColor: const Color(0xFFFFF1C9),
                    iconColor: const Color(0xFFB8860B),
                    title: "한국어 번역",
                    subtitle: "한국어 번역을 함께 표시합니다.",
                    value: showKoreanTranslation == "예",
                    onChanged: (value) {
                      setState(() {
                        showKoreanTranslation = value ? "예" : "아니오";
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildSettingCard(
                    icon: Icons.record_voice_over_outlined,
                    iconBgColor: const Color(0xFFDDEEFF),
                    iconColor: const Color(0xFF4B74A6),
                    title: "발음 가이드",
                    subtitle: "추천 답변에 발음 정보를 표시합니다.",
                    value: showKoreanPronunciation == "예",
                    onChanged: (value) {
                      setState(() {
                        showKoreanPronunciation = value ? "예" : "아니오";
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          StepNavigationButtons(
            pageController: widget.pageController,
            onNext: () {
              widget.onCompleted(
                aiSpeed, 
                showContentFromStart, 
                showKoreanTranslation, 
                showKoreanPronunciation
              );
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
