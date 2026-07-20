import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../services/microphone_permission_service.dart';
import '../../widgets/home_action_button.dart';
import '../../widgets/home_calendar.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                    width: 0.5,
                  ),                ),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tomoni',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepYellow,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const HomeCalendar(),
                    const SizedBox(height: 28),
                    HomeActionButton(
                      text: 'AI 상황극 시작하기',
                      onTap: () => _handleStart(context),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
