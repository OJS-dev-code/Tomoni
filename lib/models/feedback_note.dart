class FeedbackNote {
  final String id;
  final String sessionId;
  final DateTime date;
  final String topic;
  final int score;
  final List<FeedbackItem> items;
  final List<HintResponseItem> hintResponses;

  FeedbackNote({
    required this.id,
    required this.sessionId,
    required this.date,
    required this.topic,
    required this.score,
    required this.items,
    this.hintResponses = const [],
  });

  factory FeedbackNote.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as String? ?? '';
    return FeedbackNote(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      date: DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now(),
      topic: json['topic'] as String? ?? '',
      score: json['score'] as int? ?? 3,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => FeedbackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      hintResponses: (json['hintResponses'] as List<dynamic>? ?? [])
          .map((item) => HintResponseItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeedbackItem {
  final String title;
  final String japanese;
  final String pronunciation;
  final String translation;
  final String? description;

  FeedbackItem({
    required this.title,
    required this.japanese,
    required this.pronunciation,
    required this.translation,
    this.description,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    final description = json['description'] as String?;
    return FeedbackItem(
      title: json['title'] as String? ?? '',
      japanese: json['japanese'] as String? ?? '',
      pronunciation: json['pronunciation'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      description: description != null && description.trim().isEmpty
          ? null
          : description,
    );
  }
}

class HintResponseItem {
  final String userText;
  final String hintText;
  final String hintPronunciation;
  final String hintTranslation;

  HintResponseItem({
    required this.userText,
    required this.hintText,
    this.hintPronunciation = '',
    this.hintTranslation = '',
  });

  factory HintResponseItem.fromJson(Map<String, dynamic> json) {
    return HintResponseItem(
      userText: json['userText'] as String? ?? '',
      hintText: json['hintText'] as String? ?? '',
      hintPronunciation: json['hintPronunciation'] as String? ?? '',
      hintTranslation: json['hintTranslation'] as String? ?? '',
    );
  }
}
