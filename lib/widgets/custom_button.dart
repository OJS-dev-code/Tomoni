import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
// 앱 전체에 사용하는 확인, 다음, 이전 버튼들의 기본 UI

// 글자, 실행동작, 색상옵션, 너비높이
class CustomButton extends StatelessWidget {
  final String text; 
  final VoidCallback? onPressed;
  final bool isPrimary; //True면 파란배경, False면 흰배경
  final double? width;
  final double height;

  //호출 시 text 필수. widght height 55로 고정, isPrimary도 true로 고정
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.width,
    this.height = 55,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.deepYellow : Colors.white,
          foregroundColor: isPrimary ? Colors.white : AppColors.beigeGray,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: isPrimary 
                ? BorderSide.none 
                : const BorderSide(color: AppColors.lightGrey1),
          ),
          disabledBackgroundColor: AppColors.lightGrey1,
          disabledForegroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
