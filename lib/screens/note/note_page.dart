import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/feedback_note.dart';
import '../../widgets/note_item.dart';
import 'note_detail_page.dart';
import 'package:intl/intl.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  String sortBy = "date";
  DateTime filterDate = DateTime(2026, 4);

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("연도 및 월 선택"),
        content: SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(initialItem: filterDate.year - 2020),
                  onSelectedItemChanged: (i) => setState(() => filterDate = DateTime(2020+i, filterDate.month)),
                  children: List.generate(10, (i) => Center(child: Text("${2020+i}년"))),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(initialItem: filterDate.month - 1),
                  onSelectedItemChanged: (i) => setState(() => filterDate = DateTime(filterDate.year, i+1)),
                  children: List.generate(12, (i) => Center(child: Text("${i+1}월"))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<FeedbackNote> filteredList = sampleNotes.where((note) => 
      note.date.year == filterDate.year && note.date.month == filterDate.month).toList();

    if (sortBy == "date") {
      filteredList.sort((a, b) => b.date.compareTo(a.date));
    } else {
      filteredList.sort((a, b) => b.score.compareTo(a.score));
    }

    return Scaffold(
      backgroundColor: AppColors.pastelLightgreen,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40), 
            
            // 1. 최상단 타이틀 & 정렬 박스
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "피드백 노트",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _buildSortButton("날짜 순", "date"),
                        const Text(" | ", style: TextStyle(color: Colors.black26)),
                        _buildSortButton("점수 순", "score"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12), // 배경색이 비치는 간격
            
            // 2. 날짜 선택 바 박스
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: _showMonthPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy.MM').format(filterDate),
                        style: const TextStyle(
                          fontSize: 20, // 크기 고정 및 축소
                          fontWeight: FontWeight.normal, // 굵기 제거
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.black87),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12), // 배경색이 비치는 간격

            // 3. 리스트 영역
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final note = filteredList[index];
                  return NoteItem(
                    note: note,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NoteDetailPage(note: note)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, String value) {
    bool isSelected = sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => sortBy = value),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? AppColors.primary : Colors.black45,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
