import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/scenario_service.dart';
import '../../widgets/scenario_widgets.dart';
import 'scenario_confirm_page.dart';

class ScenarioGoalPage extends StatefulWidget {
  final String topic;

  const ScenarioGoalPage({super.key, required this.topic});

  @override
  State<ScenarioGoalPage> createState() => _ScenarioGoalPageState();
}

class _ScenarioGoalPageState extends State<ScenarioGoalPage> {
  List<String> recommendations = [];
  final List<String> customGoals = [];
  final Set<String> selectedGoals = {};
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;

  static const _selectedColor = Color(0xFF807019);

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await ScenarioService.instance.getGoals(widget.topic);
      if (mounted) {
        setState(() {
          recommendations = goals.take(3).toList();
          _isLoading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Widget _buildGoalCard(String goal) {
    final isSelected = selectedGoals.contains(goal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedGoals.remove(goal);
            } else {
              selectedGoals.add(goal);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _selectedColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(goal, style: const TextStyle(fontSize: 15)),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? _selectedColor : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            const SnackBar(
              content: Text("대화 목표를 하나 이상 선택해주세요."),
            ),
          );
        }
      },
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _selectedColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "대화 목표 선택",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "이번 대화에서 달성하고 싶은\n목표를 선택해보세요.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text(
                  "🎯 AI의 추천 목표",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (recommendations.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      "이 주제에 맞는 추천 목표가 없습니다. 아래에서 직접 입력해주세요.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  )
                else
                  ...recommendations.map(_buildGoalCard),
                const SizedBox(height: 24),
                const Text(
                  "✏ 직접 목표 입력하기",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "달성하고 싶은 목표를 입력하세요",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          final text = _controller.text.trim();
                          if (text.isEmpty) return;
                          setState(() {
                            if (!customGoals.contains(text)) {
                              customGoals.add(text);
                            }
                            selectedGoals.add(text);
                            _controller.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F6B95),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("추가"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...customGoals.map(_buildGoalCard),
              ],
            ),
    );
  }
}
