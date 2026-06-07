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
      height: 95,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Row(
          children: [
            _buildNavItem(
              0,
              const Icon(
                Icons.home_outlined,
                size: 24,
              ),
              "홈",
            ),
            _buildNavItem(
              1,
              SvgPicture.asset(
                AppIcons.note,
                width: 24,
                height: 24,
              ),
              "피드백",
            ),
            _buildNavItem(
              2,
              SvgPicture.asset(
                AppIcons.setting,
                width: 24,
                height: 24,
              ),
              "설정",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index,
      Widget iconWidget,
      String label,
      ) {
    final bool isSelected = currentIndex == index;

    final Color color = isSelected
        ? const Color(0xFF807019)
        : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
              child: iconWidget,
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}