import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/microphone_permission_service.dart';
import '../../widgets/home_action_button.dart';
import '../../widgets/home_calendar.dart';
// Phase 5 (보류): 홈 「자주 하는 실수」 — 배포 최소화
// import '../../widgets/home_mistake_patterns.dart';
import '../scenario/scenario_topic_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _handleStart(BuildContext context) async {
    final granted = await MicrophonePermissionService.request();

    if (granted) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScenarioTopicPage()),
        );
      }
    } else if (context.mounted) {
      MicrophonePermissionService.showDeniedMessage(context);
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
              const SizedBox(height: 24),
              const HomeCalendar(),
              const SizedBox(height: 24),
              HomeActionButton(
                text: "AI와 상황극 시작하기",
                onTap: () => _handleStart(context),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
