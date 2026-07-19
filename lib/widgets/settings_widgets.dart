import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SettingsContainer extends StatelessWidget {
  final Widget child;
  final double verticalPadding;

  const SettingsContainer({
    super.key,
    required this.child,
    this.verticalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// 설정 항목을 감싸고 좌측 상단에 인포 버튼을 배치하는 베이스 위젯
class SettingsTileBase extends StatelessWidget {
  final Widget child;

  const SettingsTileBase({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      child: child,
    );
  }
}

/// 인라인 칩 리스트와 입력창이 결합된 편집 위젯 (전체를 흰색 영역으로 감쌈)
class SettingsEditableTags extends StatelessWidget {
  final String title;
  final Set<String> tags;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final Function(String) onDelete;

  const SettingsEditableTags({
    super.key,
    required this.title,
    required this.tags,
    required this.controller,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => Container(
              padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightGrey1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onDelete(tag),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: AppColors.darkGrey),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: "직접 입력",
                    hintStyle: const TextStyle(color: AppColors.lightGrey1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), 
                      borderSide: const BorderSide(color: AppColors.lightGrey1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), 
                      borderSide: const BorderSide(color: AppColors.lightGrey1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("추가"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
