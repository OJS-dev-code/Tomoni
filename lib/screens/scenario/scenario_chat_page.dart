import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_constants.dart';
import '../../widgets/chat_bubble.dart';
import '../../services/user_data_service.dart';

class ScenarioChatPage extends StatefulWidget {
  final String topic;

  const ScenarioChatPage({super.key, required this.topic});

  @override
  State<ScenarioChatPage> createState() => _ScenarioChatPageState();
}

class _ScenarioChatPageState extends State<ScenarioChatPage> {
  final UserDataService _userService = UserDataService();
  bool isRecording = false;

  final List<Map<String, dynamic>> _messages = [
    {
      "isAI": true,
      "text": "いらっしゃいませ。",
      "pronunciation": "이랏샤이마세.",
      "translation": "어서오세요.",
    },
    {
      "isAI": false,
      "isRecommended": false,
      "text": "すみません。\nおでんおねがいします。",
      "pronunciation": "스미마셍.\n오뎅 오네가이시마스.",
      "translation": "저기요. 오뎅 주세요.",
    },
    {
      "isAI": true,
      "text": "どれにしますか。",
      "pronunciation": "도레니 시마스카.",
      "translation": "어느 걸로 하시겠습니까?",
    },
    {
      "isAI": false,
      "isRecommended": true,
      "text": "だいこんふたつ、たまごひとつ、\nもちきんちゃくふたつ\nおねがいします。",
      "pronunciation": "다이콘후타츠, 타마고히토츠,\n모치킨챠쿠후타츠\n오네가이시마스.",
      "translation": "무 2개, 달걀 1개, 유부떡주머니 2개 주세요.",
    },
    {
      "isAI": true,
      "text": "はい、だいこんふたつとたまごひとつ、\nもちきんちゃくふたつですね。ほかに何か？",
      "pronunciation": "하이, 다이콘후타츠토 타마고히토츠, 모치킨챠쿠후타츠데스네. 호카니 나니카?",
      "translation": "네, 무 2개랑 달걀 1개, 유부떡주머니 2개군요. 그 외에 더 필요한 것 있으신가요?",
    },
    {
      "isAI": false,
      "isRecommended": false,
      "text": "だいじょうぶです。\nはしとスプーンもらえますか?",
      "pronunciation": "다이죠부데스. 하시토 스푸-음 모라에마스카?",
      "translation": "괜찮습니다. 젓가락이랑 숟가락 받을 수 있을까요?",
    },
    {
      "isAI": true,
      "text": "はい、わかりました。\nふくろはいりますか。",
      "pronunciation": "하이, 와카리마시타. 후쿠로와 이리마스카?",
      "translation": "네, 알겠습니다. 봉투 필요하신가요?",
    },
    {
      "isAI": false,
      "isRecommended": true,
      "text": "はい、おねがいします。",
      "pronunciation": "하이, 오네가이시마스.",
      "translation": "네, 부탁드립니다.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final settings = _userService.data;
    
    // 사용자 설정 매핑
    bool showJapaneseInitially = settings['showContentFromStart'] == "예";
    bool showTranslationInitially = settings['showKoreanTranslation'] == "예";
    String aiSpeed = settings['aiSpeed'] ?? "현지인 속도로";

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/convenience_store.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.15)),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopButton("취소", () => Navigator.pop(context)),
                      _buildTopButton("대화종료", () {
                        Navigator.popUntil(context, ModalRoute.withName('/main'));
                      }),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ChatBubble(
                        text: msg['text'],
                        pronunciation: msg['pronunciation'],
                        translation: msg['translation'],
                        isAI: msg['isAI'],
                        isRecommended: msg['isRecommended'] ?? false,
                        showJapaneseInitially: showJapaneseInitially,
                        showTranslationInitially: showTranslationInitially,
                        aiSpeedSetting: aiSpeed,
                      );
                    },
                  ),
                ),

                // 하단 마이크 버튼
                Container(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  width: double.infinity,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isRecording = !isRecording;
                        });
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 8),
                          ],
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            isRecording ? AppIcons.micRed : AppIcons.micBlue,
                            width: 50,
                            height: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton(String label, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
