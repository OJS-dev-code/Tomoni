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

  @override
  Widget build(BuildContext context) {
    return ScenarioPageLayout(
      title: widget.topic,
      confirmText: _isStarting ? '준비 중...' : '시작하기',
      onConfirm: (_isStarting || _isLoadingPreview) ? null : _startSession,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScenarioSectionTitle(title: '대화 주제'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Text(
              widget.topic,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          const ScenarioSectionTitle(title: '대화 목표'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.goals.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '(${entry.key + 1}) ${entry.value}',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoadingPreview)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildInfoBox('AI 역할', _aiRole, Icons.person_outline),
            _buildInfoBox('당신의 역할', _userRole, Icons.face_outlined),
            _buildInfoBox('대화 장소', _location, Icons.location_on_outlined),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomToggle(
                title: 'AI 역할 성별',
                subtitle: '선택한 성별에 맞는 AI 음성($_genderLabel · $_voiceLabel)이 사용됩니다.',
                options: const ['여성', '남성'],
                currentValue: _genderLabel,
                onChanged: _onGenderChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
            child: Icon(icon, color: Colors.black54),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
