import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../models/feedback_note.dart';
import '../../widgets/custom_button.dart';

class NoteDetailPage extends StatelessWidget {
  final FeedbackNote note;
  final bool showHomeButton;

  const NoteDetailPage({
    super.key,
    required this.note,
    this.showHomeButton = false,
  });

  void _goHome(BuildContext context) {
    Navigator.popUntil(context, ModalRoute.withName('/main'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.black87,
                    splashRadius: 20,
                  ),
                  Text(
                    DateFormat('yyyy.MM.dd').format(note.date),
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Text(
                      note.topic,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: SvgPicture.asset(
                            index < note.score ? AppIcons.starFull : AppIcons.starEmpty,
                            width: 25,
                            height: 25,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    const Divider(
                      thickness: 1,
                      color: AppColors.border,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (note.hintResponses.isNotEmpty) ...[
                const Text(
                  '힌트대로 답한 표현 :',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, thickness: 1, color: Colors.black12),
                ...note.hintResponses.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      _buildHintResponseAccordion(idx + 1, item),
                      const Divider(height: 1, thickness: 1, color: Colors.black12),
                    ],
                  );
                }),
                const SizedBox(height: 28),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    size: 22,
                    color: AppColors.deepYellow,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '피드백',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...note.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return _buildFeedbackAccordion(idx + 1, item);
              }),
              if (showHomeButton) ...[
                const SizedBox(height: 36),
                CustomButton(
                  text: '홈 화면으로',
                  onPressed: () => _goHome(context),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintResponseAccordion(int index, HintResponseItem item) {
    return ExpansionTile(
      initiallyExpanded: true,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        '($index) 힌트 내용대로 답함',
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.primary,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '제시된 힌트',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGrey),
              ),
              const SizedBox(height: 8),
              Text(
                item.hintText,
                style: const TextStyle(color: AppColors.deepBrown, fontSize: 16, height: 1.4),
              ),
              if (item.hintPronunciation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.hintPronunciation,
                  style: const TextStyle(color: AppColors.deepYellow, fontSize: 15, height: 1.4),
                ),
              ],
              if (item.hintTranslation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.hintTranslation,
                  style: const TextStyle(color: AppColors.darkGrey, fontSize: 15, height: 1.4),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                '내가 말한 표현',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGrey),
              ),
              const SizedBox(height: 8),
              Text(
                item.userText,
                style: const TextStyle(color: AppColors.deepBrown, fontSize: 16, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildFeedbackAccordion(int index, FeedbackItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        iconColor: AppColors.darkGrey,
        collapsedIconColor: AppColors.darkGrey,
        title: Row(
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF1CC),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.description != null) ...[
                  Text(
                    item.description!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
                const Divider(
                  height: 24,
                  thickness: 1,
                  color: AppColors.border,
                ),
                if (item.japanese.isNotEmpty) ...[
                  Text(
                    item.japanese,
                    style: const TextStyle(
                      color: AppColors.deepBrown,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (item.pronunciation.isNotEmpty) ...[
                  Text(
                    item.pronunciation,
                    style: const TextStyle(
                      color: AppColors.deepYellow,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (item.translation.isNotEmpty)
                  Text(
                    item.translation,
                    style: const TextStyle(
                      color: AppColors.darkGrey,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
