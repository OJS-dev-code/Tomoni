import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/step_navigation_buttons.dart';
import '../../../widgets/step_header.dart';

class Step1Widget extends StatefulWidget {
  final PageController pageController;
  final Function(String gender, int year, int month, int day) onCompleted;

  const Step1Widget({
    super.key, 
    required this.pageController,
    required this.onCompleted,
  });

  @override
  State<Step1Widget> createState() => _Step1WidgetState();
}

class _Step1WidgetState extends State<Step1Widget> {
  String? selectedGender;
  int selectedYear = 2000;
  int selectedMonth = 1;
  int selectedDay = 1;

  final List<int> years = List.generate(100, (index) => DateTime.now().year - index);
  final List<int> months = List.generate(12, (index) => index + 1);

  List<int> get daysInMonth {
    int lastDay = DateTime(selectedYear, selectedMonth + 1, 0).day;
    return List.generate(lastDay, (index) => index + 1);
  }

  @override
  Widget build(BuildContext context) {
    List<int> currentDays = daysInMonth;
    if (selectedDay > currentDays.length) {
      selectedDay = currentDays.length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(title: "성별과 생년월일을\n입력해주세요"),
          const Text("성별", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGenderButton("여성", "female")),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderButton("남성", "male")),
            ],
          ),
          const SizedBox(height: 40),
          const Text("생년월일", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                _buildPicker(
                  years, 
                  (val) => setState(() => selectedYear = years[val]), 
                  years.indexOf(selectedYear), 
                  "년"
                ),
                _buildPicker(
                  months, 
                  (val) => setState(() => selectedMonth = months[val]), 
                  months.indexOf(selectedMonth), 
                  "월"
                ),
                _buildPicker(
                  currentDays, 
                  (val) => setState(() => selectedDay = currentDays[val]), 
                  currentDays.indexOf(selectedDay), 
                  "일",
                  key: ValueKey("$selectedYear-$selectedMonth")
                ),
              ],
            ),
          ),
          const Spacer(),
          StepNavigationButtons(
            pageController: widget.pageController,
            showPrevious: false,
            isNextEnabled: selectedGender != null,
            onNext: () {
              widget.onCompleted(selectedGender!, selectedYear, selectedMonth, selectedDay);
              widget.pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    bool isSelected = selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => selectedGender = value),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGrey1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPicker(List<int> items, ValueChanged<int> onSelectedItemChanged, int initialIndex, String unit, {Key? key}) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CupertinoPicker(
            key: key,
            itemExtent: 40,
            scrollController: FixedExtentScrollController(initialItem: initialIndex),
            onSelectedItemChanged: onSelectedItemChanged,
            children: items.map((item) => Center(child: Text("$item"))).toList(),
          ),
          Positioned(
            right: 10,
            child: Text(unit, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
