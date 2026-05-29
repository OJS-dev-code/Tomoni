import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<String> items = [
    "환영합니다\n토모니는 일본어 초보부터\n중급자를 위한\n일본어 학습 앱입니다",
    "이전에 토모니를\n이용해보신적 있으신가요?",
    "효과적인 학습을 위해\n다음 질문에 답변해주세요",
    "성별과 나이대를\n제외하고 사용자 설정에서\n모두 변경 가능하니\n부담없이 선택해주세요"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          items[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // 인디케이터
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            items.length,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8.0),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == i
                                    ? Colors.white
                                    : AppColors.lightGrey1.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 2번째 페이지 (인덱스 1) - 경험 체크 버튼
                        if (index == 1)
                          Row(
                            children: [
                              Expanded(
                                child: _buildChoiceButton("처음", () {
                                  _controller.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  );
                                }),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildChoiceButton("경험 있음", () {
                                  Navigator.pushNamed(context, '/login');
                                }),
                              ),
                            ],
                          ),

                        // 마지막 페이지 - 시작하기 버튼
                        if (index == items.length - 1)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/setup'),
                            child: const Text(
                              "시작하기",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
