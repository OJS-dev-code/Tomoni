import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

// 앱 전체적인 디자인 스타일 지정
// main.dart 연결되어서 앱 전체에 사용
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.deepYellow,
      brightness: Brightness.light,
    ),

    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.deepYellow,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    ),
  );
}