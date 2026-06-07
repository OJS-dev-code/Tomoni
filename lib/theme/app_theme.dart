import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
// 앱 전체적인 디자인 스타일 지정
// main.dart 연결되어서 앱 전체에 사용
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary, //메인컬러
    scaffoldBackgroundColor: AppColors.background, //모든화면 기본 배경색
    //상단 앱 바의 스타일 (그림자 없음, 흰색)
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
    ),
    //일반 버튼 기본 스타일
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    ),
  );
}
