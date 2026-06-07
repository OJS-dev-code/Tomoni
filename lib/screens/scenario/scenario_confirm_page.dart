import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/scenario_service.dart';
import '../../widgets/custom_toggle.dart';
import '../../widgets/scenario_widgets.dart';
import 'scenario_chat_page.dart';

class ScenarioConfirmPage extends StatefulWidget {
  final String topic;
  final List<String> goals;

  const ScenarioConfirmPage({
    super.key,
    required this.topic,
    required this.goals,
  });

  @override
  State<ScenarioConfirmPage> createState() => _ScenarioConfirmPageState();
}

class _ScenarioConfirmPageState extends State<ScenarioConfirmPage> {
  bool _isStarting = false;
  bool _isLoadingPreview = true;
  String _aiRole = '';
  String _userRole = '';
  String _location = '';
  String _aiGender = 'female';

  static const _genderLabels = {'female': '여성', 'male': '남성'};
  static const _voiceLabels = {'female': 'shimmer', 'male': 'onyx'};
  static const _selectedColor = Color(0xFF807019);

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  String get _genderLabel => _genderLabels[_aiGender] ?? '여성';

  String get _voiceLabel => _voiceLabels[_aiGender] ?? 'shimmer';

  Future<void> _loadPreview() async {
    try {
      final preview = await ScenarioService.instance.getSessionPreview(
        topic: widget.topic,
        goals: widget.goals,
      );
      if (!mounted) return;
      setState(() {
        _aiRole = preview['aiRole'] as String? ?? '';
        _userRole = preview['userRole'] as String? ?? '';
        _location = preview['location'] as String? ?? '';
        _aiGender = preview['suggestedAiGender'] as String? ?? 'female';
        _isLoadingPreview = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  void _onGenderChanged(String label) {
    setState(() {
      _aiGender = label == '남성' ? 'male' : 'female';
    });
  }

  Future<void> _startSession() async {
    setState(() => _isStarting = true);
    try {
      final session = await ScenarioService.instance.startSession(
        topic: widget.topic,
        goals: widget.goals,
        aiGender: _aiGender,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScenarioChatPage(session: session),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Widget _buildSettingRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF7F4E8),
            child: Icon(icon, color: _selectedColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScenarioPageLayout(
      title: "",
      confirmText: _isStarting ? '준비 중...' : '대화 시작하기',
      onConfirm: (_isStarting || _isLoadingPreview) ? null : _startSession,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📁 선택한 대화 주제",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8CF6B)),
            ),
            child: Text(
              widget.topic,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "🎯 대화 목표",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...widget.goals.asMap().entries.map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFFE8CF6B),
                        child: Text(
                          "${entry.key + 1}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 28),
          const Text(
            "✨ AI 추천 설정",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_isLoadingPreview)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    Icons.smart_toy_outlined,
                    "AI 역할",
                    _aiRole,
                  ),
                  const Divider(),
                  _buildSettingRow(
                    Icons.person_outline,
                    "나의 역할",
                    _userRole,
                  ),
                  const Divider(),
                  _buildSettingRow(
                    Icons.location_on_outlined,
                    "대화 장소",
                    _location,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomToggle(
                title: 'AI 역할 성별',
                subtitle:
                    '선택한 성별에 맞는 AI 음성($_genderLabel · $_voiceLabel)이 사용됩니다.',
                options: const ['여성', '남성'],
                currentValue: _genderLabel,
                onChanged: _onGenderChanged,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7D6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: _selectedColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text("준비 완료!\n설정한 내용으로 대화를 시작할게요."),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
