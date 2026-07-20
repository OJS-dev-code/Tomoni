import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/feedback_note.dart';
import '../services/app_refresh.dart';
import '../services/api_service.dart';
import '../services/note_service.dart';

class HomeCalendar extends StatefulWidget {
  const HomeCalendar({super.key});

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  DateTime _focusedDay = DateTime.now();
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

  DateTime _startOfWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  DateTime _endOfWeek(DateTime date) {
    return _startOfWeek(date).add(const Duration(days: 6));
  }

  Future<void> _loadNotes() async {
    final weekStart = _startOfWeek(_focusedDay);
    final weekEnd = _endOfWeek(_focusedDay);

    final months = <String, ({int year, int month})>{};
    void addMonth(DateTime d) {
      final key = '${d.year}-${d.month}';
      months[key] = (year: d.year, month: d.month);
    }

    addMonth(weekStart);
    addMonth(weekEnd);

    try {
      final results = await Future.wait(
        months.values.map(
          (m) => NoteService.instance.getNotes(year: m.year, month: m.month),
        ),
      );

      final merged = <String, FeedbackNote>{};
      for (final list in results) {
        for (final note in list) {
          merged[note.id] = note;
        }
      }

      if (!mounted) return;
      setState(() => _notes = merged.values.toList());
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _notes = []);
    }
  }

  void _updateFocusedDay(DateTime newDate) {
    setState(() => _focusedDay = newDate);
    _loadNotes();
  }

  void _changeWeek(int deltaWeeks) {
    _updateFocusedDay(_focusedDay.add(Duration(days: 7 * deltaWeeks)));
  }

  bool _isHoliday(DateTime date) {
    if (date.weekday == 7) return true;

    final md = '${date.month}-${date.day}';
    const holidays = {
      '1-1': '신정',
      '3-1': '삼일절',
      '5-5': '어린이날',
      '6-6': '현충일',
      '8-15': '광복절',
      '10-3': '개천절',
      '10-9': '한글날',
      '12-25': '성탄절',
    };
    return holidays.containsKey(md);
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _startOfWeek(_focusedDay);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        children: [
          _CalendarHeader(
            weekStart: weekStart,
            weekEnd: _endOfWeek(_focusedDay),
            onDateSelected: _updateFocusedDay,
            onWeekChanged: _changeWeek,
          ),
          const SizedBox(height: 16),
          _WeekCalendarRow(
            weekStart: weekStart,
            isHoliday: _isHoliday,
            notes: _notes,
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<int> onWeekChanged;

  const _CalendarHeader({
    required this.weekStart,
    required this.weekEnd,
    required this.onDateSelected,
    required this.onWeekChanged,
  });

  String _formatWeekRange() {
    if (weekStart.year == weekEnd.year && weekStart.month == weekEnd.month) {
      return '${weekStart.year}년 ${weekStart.month}월 ${weekStart.day}일 - ${weekEnd.day}일';
    }
    if (weekStart.year == weekEnd.year) {
      return '${weekStart.year}년 ${weekStart.month}월 ${weekStart.day}일 - '
          '${weekEnd.month}월 ${weekEnd.day}일';
    }
    return '${weekStart.year}년 ${weekStart.month}월 ${weekStart.day}일 - '
        '${weekEnd.year}년 ${weekEnd.month}월 ${weekEnd.day}일';
  }

  void _showPicker(BuildContext context) {
    DateTime tempDate = weekStart;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '날짜 선택',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          height: 200,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: tempDate,
            minimumDate: DateTime(2020),
            maximumDate: DateTime(2100),
            onDateTimeChanged: (value) => tempDate = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              onDateSelected(tempDate);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () => _showPicker(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _formatWeekRange(),
                    style: headerStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.black87),
              ],
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => onWeekChanged(-1),
              icon: const Icon(Icons.chevron_left, color: AppColors.darkGrey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 15),
            IconButton(
              onPressed: () => onWeekChanged(1),
              icon: const Icon(Icons.chevron_right, color: AppColors.darkGrey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekCalendarRow extends StatelessWidget {
  final DateTime weekStart;
  final bool Function(DateTime) isHoliday;
  final List<FeedbackNote> notes;

  const _WeekCalendarRow({
    required this.weekStart,
    required this.isHoliday,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: weekDays.map((day) {
            Color textColor = AppColors.darkGrey;
            if (day == '일') textColor = AppColors.deepYellow;
            if (day == '토') textColor = AppColors.navy;
            return Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: textColor),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (index) {
            final current = weekStart.add(Duration(days: index));
            final holiday = isHoliday(current);
            final isToday = current.year == today.year &&
                current.month == today.month &&
                current.day == today.day;

            final noteCount = notes
                .where(
                  (note) =>
                      note.date.year == current.year &&
                      note.date.month == current.month &&
                      note.date.day == current.day,
                )
                .length;

            Color? noteColor;
            if (noteCount == 1) {
              noteColor = const Color(0xFFF8F2D9);
            } else if (noteCount == 2) {
              noteColor = const Color(0xFFF1E2A3);
            } else if (noteCount >= 3) {
              noteColor = const Color(0xFFE8D27A);
            }

            return Expanded(
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.transparent
                        : (noteColor ?? Colors.transparent),
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(color: AppColors.black, width: 0.8)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${current.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: holiday
                            ? AppColors.deepYellow
                            : (current.weekday == 6
                                ? AppColors.navy
                                : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
