import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../widgets/scenario_widgets.dart';
import 'scenario_chat_page.dart';

class ScenarioConfirmPage extends StatelessWidget {
  final String topic;
  final List<String> goals;

  const ScenarioConfirmPage({
    super.key,
    required this.topic,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    return ScenarioPageLayout(
      title: topic,
      confirmText: "시작하기",
      onConfirm: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScenarioChatPage(topic: topic),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScenarioSectionTitle(title: "대화 목표"),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: goals.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text("(${entry.key + 1}) ${entry.value}", 
                    style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          
          // 프리셋 이미지를 사용할 수 있도록 구성된 역할 박스들
          _buildRoleBox(
            "AI 역할 :", 
            "선생님", 
            null, // 'assets/images/characters/ai_teacher.png' 형식으로 대체 가능
            Icons.person_outline
          ),
          _buildRoleBox(
            "당신의 역할 :", 
            "학생", 
            null, // 'assets/images/characters/user_student.png' 형식으로 대체 가능
            Icons.face_outlined
          ),
          _buildRoleBox(
            "대화 장소 :", 
            "교실", 
            null, // 'assets/images/backgrounds/classroom.png' 형식으로 대체 가능
            Icons.location_on_outlined
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBox(String label, String value, String? imagePath, IconData fallbackIcon) {
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
              image: imagePath != null 
                ? DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover)
                : null,
            ),
            child: imagePath == null 
              ? Icon(fallbackIcon, color: Colors.black54) 
              : null,
          ),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}
