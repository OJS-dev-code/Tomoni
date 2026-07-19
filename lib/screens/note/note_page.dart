import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../models/feedback_note.dart';
import '../../services/app_refresh.dart';
import '../../services/api_service.dart';
import '../../services/note_service.dart';
import '../../widgets/note_item.dart';
import 'note_detail_page.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  String sortBy = 'date';
  DateTime filterDate = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;
  List<FeedbackNote> _notes = [];

  @override
  void initState() {
    super.initState();
    AppRefresh.notesChanged.addListener(_onNotesChanged);
    _loadNotes();
  }

  @override
  void dispose() {
    AppRefresh.notesChanged.removeListener(_onNotesChanged);
    super.dispose();
  }

  void _onNotesChanged() {
    _loadNotes();
  }

  void reloadNotes() => _loadNotes();

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final notes = await NoteService.instance.getNotes(
        year: filterDate.year,
        month: filterDate.month,
      );
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      filterDate = DateTime(filterDate.year, filterDate.month + delta);
    });
    _loadNotes();
  }

  Future<void> _showMonthPickerSheet() async {
    int tempYear = filterDate.year;
    int tempMonth = filterDate.month;
    final now = DateTime.now();
    const startYear = 2024;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey1,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '연도 · 월 선택',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: tempYear - startYear,
                          ),
                          itemExtent: 36,
                          onSelectedItemChanged: (index) {
                            tempYear = startYear + index;
                          },
                          children: List.generate(
                            now.year - startYear + 2,
                            (index) => Center(
                              child: Text(
                                '${startYear + index}년',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: tempMonth - 1,
                          ),
                          itemExtent: 36,
                          onSelectedItemChanged: (index) {
                            tempMonth = index + 1;
                          },
                          children: List.generate(
                            12,
                            (index) => Center(
                              child: Text(
                                '${index + 1}월',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.lightGrey1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('취소', style: TextStyle(color: AppColors.darkGrey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            filterDate = DateTime(tempYear, tempMonth);
                          });
                          Navigator.pop(context);
                          _loadNotes();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepYellow,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('적용'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<FeedbackNote> get _sortedNotes {
    final list = List<FeedbackNote>.from(_notes);
    if (sortBy == 'date') {
      list.sort((a, b) => b.date.compareTo(a.date));
    } else {
      list.sort((a, b) => b.score.compareTo(a.score));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _sortedNotes;

    return Scaffold(
      backgroundColor: AppColors.background,
        body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
            Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "피드백 노트",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF807019),
                    ),
                  ),

                  Row(
                    children: [
                      _buildSortButton("날짜 순", "date"),
                      const Text(" | "),
                      _buildSortButton("점수 순", "score"),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 12),
            Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left, color: AppColors.darkGrey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showMonthPickerSheet,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('yyyy년 M월').format(filterDate),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.black.withValues(alpha: 0.45),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right, color: AppColors.darkGrey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.darkGrey),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _loadNotes,
                                  child: const Text('다시 시도'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredList.isEmpty
                          ? const Center(
                              child: Text(
                                '이 달에 작성된 피드백 노트가 없습니다.',
                                style: TextStyle(color: AppColors.darkGrey),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotes,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final note = filteredList[index];
                                  return NoteItem(
                                    note: note,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NoteDetailPage(note: note),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildSortButton(String label, String value) {
    final isSelected = sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => sortBy = value),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? AppColors.deepYellow : Colors.black45,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
