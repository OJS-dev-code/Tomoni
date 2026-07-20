import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_constants.dart';

class ChatBubble extends StatefulWidget {
  final String text;
  final String? pronunciation;
  final String? translation;
  final bool isAI;
  final bool isRecommended;

  // 사용자 설정에 따른 초기값
  final bool showJapaneseInitially;
  final bool showTranslationInitially;
  final bool showPronunciationInitially;
  final String aiSpeedSetting;
  final VoidCallback? onReplay;
  final VoidCallback? onSpeedTap;

  const ChatBubble({
    super.key,
    required this.text,
    this.pronunciation,
    this.translation,
    required this.isAI,
    this.isRecommended = false,
    required this.showJapaneseInitially,
    required this.showTranslationInitially,
    required this.showPronunciationInitially,
    required this.aiSpeedSetting,
    this.onReplay,
    this.onSpeedTap,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool isJapaneseRevealed = false;
  bool isTranslationVisible = false;
  bool isPronunciationVisible = false;

  @override
  void initState() {
    super.initState();
    isJapaneseRevealed = widget.showJapaneseInitially || !widget.isAI;
    isTranslationVisible = widget.showTranslationInitially;
    isPronunciationVisible = widget.showPronunciationInitially;
  }

  bool get _hasPronunciation =>
      widget.pronunciation != null && widget.pronunciation!.trim().isNotEmpty;

  bool get _hasTranslation =>
      widget.translation != null && widget.translation!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    Color japaneseColor = AppColors.deepBrown;
    if (!widget.isAI && widget.isRecommended) {
      japaneseColor = AppColors.red;
    }

    return Align(
      alignment: widget.isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: widget.isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: widget.isAI
                      ? const Color(0xFFFFFCF3)
                      : const Color(0xFFFFEB99),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(widget.isAI ? 4 : 16),
                  bottomRight: Radius.circular(widget.isAI ? 16 : 4),
                ),
                border: Border.all(
                  color: widget.isAI
                      ? const Color(0xFFE5DED0)
                      : const Color(0xFFF2C94C),
                  width: 1.2,
                ),              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 일본어 텍스트 (사용자이거나 설정이 켜져있으면 표시, AI이면서 설정이 꺼져있으면 버튼으로 표시)
                  if (isJapaneseRevealed || !widget.isAI)
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: japaneseColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => setState(() => isJapaneseRevealed = true),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 2), // 밑줄과의 간격
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.egyptianBlue, width: 0.8),
                          ),
                        ),
                        child: const Text(
                          "텍스트로 확인",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepBrown,
                          ),
                        ),
                      ),
                    ),

                  // 2. 발음 표시 (발음 버튼으로 토글)
                  if (widget.pronunciation != null && isPronunciationVisible) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.pronunciation!,
                      style: const TextStyle(
                        color: AppColors.deepYellow,
                        fontSize: 14,
                      ),
                    ),
                  ],

                  // 3. 번역 표시 (설정에 따라 자동 노출되거나 번역 버튼으로 토글)
                  if (widget.translation != null && isTranslationVisible) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.translation!,
                      style: const TextStyle(
                        color: AppColors.darkGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 4. 하단 버튼 영역 (통합된 디자인)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!widget.showPronunciationInitially && _hasPronunciation) ...[
                                _buildGroupButton(
                                  AppIcons.pronunciation,
                                  () => setState(
                                    () => isPronunciationVisible = !isPronunciationVisible,
                                  ),
                                ),
                                const VerticalDivider(width: 1, color: Colors.black12),
                              ],

                              if (!widget.showTranslationInitially && _hasTranslation) ...[
                                _buildGroupButton(
                                  AppIcons.translate,
                                  () => setState(
                                    () => isTranslationVisible = !isTranslationVisible,
                                  ),
                                ),
                                const VerticalDivider(width: 1, color: Colors.black12),
                              ],

                              if (widget.isAI && widget.onSpeedTap != null) ...[
                                _buildGroupButton(
                                  widget.aiSpeedSetting.contains("천천히")
                                      ? AppIcons.tellFaster
                                      : AppIcons.tellSlower,
                                  widget.onSpeedTap!,
                                ),
                                const VerticalDivider(width: 1, color: Colors.black12),
                              ],

                              // 다시듣기 버튼
                              if (widget.onReplay != null)
                                _buildGroupButton(AppIcons.replay, widget.onReplay!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupButton(String iconPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
