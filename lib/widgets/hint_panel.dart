import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_constants.dart';

/// AI 추천 답변(힌트) 영역 — ChatBubble과 동일한 표시·버튼 규칙
class HintPanel extends StatefulWidget {
  final String text;
  final String? pronunciation;
  final String? translation;
  final bool showJapaneseInitially;
  final bool showTranslationInitially;
  final bool showPronunciationInitially;
  final VoidCallback? onReplay;

  const HintPanel({
    super.key,
    required this.text,
    this.pronunciation,
    this.translation,
    required this.showJapaneseInitially,
    required this.showTranslationInitially,
    required this.showPronunciationInitially,
    this.onReplay,
  });

  @override
  State<HintPanel> createState() => _HintPanelState();
}

class _HintPanelState extends State<HintPanel> {
  bool isJapaneseRevealed = false;
  bool isTranslationVisible = false;
  bool isPronunciationVisible = false;

  @override
  void initState() {
    super.initState();
    isJapaneseRevealed = widget.showJapaneseInitially;
    isTranslationVisible = widget.showTranslationInitially;
    isPronunciationVisible = widget.showPronunciationInitially;
  }

  bool get _hasPronunciation =>
      widget.pronunciation != null && widget.pronunciation!.trim().isNotEmpty;

  bool get _hasTranslation =>
      widget.translation != null && widget.translation!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.red),
              SizedBox(width: 6),
              Text(
                'AI 추천 답변',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isJapaneseRevealed)
            Text(
              widget.text,
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            )
          else
            InkWell(
              onTap: () => setState(() => isJapaneseRevealed = true),
              child: Container(
                padding: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.red, width: 0.8),
                  ),
                ),
                child: const Text(
                  '텍스트로 확인',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
              ),
            ),
          if (_hasPronunciation && isPronunciationVisible) ...[
            const SizedBox(height: 8),
            Text(
              widget.pronunciation!,
              style: const TextStyle(
                color: AppColors.sapphireBlue,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
          if (_hasTranslation && isTranslationVisible) ...[
            const SizedBox(height: 6),
            Text(
              widget.translation!,
              style: const TextStyle(
                color: AppColors.darkGrey,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (widget.onReplay != null)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.showPronunciationInitially && _hasPronunciation) ...[
                      _iconButton(
                        AppIcons.pronunciation,
                        () => setState(
                          () => isPronunciationVisible = !isPronunciationVisible,
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Colors.black12),
                    ],
                    if (!widget.showTranslationInitially && _hasTranslation) ...[
                      _iconButton(
                        AppIcons.translate,
                        () => setState(
                          () => isTranslationVisible = !isTranslationVisible,
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Colors.black12),
                    ],
                    _iconButton(AppIcons.replay, widget.onReplay!),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconButton(String iconPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SvgPicture.asset(
          iconPath,
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
        ),
      ),
    );
  }
}
