import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/home_action_button.dart';
import '../../widgets/home_calendar.dart';
import '../../widgets/home_mistake_patterns.dart';
import '../scenario/scenario_topic_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _handleStart(BuildContext context) async {
    // 1. 마이크 권한 요청
    var status = await Permission.microphone.request();
    
    if (status.isGranted) {
      // 2. 권한 허용 시 페이지 이동
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScenarioTopicPage()),
        );
      }
    } else {
      // 3. 거부 시 안내 (선택사항)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("상황극을 위해 마이크 권한이 필요합니다.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pastelLightgreen,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // 양옆 공백 축소
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50), // 버튼 위 공간 추가
              // 상단 상황극 시작 버튼
              HomeActionButton(
                text: "AI와 상황극 시작하기",
                onTap: () => _handleStart(context),
              ),
              const SizedBox(height: 30),
              const HomeCalendar(),
              const SizedBox(height: 20),
              const HomeMistakePatterns(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
