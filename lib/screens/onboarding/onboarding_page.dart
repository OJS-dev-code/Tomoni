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
    "효과적인 학습을 위해\n다음 질문에 답변해주세요",
    "성별과 나이대를\n제외하고 사용자 설정에서\n모두 변경 가능하니\n부담없이 선택해주세요",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF4CC),
                  Color(0xFFFFFBF5),
                  Color(0xFFE5F8FF),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // 왼쪽 위 노란빛
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFFF0A8),
                    Color(0xFFFFF8E1),
                    Color(0x00FFF8E1),
                  ],
                ),
              ),
            ),
          ),

          // 오른쪽 아래 하늘빛
          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFDDF7FF),
                    Color(0xFFF5FCFF),
                    Color(0x00F5FCFF),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: GestureDetector(
              onTapUp: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                final tapX = details.localPosition.dx;

                // 오른쪽 탭 → 다음 페이지
                if (tapX > screenWidth / 2) {
                  if (_currentPage < items.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }

                // 왼쪽 탭 → 이전 페이지
                else {
                  if (_currentPage > 0) {
                    _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              },
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: items.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                items[index],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.darkGrey,
                                  fontSize: 22,
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              const SizedBox(height: 40),

                              if (index == items.length - 1)
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.deepYellow,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 60,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/setup',
                                    );
                                  },
                                  child: const Text(
                                    '시작하기',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      items.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: _currentPage == i ? 12 : 8,
                        height: _currentPage == i ? 12 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == i
                              ? const Color(0xFF807019)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}