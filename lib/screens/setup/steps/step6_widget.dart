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
                  CustomToggle(
                    title: "AI가 말하는 속도",
                    options: const ["천천히", "현지인속도"],
                    currentValue: aiSpeed,
                    onChanged: (val) => setState(() => aiSpeed = val),
                  ),
                  const SizedBox(height: 24),
                  CustomToggle(
                    title: "상황극 내용을 처음부터 텍스트로 확인하기",
                    subtitle: "대화 기록을 항상 텍스트로 표시합니다.",
                    options: const ["예", "아니오"],
                    currentValue: showContentFromStart,
                    onChanged: (val) => setState(() => showContentFromStart = val),
                  ),
                  const SizedBox(height: 24),
                  CustomToggle(
                    title: "AI의 음성 한국어 번역 표기",
                    subtitle: "일본어 대화 아래에 한국어 번역을 표시합니다.",
                    options: const ["예", "아니오"],
                    currentValue: showKoreanTranslation,
                    onChanged: (val) => setState(() => showKoreanTranslation = val),
                  ),
                  const SizedBox(height: 24),
                  CustomToggle(
                    title: "AI의 추천 답변 한국어 발음 표기",
                    subtitle: "추천 답변 위에 한국어 발음을 표시합니다.",
                    options: const ["예", "아니오"],
                    currentValue: showKoreanPronunciation,
                    onChanged: (val) => setState(() => showKoreanPronunciation = val),
                  ),
                  const SizedBox(height: 20),
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
