import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../../widgets/app_background.dart';
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
          const AppBackground(),

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
                  'AI와 함께 일본어 회화를 연습해 보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 60),

                // 시작하기 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepYellow,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
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
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFBF7),
                        foregroundColor: AppColors.deepYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        '이미 계정이 있음',
                        style: TextStyle(
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
                          text: '계속하시면면 ',
                        ),
                        TextSpan(
                          text: '이용약관',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepYellow,
                          ),
                        ),
                        TextSpan(text: ' 및\n'),
                        TextSpan(
                          text: '개인정보 처리방침',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepYellow,
                          ),
                        ),
                        TextSpan(text: '에 동의합니다.'),
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