import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/custom_button.dart';

class Step1Widget extends StatefulWidget {
  final PageController pageController;

  const Step1Widget({super.key, required this.pageController});

  @override
  _Step1WidgetState createState() => _Step1WidgetState();
}

class _Step1WidgetState extends State<Step1Widget> {
  String? selectedGender;
  int selectedYear = 2000;
  int selectedMonth = 1;
  int selectedDay = 1;

  final List<int> years = List.generate(100, (index) => DateTime.now().year - index);
  final List<int> months = List.generate(12, (index) => index + 1);
  final List<int> days = List.generate(31, (index) => index + 1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "성별과 생년월일을\n입력해주세요",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
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
                _buildPicker(years, (val) => setState(() => selectedYear = years[val]), years.indexOf(selectedYear), "년"),
                _buildPicker(months, (val) => setState(() => selectedMonth = months[val]), months.indexOf(selectedMonth), "월"),
                _buildPicker(days, (val) => setState(() => selectedDay = days[val]), days.indexOf(selectedDay), "일"),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: CustomButton(
              text: "다음",
              onPressed: (selectedGender != null)
                  ? () => widget.pageController.nextPage(
                      duration: const Duration(milliseconds: 300), curve: Curves.ease)
                  : null,
            ),
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

  Widget _buildPicker(List<int> items, ValueChanged<int> onSelectedItemChanged, int initialIndex, String unit) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CupertinoPicker(
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
