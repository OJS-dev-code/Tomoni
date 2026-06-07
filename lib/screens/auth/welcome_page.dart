import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 기본 배경
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
              decoration: BoxDecoration(
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
              decoration: BoxDecoration(
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

          // 화면 내용
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                const Text(
                  'Tomoni',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF8A7530),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Master Japanese with a friendly\ncompanion by your side.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 60),

                // Get Started 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepYellow,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 로그인 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFBF7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'I already have an account',
                        style: TextStyle(
                          color: AppColors.deepYellow,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepYellow,
                          ),
                        ),
                        TextSpan(text: ' and\n'),
                        TextSpan(
                          text: 'Privacy Policy.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}