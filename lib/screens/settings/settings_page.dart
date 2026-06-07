import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_data_service.dart';
import '../../widgets/settings_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UserDataService _userService = UserDataService();

  late String selectedLevel;
  late String showContentFromStart;
  late String showKoreanTranslation;
  late String showKoreanPronunciation;
  late String speakSlowly;
  late Set<String> purposes;
  late Set<String> hobbies;
  List<String> customPurposes = [];
  List<String> customHobbies = [];

  static const _defaultPurposes = [
    "취미/자기계발",
    "여행",
    "현지생활",
    "취업/비즈니스",
    "시험/자격증(JLPT 등)",
    "덕질(애니/드라마)",
  ];

  static const _defaultHobbies = [
    "여행",
    "음악",
    "영화",
    "게임",
    "요리",
    "운동",
    "독서",
    "만화/애니",
    "기술",
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    setState(() {
      final data = _userService.data;
      selectedLevel = data['level'] ?? "입문";
      final aiSpeed = (data['aiSpeed'] as String? ?? "현지인 속도로");
      speakSlowly = aiSpeed.contains("천천히") ? "예" : "아니오";
      showContentFromStart = data['showContentFromStart'] ?? "예";
      showKoreanTranslation = data['showKoreanTranslation'] ?? "예";
      showKoreanPronunciation = data['showKoreanPronunciation'] ?? "아니오";
      purposes = Set<String>.from(data['purposes'] ?? {});
      hobbies = Set<String>.from(data['hobbies'] ?? {});

      customPurposes = purposes
          .where((item) => !_defaultPurposes.contains(item))
          .toList();
      customHobbies =
          hobbies.where((item) => !_defaultHobbies.contains(item)).toList();
    });
  }

  Future<void> _saveSettings() async {
    if (purposes.isEmpty || hobbies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("적어도 1개의 목적, 관심사를 가져야 합니다."),
            duration: Duration(seconds: 2),
          ),
        );
      }
      _loadCurrentData();
      return;
    }

    final updatedData = {
      'level': selectedLevel,
      'aiSpeed': speakSlowly == "예" ? "천천히" : "현지인 속도로",
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
        _loadCurrentData();
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("설정이 저장되었습니다."),
          duration: Duration(seconds: 2),
        ),
      );
    }
    _loadCurrentData();
  }

  void _showLevelDialog() {
    const levels = ["입문", "초급", "중급", "중상급"];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "일본어 레벨",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...levels.map(
                  (level) => ListTile(
                    title: Text(level),
                    trailing: selectedLevel == level
                        ? const Icon(Icons.check, color: Color(0xFF807019))
                        : null,
                    onTap: () {
                      setState(() => selectedLevel = level);
                      _saveSettings();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPurposeDialog() {
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "일본어 학습 목적",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        ..._defaultPurposes.map((option) {
                          final isSelected = purposes.contains(option);
                          return _buildPurposeChip(
                            option,
                            isSelected,
                            () {
                              modalSetState(() {
                                if (isSelected) {
                                  purposes.remove(option);
                                } else {
                                  purposes.add(option);
                                }
                              });
                              setState(() {});
                            },
                          );
                        }),
                        ...customPurposes.map((option) {
                          final isSelected = purposes.contains(option);
                          return _buildCustomPurposeChip(
                            option,
                            isSelected,
                            () {
                              modalSetState(() {
                                if (isSelected) {
                                  purposes.remove(option);
                                } else {
                                  purposes.add(option);
                                }
                              });
                              setState(() {});
                            },
                            () {
                              modalSetState(() {
                                customPurposes.remove(option);
                                purposes.remove(option);
                              });
                              setState(() {});
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customController,
                            decoration: InputDecoration(
                              hintText: "직접 입력",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final text = customController.text.trim();
                            if (text.isEmpty) return;
                            modalSetState(() {
                              if (!_defaultPurposes.contains(text) &&
                                  !customPurposes.contains(text)) {
                                customPurposes.add(text);
                              }
                              purposes.add(text);
                            });
                            setState(() {});
                            customController.clear();
                          },
                          child: const Text("추가"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveSettings();
                          Navigator.pop(context);
                        },
                        child: const Text("완료"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHobbyDialog() {
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "취미 및 관심사",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        ..._defaultHobbies.map((option) {
                          final isSelected = hobbies.contains(option);
                          return _buildPurposeChip(
                            option,
                            isSelected,
                            () {
                              modalSetState(() {
                                if (isSelected) {
                                  hobbies.remove(option);
                                } else {
                                  hobbies.add(option);
                                }
                              });
                              setState(() {});
                            },
                          );
                        }),
                        ...customHobbies.map((option) {
                          final isSelected = hobbies.contains(option);
                          return _buildCustomPurposeChip(
                            option,
                            isSelected,
                            () {
                              modalSetState(() {
                                if (isSelected) {
                                  hobbies.remove(option);
                                } else {
                                  hobbies.add(option);
                                }
                              });
                              setState(() {});
                            },
                            () {
                              modalSetState(() {
                                customHobbies.remove(option);
                                hobbies.remove(option);
                              });
                              setState(() {});
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customController,
                            decoration: InputDecoration(
                              hintText: "직접 입력",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final text = customController.text.trim();
                            if (text.isEmpty) return;
                            modalSetState(() {
                              if (!_defaultHobbies.contains(text) &&
                                  !customHobbies.contains(text)) {
                                customHobbies.add(text);
                              }
                              hobbies.add(text);
                            });
                            setState(() {});
                            customController.clear();
                          },
                          child: const Text("추가"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveSettings();
                          Navigator.pop(context);
                        },
                        child: const Text("완료"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPurposeChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGrey1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPurposeChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    VoidCallback onDelete,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 8,
          top: 10,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGrey1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                size: 18,
                color: isSelected ? Colors.white : AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioRow(
    IconData icon,
    String title,
    String? infoMessage,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SettingsTileBase(
      infoMessage: infoMessage,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF807019), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: value,
              activeColor: const Color(0xFFE7C95F),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "설정",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF807019),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "학습 프로필",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SettingsContainer(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.school_outlined),
                      title: const Text("일본어 레벨"),
                      subtitle: Text(selectedLevel),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showLevelDialog,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: const Text("일본어 학습 목적"),
                      subtitle: Text(
                        purposes.isEmpty ? "설정 안됨" : purposes.join(", "),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showPurposeDialog,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.favorite_border),
                      title: const Text("취미 및 관심사"),
                      subtitle: Text(
                        hobbies.isEmpty ? "설정 안됨" : hobbies.join(", "),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showHobbyDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "음성 및 자막",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAudioRow(
                Icons.record_voice_over_outlined,
                "천천히 말하기",
                "상황극 중 AI가 말하는 속도를 느리게 재생합니다.",
                speakSlowly == "예",
                (value) {
                  setState(() => speakSlowly = value ? "예" : "아니오");
                  _saveSettings();
                },
              ),
              const SizedBox(height: 12),
              _buildAudioRow(
                Icons.subtitles_outlined,
                "일본어 자막",
                "상황극 중 AI의 음성을 일본어 텍스트로 보여드립니다.",
                showContentFromStart == "예",
                (value) {
                  setState(
                    () => showContentFromStart = value ? "예" : "아니오",
                  );
                  _saveSettings();
                },
              ),
              const SizedBox(height: 12),
              _buildAudioRow(
                Icons.translate_outlined,
                "한국어 번역",
                "상황극 중 AI의 음성을 한국어 번역 텍스트도 보여드립니다.",
                showKoreanTranslation == "예",
                (value) {
                  setState(
                    () => showKoreanTranslation = value ? "예" : "아니오",
                  );
                  _saveSettings();
                },
              ),
              const SizedBox(height: 12),
              _buildAudioRow(
                Icons.volume_up_outlined,
                "한국어 발음",
                "상황극 중 AI의 추천 답변을 한글 발음으로 보여드립니다.",
                showKoreanPronunciation == "예",
                (value) {
                  setState(
                    () => showKoreanPronunciation = value ? "예" : "아니오",
                  );
                  _saveSettings();
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
