import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/server_warmup_service.dart';
import '../services/user_data_service.dart';
import '../widgets/top_loading_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPreparingServer = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() => _isPreparingServer = true);

    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 800)),
      ServerWarmupService.waitUntilReady(),
    ]);

    if (!mounted) return;
    setState(() => _isPreparingServer = false);

    final user = AuthService.instance.currentUser;
    if (user != null) {
      Map<String, dynamic> profile = UserDataService().data;
      try {
        final token = await AuthService.instance.getIdToken();
        if (token != null) {
          profile = await ApiService.instance.getProfile(token);
          ApiService.instance.applyProfileToUserData(profile);
        }
      } catch (_) {
        // 프로필 로드 실패 시에도 로그인 상태는 유지
      }

      if (mounted) {
        final route = ApiService.instance.routeAfterAuth(profile);
        Navigator.of(context).pushReplacementNamed(route);
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          Center(
            child: FadeTransition(
              opacity: _animation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tomoni',
                    style: TextStyle(
                      color: AppColors.deepYellow,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  if (_isPreparingServer) ...[
                    const SizedBox(height: 20),
                    Text(
                      '서버 준비중',
                      style: TextStyle(
                        color: AppColors.deepYellow.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isPreparingServer)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopLoadingBar(
                valueColor: AppColors.deepYellow,
                backgroundColor: Color(0x33FFFFFF),
              ),
            ),
        ],
      ),
    );
  }
}
