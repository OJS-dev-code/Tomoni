import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import 'steps/step1_widget.dart';
import 'steps/step2_widget.dart';
import 'steps/step3_widget.dart';
import 'steps/step4_widget.dart';
import 'steps/step5_widget.dart';
import 'steps/summary_widget.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final PageController _controller = PageController();
  double _progress = 0.2; // 초기 1단계 (1/5)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () {
            if (_controller.hasClients && _controller.page! > 0) {
              _controller.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            } else {
              // 1단계에서 뒤로가기 시 온보딩 페이지로 이동
              Navigator.of(context).pushReplacementNamed('/onboarding');
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.lightGrey1,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            // 요약 페이지(index 5)는 게이지를 100%로 채움
            setState(() => _progress = index >= 5 ? 1.0 : (index + 1) / 5);
          },
          children: [
            Step1Widget(pageController: _controller),
            Step2Widget(pageController: _controller),
            Step3Widget(pageController: _controller),
            Step4Widget(pageController: _controller),
            Step5Widget(pageController: _controller),
            SummaryWidget(pageController: _controller),
          ],
        ),
      ),
    );
  }
}
