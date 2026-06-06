import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../widgets/settings_widgets.dart';
import '../../widgets/custom_toggle.dart';
import '../../services/user_data_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UserDataService _userService = UserDataService();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _hobbyController = TextEditingController();

  late String selectedLevel;
  late String showContentFromStart;
  late String showKoreanTranslation;
  late String showKoreanPronunciation;
  late String aiSpeed;
  late Set<String> purposes;
  late Set<String> hobbies;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    setState(() {
      final data = _userService.data;
      selectedLevel = data['level'] ?? "입문";
      aiSpeed = data['aiSpeed'] ?? "현지인 속도로";
      showContentFromStart = data['showContentFromStart'] ?? "예";
      showKoreanTranslation = data['showKoreanTranslation'] ?? "예";
      showKoreanPronunciation = data['showKoreanPronunciation'] ?? "아니오";
      purposes = Set.from(data['purposes']);
      hobbies = Set.from(data['hobbies']);
    });
  }

  Future<void> _saveSettings() async {
    if (purposes.isEmpty || hobbies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("적어도 1개의 목적, 관심사를 가져야 합니다."),
            duration: Duration(seconds: 2)
        ),
      );
      _loadCurrentData(); // 저장이 거부되었으므로 UI 상태 복구
      return;
    }

    final Map<String, dynamic> updatedData = {
      'level': selectedLevel,
      'aiSpeed': aiSpeed,
      'showContentFromStart': showContentFromStart,
      'showKoreanTranslation': showKoreanTranslation,
      'showKoreanPronunciation': showKoreanPronunciation,
      'purposes': purposes,
      'hobbies': hobbies,
    };
    _userService.updateAll(updatedData);

    final token = await AuthService.instance.getIdToken();
    if (token != null) {
      try {
        await ApiService.instance.updateProfile(token, _userService.data);
      } on ApiException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("서버 동기화 실패: ${error.message}")),
          );
        }
        return;
      }
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("설정이 저장되었습니다."),
        duration: Duration(seconds: 2),
      ),
    );
    _loadCurrentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pastelLightgreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "사용자 설정",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 일본어 레벨
              SettingsContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("일본어 레벨", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    _buildLevelDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SettingsTileBase(
                infoMessage: "상황극 중 AI의 음성을 일본어 텍스트로 보여드립니다.",
                child: CustomToggle(
                  title: "상황극 내용을 처음부터 텍스트로 보기",
                  options: const ["예", "아니오"],
                  currentValue: showContentFromStart,
                  onChanged: (val) => setState(() => showContentFromStart = val),
                ),
              ),
              const SizedBox(height: 20),

              SettingsTileBase(
                infoMessage: "상황극 중 AI의 음성을 한국어 번역 텍스트도 보여드립니다.",
                child: CustomToggle(
                  title: "AI의 음성 한국어 번역 표기",
                  options: const ["예", "아니오"],
                  currentValue: showKoreanTranslation,
                  onChanged: (val) => setState(() => showKoreanTranslation = val),
                ),
              ),
              const SizedBox(height: 20),

              SettingsTileBase(
                infoMessage: "상황극 중 AI의 추천 답변을 한글 발음으로 보여드립니다.",
                child: CustomToggle(
                  title: "AI의 추천 답변 한국어 발음 표기",
                  options: const ["예", "아니오"],
                  currentValue: showKoreanPronunciation,
                  onChanged: (val) => setState(() => showKoreanPronunciation = val),
                ),
              ),
              const SizedBox(height: 20),

              SettingsTileBase(
                infoMessage: "상황극 중 AI가 말하는 속도를 고르실 수 있습니다.",
                child: CustomToggle(
                  title: "AI가 말하는 속도",
                  options: const ["천천히", "현지인 속도로"],
                  currentValue: aiSpeed,
                  onChanged: (val) => setState(() => aiSpeed = val),
                ),
              ),

              const SizedBox(height: 40),

              // 인라인 목적 수정 (흰색 영역 안으로 통합)
              SettingsEditableTags(
                title: "일본어를 배우는 목적",
                tags: purposes,
                controller: _purposeController,
                onAdd: () {
                  if (_purposeController.text.trim().isNotEmpty) {
                    setState(() {
                      purposes.add(_purposeController.text.trim());
                      _purposeController.clear();
                    });
                  }
                },
                onDelete: (tag) => setState(() => purposes.remove(tag)),
              ),
              const SizedBox(height: 40),

              SettingsEditableTags(
                title: "관심사와 취미",
                tags: hobbies,
                controller: _hobbyController,
                onAdd: () {
                  if (_hobbyController.text.trim().isNotEmpty) {
                    setState(() {
                      hobbies.add(_hobbyController.text.trim());
                      _hobbyController.clear();
                    });
                  }
                },
                onDelete: (tag) => setState(() => hobbies.remove(tag)),
              ),

              const SizedBox(height: 50),
              
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveSettings,
                  child: const Text("저장", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelDropdown() {
    final Map<String, Color> levelColors = {
      "입문": AppColors.pastelGreen,
      "초급": AppColors.pastelYellow,
      "중급": AppColors.heavyYellow,
      "중상급": AppColors.pinkyRed,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        // 드롭다운 메뉴 테두리를 위해 Theme으로 감쌈
        child: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.white, // 배경색 흰색
          ),
          child: DropdownButton<String>(
            value: selectedLevel,
            borderRadius: BorderRadius.circular(8),
            // 선택된 항목 표시 스타일
            selectedItemBuilder: (BuildContext context) {
              return levelColors.keys.map<Widget>((String value) {
                return Center(
                  child: Text(
                    value,
                    style: TextStyle(color: levelColors[value], fontWeight: FontWeight.bold),
                  ),
                );
              }).toList();
            },
            items: levelColors.keys.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(color: levelColors[value], fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => selectedLevel = newValue);
              }
            },
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
