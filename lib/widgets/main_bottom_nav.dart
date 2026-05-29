import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_constants.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: const BoxDecoration(
        color: AppColors.pastelLightgreen,
        border: Border(
          top: BorderSide(color: Colors.black12, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(0, SvgPicture.asset(AppIcons.note, width: 33, height: 33, colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn))),
            _buildNavItem(1, const Icon(Icons.home_filled, size: 38, color: AppColors.black)),
            _buildNavItem(2, SvgPicture.asset(AppIcons.setting, width: 33, height: 33, colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn))),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, Widget iconWidget) {
    bool isSelected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: iconWidget,
          ),
        ),
      ),
    );
  }
}
