import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/feedback_note.dart';

class HomeCalendar extends StatefulWidget {
  const HomeCalendar({super.key});

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  DateTime _focusedDay = DateTime.now();

  void _updateMonth(DateTime newDate) {
    setState(() {
      _focusedDay = newDate;
    });
  }

  // 대한민국 공휴일 체크 로직 (양력 기준)
  bool _isHoliday(DateTime date) {
    // 일요일 체크 (weekday: 7)
    if (date.weekday == 7) return true;

    // 주요 법정 공휴일 (양력)
    final String md = "${date.month}-${date.day}";
    const holidays = {
      "1-1": "신정",
      "3-1": "삼일절",
      "5-5": "어린이날",
      "6-6": "현충일",
      "8-15": "광복절",
      "10-3": "개천절",
      "10-9": "한글날",
      "12-25": "성탄절",
    };
    return holidays.containsKey(md);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // 12pt 모서리
      ),
      child: Column(
        children: [
          _CalendarHeader(
            focusedDay: _focusedDay,
            onMonthChanged: _updateMonth,
          ),
          const SizedBox(height: 25),
          _CalendarGrid(
            focusedDay: _focusedDay,
            isHoliday: _isHoliday,
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final ValueChanged<DateTime> onMonthChanged;

  const _CalendarHeader({
    required this.focusedDay,
    required this.onMonthChanged,
  });

  void _showPicker(BuildContext context) {
    int tempYear = focusedDay.year;
    int tempMonth = focusedDay.month;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("연도 및 월 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          height: 200,
          child: Row(
            children: [
              // 연도 선택기
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(initialItem: tempYear - 2026),
                  onSelectedItemChanged: (index) => tempYear = 2026 + index,
                  children: List.generate(100, (i) => Center(child: Text("${2026 + i}년"))), // 2026년부터 100년간 선택 가능
                ),
              ),
              // 월 선택기
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(initialItem: tempMonth - 1),
                  onSelectedItemChanged: (index) => tempMonth = index + 1,
                  children: List.generate(12, (i) => Center(child: Text("${i + 1}월"))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () {
              onMonthChanged(DateTime(tempYear, tempMonth));
              Navigator.pop(context);
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text("학습 캘린더", style: headerStyle),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _showPicker(context),
              child: Row(
                children: [
                  Text("${focusedDay.year}년 ${focusedDay.month}월", style: headerStyle),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.black87),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => onMonthChanged(DateTime(focusedDay.year, focusedDay.month - 1)),
                  icon: const Icon(Icons.chevron_left, color: AppColors.darkGrey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 15),
                IconButton(
                  onPressed: () => onMonthChanged(DateTime(focusedDay.year, focusedDay.month + 1)),
                  icon: const Icon(Icons.chevron_right, color: AppColors.darkGrey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedDay;
  final bool Function(DateTime) isHoliday;

  const _CalendarGrid({
    required this.focusedDay,
    required this.isHoliday,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7;
    final List<String> weekDays = ["日", "月", "火", "水", "木", "金", "土"];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) {
            Color textColor = AppColors.darkGrey;
            if (day == "日") textColor = AppColors.pinkyRed;
            if (day == "土") textColor = AppColors.primary;
            return SizedBox(
              width: 40,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: textColor,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10), // 간격 조정
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 0,
          ),
          itemBuilder: (context, index) {
            final dayNum = index - firstWeekday + 1;
            if (dayNum < 1 || dayNum > lastDay.day) return const SizedBox();

            final current = DateTime(focusedDay.year, focusedDay.month, dayNum);
            bool holiday = isHoliday(current);
            bool isToday = current.year == DateTime.now().year && current.month == DateTime.now().month && current.day == DateTime.now().day;

            // 해당 날짜의 피드백 노트 개수 확인
            final noteCount = sampleNotes.where((note) => 
              note.date.year == current.year && 
              note.date.month == current.month && 
              note.date.day == current.day).length;

            Color? noteColor;
            if (noteCount == 1) {
              noteColor = AppColors.pastelGreen;
            } else if (noteCount == 2) {
              noteColor = AppColors.pastelYellow;
            } else if (noteCount >= 3) {
              noteColor = AppColors.heavyYellow;
            }

            return Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isToday ? Colors.transparent : (noteColor ?? Colors.transparent),
                  shape: BoxShape.circle,
                  border: isToday 
                    ? Border.all(color: AppColors.black, width: 0.8)
                    : null,
                ),
                child: Center(
                  child: Text(
                    "$dayNum",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: holiday ? AppColors.pinkyRed : (current.weekday == 6 ? AppColors.primary : Colors.black87),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
