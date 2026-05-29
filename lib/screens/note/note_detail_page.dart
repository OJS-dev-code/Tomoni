import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_constants.dart';
import '../../models/feedback_note.dart';
import 'package:intl/intl.dart';

class NoteDetailPage extends StatelessWidget {
  final FeedbackNote note;

  const NoteDetailPage({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더: 이전 버튼(좌) 및 날짜(우)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset(
                      AppIcons.previousNoBg,
                      width: 32,
                      height: 32,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy.MM.dd').format(note.date),
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // 주제 및 별점
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
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SvgPicture.asset(
                            index < note.score ? AppIcons.starFull : AppIcons.starEmpty,
                            width: 45,
                            height: 45,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "피드백 :",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // 아코디언 피드백 항목들
              const Divider(height: 1, thickness: 1, color: Colors.black12),
              ...note.items.asMap().entries.map((entry) {
                int idx = entry.key;
                FeedbackItem item = entry.value;
                return Column(
                  children: [
                    _buildFeedbackAccordion(idx + 1, item),
                    const Divider(height: 1, thickness: 1, color: Colors.black12),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackAccordion(int index, FeedbackItem item) {
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        "($index) ${item.title}",
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
      ),
      iconColor: AppColors.darkGrey,
      collapsedIconColor: AppColors.darkGrey,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.description != null) ...[
                Text(
                  item.description!,
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                item.japanese,
                style: const TextStyle(color: AppColors.pinkyRed, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                item.pronunciation,
                style: const TextStyle(color: Colors.blueAccent, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                item.translation,
                style: const TextStyle(color: AppColors.darkGrey, fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
