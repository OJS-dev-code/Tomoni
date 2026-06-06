import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// 화면 최상단 indeterminate 로딩 바.
class TopLoadingBar extends StatelessWidget {
  final Color? valueColor;
  final Color? backgroundColor;

  const TopLoadingBar({
    super.key,
    this.valueColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        backgroundColor: backgroundColor ?? AppColors.lightGrey1,
        valueColor: AlwaysStoppedAnimation<Color>(
          valueColor ?? AppColors.primary,
        ),
        minHeight: 3,
      ),
    );
  }
}
