import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/feedback_note.dart';

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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero, // 라운드 제거
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 첫 번째 줄: 날짜
            Text(
              DateFormat('MM.dd').format(note.date),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            // 두 번째 줄: 주제 + 점수
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.topic,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "${note.score} / 5",
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
