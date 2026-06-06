import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'constants/app_constants.dart';
import 'services/api_loading_service.dart';
import 'widgets/top_loading_bar.dart';
import 'screens/onboarding/onboarding_page.dart';
import 'screens/setup/setup_page.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomoni',
      color: AppColors.primary,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return Stack(
          children: [
            ?child,
            ValueListenableBuilder<int>(
              valueListenable: ApiLoadingService.pendingCount,
              builder: (context, count, _) {
                if (count <= 0) return const SizedBox.shrink();
                return const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: TopLoadingBar(),
                );
              },
            ),
          ],
        );
      },
      home: const SplashScreen(),
      routes: {
        '/setup': (context) => const SetupPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/main': (context) => const MainScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}
