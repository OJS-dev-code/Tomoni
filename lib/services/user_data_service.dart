class UserDataService {
  // 싱글톤 패턴 구현
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  // 기본값 설정
  Map<String, dynamic> data = {
    'gender': '',
    'birthDate': '',
    'level': '입문',
    'duration': '',
    'purposes': <String>{},
    'hobbies': <String>{},
    'aiSpeed': '현지인 속도로',
    'showContentFromStart': '예',
    'showKoreanTranslation': '예',
    'showKoreanPronunciation': '아니오',
  };

  void updateAll(Map<String, dynamic> newData) {
    data.addAll(newData);
  }

  void updateSingle(String key, dynamic value) {
    data[key] = value;
  }
}
