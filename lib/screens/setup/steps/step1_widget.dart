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
  DateTime? selectedBirthDate;


  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(title: "성별과 생년월일을\n입력해주세요"),
          const Text("성별", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  "여성",
                  "female",
                  Icons.female,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderCard(
                  "남성",
                  "male",
                  Icons.male,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text("생년월일", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedBirthDate ?? DateTime(2000),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
              );

              if (pickedDate != null) {
                setState(() {
                  selectedBirthDate = pickedDate;
                });
              }
            },
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),

              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedBirthDate == null
                          ? "생년월일을 선택해주세요"
                          : "${selectedBirthDate!.year}.${selectedBirthDate!.month.toString().padLeft(2, '0')}.${selectedBirthDate!.day.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedBirthDate == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_month),
                ],
              ),
            ),
          ),

          const Spacer(),
          StepNavigationButtons(
            pageController: widget.pageController,
            showPrevious: false,
            isNextEnabled:
            selectedGender != null&&
            selectedBirthDate != null,
            onNext: () {
              widget.onCompleted(
                  selectedGender!,
                  selectedBirthDate!.year,
                  selectedBirthDate!.month,
                  selectedBirthDate!.day,
              );
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

  Widget _buildGenderCard(
      String label,
      String value,
      IconData icon,
      ) {
    bool isSelected = selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = value;
        });
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.deepYellow
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: value == "female"
                  ? const Color(0xFFEAF3FB)
                  : const Color(0xFFFFF4D6),
              child: Icon(
                icon,
                color: value == "female"
                    ? const Color(0xFF3A6D9A)
                    : const Color(0xFF8A6A00),
                size: 32,
              ),
            ),

            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


}
