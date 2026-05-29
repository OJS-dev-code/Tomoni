import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
//예,아니오 선택 슬라이딩 토글
//선택된 항목은 흰색 배경에 primary 글씨, 선택 안된 것은 회색으로 흐리게 처리
//부제목 추가 가능

class CustomToggle extends StatelessWidget {
  final String title;
  final List<String> options;
  final String currentValue;
  final ValueChanged<String> onChanged;
  final String? subtitle;

  const CustomToggle({
    super.key,
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.lightGrey1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: options.map((opt) {
              bool isSelected = currentValue == opt;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.darkGrey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
