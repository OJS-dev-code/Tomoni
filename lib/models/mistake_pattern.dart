class MistakePattern {
  final String id;
  final String category;
  final String label;
  final String description;
  final String userExample;
  final String betterJapanese;
  final String betterPronunciation;
  final String betterTranslation;
  final int count;
  final String lastTopic;

  MistakePattern({
    required this.id,
    required this.category,
    required this.label,
    required this.description,
    required this.userExample,
    required this.betterJapanese,
    required this.betterPronunciation,
    required this.betterTranslation,
    required this.count,
    required this.lastTopic,
  });

  factory MistakePattern.fromJson(Map<String, dynamic> json) {
    return MistakePattern(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '표현',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
      userExample: json['userExample'] as String? ?? '',
      betterJapanese: json['betterJapanese'] as String? ?? '',
      betterPronunciation: json['betterPronunciation'] as String? ?? '',
      betterTranslation: json['betterTranslation'] as String? ?? '',
      count: json['count'] as int? ?? 1,
      lastTopic: json['lastTopic'] as String? ?? '',
    );
  }
}
