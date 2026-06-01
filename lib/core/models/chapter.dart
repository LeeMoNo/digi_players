class ChapterSummary {
  final String chapterId, requiresChapter;
  final int order;
  final Map<String, String> title, description;
  final int cardCount;
  final bool hasQuiz;
  final String? unlocksGame;

  const ChapterSummary({
    required this.chapterId, required this.order,
    required this.title, required this.description,
    required this.cardCount, required this.hasQuiz,
    this.unlocksGame, this.requiresChapter = '',
  });

  factory ChapterSummary.fromJson(Map<String, dynamic> j) => ChapterSummary(
    chapterId:       j['chapter_id'],
    order:           j['order'],
    title:           Map<String, String>.from(j['title']),
    description:     Map<String, String>.from(j['description']),
    cardCount:       j['card_count'],
    hasQuiz:         j['has_quiz'],
    unlocksGame:     j['unlocks_game'],
    requiresChapter: j['requires_chapter'] ?? '',
  );

  String localTitle(String lang) => title[lang] ?? title['en'] ?? chapterId;
  String localDesc(String lang)  => description[lang] ?? description['en'] ?? '';
}

class CardItem {
  final String cardId, pointsAction;
  final int order;
  final Map<String, String> title, body;

  const CardItem({
    required this.cardId, required this.order,
    required this.title, required this.body,
    required this.pointsAction,
  });

  factory CardItem.fromJson(Map<String, dynamic> j) => CardItem(
    cardId:       j['card_id'],
    order:        j['order'],
    title:        Map<String, String>.from(j['title']),
    body:         Map<String, String>.from(j['body']),
    pointsAction: j['points_action'],
  );

  String localTitle(String lang) => title[lang] ?? title['en'] ?? '';
  String localBody(String lang)  => body[lang]  ?? body['en']  ?? '';
}

class QuizQuestion {
  final String qId;
  final Map<String, String> question;
  final Map<String, List<String>> options;
  final int answer;

  const QuizQuestion({
    required this.qId, required this.question,
    required this.options, required this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
    qId:      j['q_id'],
    question: Map<String, String>.from(j['question']),
    options:  (j['options'] as Map).map(
      (k, v) => MapEntry(k as String, List<String>.from(v)),
    ),
    answer: j['answer'],
  );

  String localQuestion(String lang)    => question[lang] ?? question['en'] ?? '';
  List<String> localOptions(String lang) => options[lang] ?? options['en'] ?? [];
}

class ChapterDetail {
  final String chapterId, quizPointsAction, completionAction;
  final List<CardItem> cards;
  final List<QuizQuestion> quizQuestions;
  final int passScore;

  const ChapterDetail({
    required this.chapterId, required this.cards,
    required this.quizQuestions, required this.passScore,
    required this.quizPointsAction, required this.completionAction,
  });

  factory ChapterDetail.fromJson(Map<String, dynamic> j) {
    final quiz = Map<String, dynamic>.from(j['quiz'] as Map);
    return ChapterDetail(
      chapterId:         j['chapter_id'],
      cards:             (j['cards'] as List)
          .map((c) => CardItem.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList(),
      quizQuestions:     (quiz['questions'] as List)
          .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
          .toList(),
      passScore:         quiz['pass_score'],
      quizPointsAction:  quiz['points_action'],
      completionAction:  quiz['completion_action'],
    );
  }
}