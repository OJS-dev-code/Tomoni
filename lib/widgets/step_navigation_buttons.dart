import 'package:flutter/material.dart';
import 'custom_button.dart';
//모든 step_widget의 하단에 들어가는 이전,다음 버튼 조합
//자동 키보드 닫기, 페이지 이동 통합 기능

class StepNavigationButtons extends StatelessWidget {
  final PageController pageController;
  final VoidCallback? onNext; // 다음 버튼 클릭 시 커스텀 동작 (없으면 기본 nextPage)
  final bool isNextEnabled;   // 다음 버튼 활성화 여부
  final String nextText;      // 다음 버튼 텍스트 (기본값: "다음")
  final bool showPrevious;    // 이전 버튼 표시 여부 (Step 1은 false)

  const StepNavigationButtons({
    super.key,
    required this.pageController,
    this.onNext,
    this.isNextEnabled = true,
    this.nextText = "다음",
    this.showPrevious = true,
  });

  void _dismissKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 40,
      ),      child: Row(
        children: [
          if (showPrevious)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: CustomButton(
                  text: "이전",
                  isPrimary: false,
                  onPressed: () {
                    _dismissKeyboard(context);
                    pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    );
                  },
                ),
              ),
            ),
          Expanded(
            flex: showPrevious ? 2 : 1,
            child: CustomButton(
              text: nextText,
              onPressed: isNextEnabled
                  ? () {
                      _dismissKeyboard(context);
                      if (onNext != null) {
                        onNext!();
                      } else {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
