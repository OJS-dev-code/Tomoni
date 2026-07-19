import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/scenario_service.dart';
import '../../widgets/scenario_widgets.dart';
import '../../widgets/custom_input_dialog.dart';
import 'scenario_goal_page.dart';

class ScenarioTopicPage extends StatefulWidget {
  const ScenarioTopicPage({super.key});

  @override
  State<ScenarioTopicPage> createState() => _ScenarioTopicPageState();
}

class _ScenarioTopicPageState extends State<ScenarioTopicPage> {
  List<String> recommendations = [];
  final List<String> customTopics = [];
  String? selectedTopic;
  String? customTopic;
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;

  static const _selectedColor = Color(0xFF807019);

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final topics = await ScenarioService.instance.getTopics();
      if (mounted) {
        setState(() {
          recommendations = topics.take(3).toList();
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

  Future<void> _showTopicDialog() async {
    final text = await CustomInputDialog.show(
      context: context,
      title: '직접 주제 입력',
      initialValue: customTopic,
      hintText: '연습하고 싶은 상황을 입력하세요',
    );

    if (text == null) return;

    setState(() {
      if (text.isEmpty) {
        customTopic = null;

        if (selectedTopic != null &&
            customTopics.contains(selectedTopic)) {
          selectedTopic = null;
        }
      } else {
        customTopic = text;

        if (!customTopics.contains(text)) {
          customTopics.add(text);
        }

        selectedTopic = text;
      }
    });
  }

  Widget _buildTopicCard(String topic, {String? prefix}) {
    final isSelected = selectedTopic == topic;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => selectedTopic = topic),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
              color: _selectedColor,
              width: 1.5,
            )
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  prefix != null ? "$prefix $topic" : topic,
                  style: const TextStyle(fontSize: 15),
                ),
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
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "대화 주제 선택",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "AI 친구와 함께 연습하고 싶은\n대화 상황을 골라보세요.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Row(
                  children: const [
                    Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: _selectedColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "AI의 추천 주제",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recommendations.asMap().entries.map(
                      (entry) => _buildTopicCard(
                        entry.value,
                        prefix: "(${entry.key + 1})",
                      ),
                    ),
                const SizedBox(height: 32),
                Row(
                  children: const [
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: _selectedColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "직접 주제 입력하기",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showTopicDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: customTopic != null &&
                          customTopic!.isNotEmpty &&
                          selectedTopic == customTopic
                          ? Border.all(
                        color: _selectedColor,
                        width: 1.5,
                      )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            customTopic == null || customTopic!.isEmpty
                                ? "연습하고 싶은 상황을 입력해보세요"
                                : customTopic!,
                            style: TextStyle(
                              fontSize: 15,
                              color: customTopic == null ||
                                      customTopic!.isEmpty
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                        const Icon(Icons.edit),
                      ],
                    ),
                  ),
                ),
                if (customTopics.length > 1) ...[
                  const SizedBox(height: 12),
                  ...customTopics.where((t) => t != customTopic).map(
                        (topic) => _buildTopicCard(topic),
                      ),
                ],
              ],
            ),
    );
  }
}
