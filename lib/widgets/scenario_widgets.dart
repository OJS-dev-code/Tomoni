import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_button.dart';

/// 상황극 설정 페이지의 공통 레이아웃 (확인 버튼을 하단 고정에서 콘텐츠 끝으로 이동)
class ScenarioPageLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onConfirm;
  final String confirmText;

  const ScenarioPageLayout({
    super.key,
    required this.title,
    required this.child,
    required this.onConfirm,
    this.confirmText = "확인",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 20),

            child,
            const SizedBox(height: 40),
            // 하단 확인 버튼
            CustomButton(
              text: confirmText,
              onPressed: onConfirm,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// 상황극 아이템 박스 (라운드 제거 및 패딩 축소)
class ScenarioItemBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onDelete;

  const ScenarioItemBox({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6), // 간격 줄임 (10 -> 6)
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.pinkyRed, width: 2) : null,
        ),
        child: Row(
          children: [
            Expanded(child: child),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, color: Colors.redAccent, size: 24),
              ),
          ],
        ),
      ),
    );
  }
}

/// 상황극 섹션 헤더 (패딩 확대 및 글씨 키움)
class ScenarioSectionTitle extends StatelessWidget {
  final String title;
  const ScenarioSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12, top: 10), // 리스트와의 간격 확보 (bottom: 12)
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 상황극 입력 필드 (언더바 색상을 primary로 수정)
class ScenarioInputRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const ScenarioInputRow({
    super.key,
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // 입력창 영역도 12pt 라운드 적용
      ),
      child: Row(
        children: [
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.primary),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Colors.black26),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("추가", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
