import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_data_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (!mounted) {
      return;
    }

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

    Navigator.of(context).pushReplacementNamed('/login');
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
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: const Text(
            "Tomoni",
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
