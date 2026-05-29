class FeedbackNote {
  final String id;
  final DateTime date;
  final String topic;
  final int score;
  final List<FeedbackItem> items;

  FeedbackNote({
    required this.id,
    required this.date,
    required this.topic,
    required this.score,
    required this.items,
  });
}

class FeedbackItem {
  final String title;
  final String japanese;
  final String pronunciation;
  final String translation;
  final String? description; // 긴 텍스트 설명용

  FeedbackItem({
    required this.title,
    required this.japanese,
    required this.pronunciation,
    required this.translation,
    this.description,
  });
}

// 샘플 데이터
List<FeedbackNote> sampleNotes = [
  FeedbackNote(
    id: "1",
    date: DateTime(2026, 4, 9),
    topic: "편의점 오뎅 포장 주문",
    score: 2,
    items: [
      FeedbackItem(
        title: "오뎅 포장 요청",
        japanese: "すみません。\nおでんおねがいします。",
        pronunciation: "스미마셍.\n오뎅 오네가이시마스.",
        translation: "저기요. 오뎅 주세요.",
      ),
      FeedbackItem(
        title: "오뎅 주문",
        japanese: "だいこんふたつ、たまごひとつ、\nもちきんちゃくふたつ\nおねがいします。",
        pronunciation: "다이콘후타츠, 타마고히토츠,\n모치킨챠쿠후타츠\n오네가이시마스.",
        translation: "무 2개, 달걀 1개, 유부떡주머니 2개 주세요.",
      ),
    ],
  ),
  FeedbackNote(
    id: "2",
    date: DateTime(2026, 4, 10),
    topic: "이마다 미오 이야기하기",
    score: 4,
    items: [
      FeedbackItem(
        title: "대답 못한 질문",
        japanese: "ねえ、今田美桜ちゃんが来年の朝ドラのヒロインになったの、知ってる？さっきニュースを見て、びっくりしたよ！",
        pronunciation: "네에, 이마다미오쨩가 라이넨노 아사도라노 히로인니 낫타노, 싯테루? 삿키 뉴-스오미테, 빗쿠리시타요!",
        translation: "있잖아, 이마다 미오가 내년 아침드라마의 여주인공이 된 거 알아? 아까 뉴스를 보고 깜짝 놀랐어!",
      ),
      FeedbackItem(
        title: "AI 추천대로 말한 내용",
        japanese: "うん、ニュースで見たよ。朝ドラのヒロインは本当にすごいね！最近、テレビで美桜ちゃんをよく見るから、本当に人気があると思う。",
        pronunciation: "응, 뉴-스데 미타요. 아사도라마노 히로인와 혼토니 스고이네! 사이킨, 테레비데 미오쨩오 요쿠 미루카라, 혼토-니 닌키가 아루토 오모우.",
        translation: "응, 뉴스에서 봤어. 아침 드라마 여주인공은 정말 대단하네! 요즘 TV에서 미오를 자주 보니까 정말 인기가 있는 것 같아.",
      ),
    ],
  ),
  FeedbackNote(
    id: "3",
    date: DateTime(2026, 4, 15),
    topic: "적절하지 못한 표현 수정",
    score: 3,
    items: [
      FeedbackItem(
        title: "상황에 맞는 태도",
        japanese: "あ、なるほど。確かにシルエットは大事だよね。",
        pronunciation: "아, 나루호도. 타시카니 시루엣토와 다이지다요네.",
        translation: "아, 그렇군요. 확실히 실루엣은 중요하죠.",
        description: "예민한 작업 공간에서는 함께 고민하는 태도가 중요합니다. 상대방의 고민에 바로 대답한다면 상대는 '내 실력이 부족하구나'라고 느낄 수 있습니다. 20대 초 동기 사이라면 조금 더 조심스러운 접근이 필요합니다.",
      ),
    ],
  ),
];
