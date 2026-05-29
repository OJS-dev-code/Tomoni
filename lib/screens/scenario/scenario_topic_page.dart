import 'package:flutter/material.dart';
import '../../widgets/scenario_widgets.dart';
import 'scenario_goal_page.dart';

class ScenarioTopicPage extends StatefulWidget {
  const ScenarioTopicPage({super.key});

  @override
  State<ScenarioTopicPage> createState() => _ScenarioTopicPageState();
}

class _ScenarioTopicPageState extends State<ScenarioTopicPage> {
  final List<String> recommendations = ["주제명 1", "주제명 2", "주제명 3"];
  final List<String> customTopics = [];
  String? selectedTopic;
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ScenarioPageLayout(
      title: "대화 주제 선정",
      onConfirm: () {
        if (selectedTopic != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScenarioGoalPage(topic: selectedTopic!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("주제를 선택해주세요.")),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScenarioSectionTitle(title: "AI의 추천 주제"),
          ...recommendations.asMap().entries.map((entry) {
            final topic = entry.value;
            final index = entry.key + 1;
            return ScenarioItemBox(
              isSelected: selectedTopic == topic,
              onTap: () => setState(() => selectedTopic = topic),
              child: Text("($index) $topic", style: const TextStyle(fontSize: 18)),
            );
          }),
          const SizedBox(height: 20),
          const ScenarioSectionTitle(title: "직접 주제 입력하기"),
          ScenarioInputRow(
            controller: _controller,
            onAdd: () {
              if (_controller.text.isNotEmpty) {
                setState(() {
                  customTopics.add(_controller.text);
                  _controller.clear();
                });
              }
            },
          ),
          const SizedBox(height: 12),
          ...customTopics.map((topic) => ScenarioItemBox(
                isSelected: selectedTopic == topic,
                onTap: () => setState(() => selectedTopic = topic),
                onDelete: () => setState(() {
                  customTopics.remove(topic);
                  if (selectedTopic == topic) selectedTopic = null;
                }),
                child: Text(topic, style: const TextStyle(fontSize: 18, color: Colors.blue)),
              )),
        ],
      ),
    );
  }
}
