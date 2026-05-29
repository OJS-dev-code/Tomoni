import 'package:flutter/material.dart';
import '../../widgets/scenario_widgets.dart';
import 'scenario_confirm_page.dart';

class ScenarioGoalPage extends StatefulWidget {
  final String topic;

  const ScenarioGoalPage({super.key, required this.topic});

  @override
  State<ScenarioGoalPage> createState() => _ScenarioGoalPageState();
}

class _ScenarioGoalPageState extends State<ScenarioGoalPage> {
  final List<String> recommendations = ["목표명 1", "목표명 2", "목표명 3"];
  final List<String> customGoals = [];
  final Set<String> selectedGoals = {};
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ScenarioPageLayout(
      title: widget.topic,
      onConfirm: () {
        if (selectedGoals.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScenarioConfirmPage(
                topic: widget.topic,
                goals: selectedGoals.toList(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("대화 목표를 하나 이상 선택해주세요.")),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScenarioSectionTitle(title: "AI의 추천 목표"),
          ...recommendations.asMap().entries.map((entry) {
            final goal = entry.value;
            final index = entry.key + 1;
            final isSelected = selectedGoals.contains(goal);
            return ScenarioItemBox(
              onTap: () => setState(() {
                if (isSelected) selectedGoals.remove(goal);
                else selectedGoals.add(goal);
              }),
              onDelete: () {}, 
              child: Text("($index) $goal", style: const TextStyle(fontSize: 18)), 
            );
          }),
          const SizedBox(height: 20),
          const ScenarioSectionTitle(title: "직접 목표 입력하기"),
          ScenarioInputRow(
            controller: _controller,
            onAdd: () {
              if (_controller.text.isNotEmpty) {
                setState(() {
                  customGoals.add(_controller.text);
                  selectedGoals.add(_controller.text);
                  _controller.clear();
                });
              }
            },
          ),
          const SizedBox(height: 12),
          ...customGoals.asMap().entries.map((entry) {
            final goal = entry.value;
            final index = recommendations.length + entry.key + 1;
            final isSelected = selectedGoals.contains(goal);
            return ScenarioItemBox(
              onTap: () => setState(() {
                if (isSelected) selectedGoals.remove(goal);
                else selectedGoals.add(goal);
              }),
              onDelete: () => setState(() {
                customGoals.remove(goal);
                selectedGoals.remove(goal);
              }),
              child: Text("($index) $goal", style: const TextStyle(fontSize: 18)),
            );
          }),
          const SizedBox(height: 30),
          // 하단 선정한 목표 요약
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            width: double.infinity,
            child: Row(
              children: [
                const Text("선정한 목표 : ", style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    selectedGoals.map((g) {
                      int idx = recommendations.indexOf(g);
                      if (idx != -1) return "(${idx + 1})";
                      int cIdx = customGoals.indexOf(g);
                      if (cIdx != -1) return "(${recommendations.length + cIdx + 1})";
                      return "";
                    }).join(" "),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
