import 'dart:async';

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
      Navigator.of(context).pushReplacementNamed('/login');
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
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _animation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tomoni',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  if (_isPreparingServer) ...[
                    const SizedBox(height: 20),
                    Text(
                      '서버 준비중',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
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
                valueColor: Colors.white,
                backgroundColor: Color(0x33FFFFFF),
              ),
            ),
        ],
      ),
    );
  }
}
