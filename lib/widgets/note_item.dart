import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/feedback_note.dart';
import '../../constants/app_constants.dart';

class NoteItem extends StatelessWidget {
  final FeedbackNote note;
  final VoidCallback onTap;

  const NoteItem({
    super.key,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), // 박스 사이 간격
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // 라운드 제거
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜
                Text(
                  DateFormat('MM.dd').format(note.date),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // 대화 주제
                Text(
                  note.topic,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 13,
              child: Row(
                children: [
                  Text(
                    "${note.score} / 5",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF807019),
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 25,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),

          ],
        )
      ),
    );
  }
}
