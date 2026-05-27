import '../state/lang.dart';

/// Lightweight shape returned by `GET /courses` — just enough to render
/// the courses list cards.
class CourseSummary {
  final String id;
  final String title;
  final String subtitle;
  final String icon;          // Material icon name (e.g. "play_arrow")
  final String levelPill;     // "A1·A2", "In Progress", …
  final Lang sourceLang;
  final Lang targetLang;
  final int lessonCount;
  final int lessonsDone;
  final double avgScore;
  // 0..1 fraction; null only when lessonCount is 0.
  final double? progress;
  // The user's last-touched module + lesson on THIS course. Both
  // non-null only on the user's "current" course (the server fills
  // them from the most-recent lesson_status row scoped to that user).
  // The courses-list page uses this to mark exactly one card as the
  // current course; the course-detail page uses it to default the
  // selected module + lesson without waiting on /preference.
  final int? currentModuleId;
  final int? currentLessonId;

  const CourseSummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.levelPill,
    required this.sourceLang,
    required this.targetLang,
    this.lessonCount = 0,
    this.lessonsDone = 0,
    this.avgScore = 0.0,
    this.progress,
    this.currentModuleId,
    this.currentLessonId,
  });

  /// True when the user has activity here but hasn't finished.
  bool get inProgress => lessonsDone > 0 && lessonsDone < lessonCount;

  /// True when this is the user's most recently studied course (the
  /// server picks exactly one across the list).
  bool get isCurrent => currentModuleId != null && currentLessonId != null;

  factory CourseSummary.fromJson(Map<String, dynamic> j) {
    final tags = ((j['tags'] as List?) ?? const []).cast<String>();
    final lessonCount = (j['lesson_count'] as num?)?.toInt() ?? 0;
    final lessonsDone = (j['user_lessons_done'] as num?)?.toInt() ?? 0;
    return CourseSummary(
      id: (j['course_id']).toString(),
      title: (j['title'] as String?) ?? '',
      subtitle: (j['description'] as String?) ?? '',
      icon: 'play_arrow',
      levelPill: tags.isNotEmpty ? tags.first : '',
      // Server: `lang` = language being learned, `to_lang` = student's
      // native language. `sourceLang` is the native/"I speak" side.
      sourceLang: Lang.byCode(j['to_lang'] as String),
      targetLang: Lang.byCode(j['lang'] as String),
      lessonCount: lessonCount,
      lessonsDone: lessonsDone,
      avgScore: (j['avg_score'] as num?)?.toDouble() ?? 0.0,
      // Server returns progress as a 0–100 int; normalise to 0..1 here
      // so the UI's PolyProgressBar can consume it without a divide.
      progress: lessonCount == 0
          ? null
          : ((j['progress'] as num?)?.toDouble() ?? 0.0) / 100.0,
      currentModuleId: j['current_module'] as int?,
      currentLessonId: j['current_lesson'] as int?,
    );
  }
}

/// Shape returned by `GET /api/v1/module/?course_id=…` — one module
/// row in the course screen. `completed` is the server's 0/1 flag.
class Module {
  final int id;
  final String title;
  final String description;
  final List<String> words;
  final bool completed;

  const Module({
    required this.id,
    required this.title,
    required this.description,
    required this.words,
    required this.completed,
  });

  factory Module.fromJson(Map<String, dynamic> j) => Module(
        id: j['module_id'] as int,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        words: ((j['words'] as List?) ?? const []).cast<String>(),
        completed: ((j['completed'] as int?) ?? 0) == 1,
      );
}

/// Server-side per-user state returned by `GET /api/v1/preference/`.
/// Mirrors what gets persisted via the POST endpoint.
class Preference {
  final int userId;
  final int? courseId;
  final int? moduleId;
  final int? lessonId;
  final String? uiLang;
  final String? lang;
  final String? toLang;

  const Preference({
    required this.userId,
    this.courseId,
    this.moduleId,
    this.lessonId,
    this.uiLang,
    this.lang,
    this.toLang,
  });

  factory Preference.fromJson(Map<String, dynamic> j) => Preference(
        userId: j['user_id'] as int,
        courseId: j['course_id'] as int?,
        moduleId: j['module_id'] as int?,
        lessonId: j['lesson_id'] as int?,
        uiLang: j['ui_lang'] as String?,
        lang: j['lang'] as String?,
        toLang: j['to_lang'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'course_id': courseId,
        'module_id': moduleId,
        'lesson_id': lessonId,
        'ui_lang': uiLang,
        'lang': lang,
        'to_lang': toLang,
      };

  Preference copyWith({
    int? courseId,
    int? moduleId,
    int? lessonId,
    String? uiLang,
    String? lang,
    String? toLang,
  }) =>
      Preference(
        userId: userId,
        courseId: courseId ?? this.courseId,
        moduleId: moduleId ?? this.moduleId,
        lessonId: lessonId ?? this.lessonId,
        uiLang: uiLang ?? this.uiLang,
        lang: lang ?? this.lang,
        toLang: toLang ?? this.toLang,
      );
}

/// One choice within an [Exercise]. Exactly one option per exercise
/// is the correct answer (`correct: true` on the server).
class ExerciseOption {
  final String text;
  final bool correct;

  const ExerciseOption({required this.text, this.correct = false});

  factory ExerciseOption.fromJson(Map<String, dynamic> j) => ExerciseOption(
        text: (j['text'] as String?) ?? '',
        correct: (j['correct'] as bool?) ?? false,
      );
}

/// Shape returned by `GET /api/v1/exercise/?lesson_id=…` — one
/// question to display on the quiz screen.
class Exercise {
  final int id;
  final String sentence;
  final String exerciseType;
  final List<ExerciseOption> options;
  final String audio;
  final String word1;
  final String word2;
  final String word3;
  final int? sentenceId;

  const Exercise({
    required this.id,
    required this.sentence,
    required this.exerciseType,
    required this.options,
    required this.audio,
    required this.word1,
    required this.word2,
    required this.word3,
    required this.sentenceId,
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['exercise_id'] as int,
        sentence: (j['sentence'] as String?) ?? '',
        exerciseType: (j['exercise_type'] as String?) ?? '',
        options: ((j['options'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ExerciseOption.fromJson)
            .toList(),
        audio: (j['audio'] as String?) ?? '',
        word1: (j['word1'] as String?) ?? '',
        word2: (j['word2'] as String?) ?? '',
        word3: (j['word3'] as String?) ?? '',
        sentenceId: j['sentence_id'] as int?,
      );
}

/// Write-only payload for `POST /api/v1/user_data/` — one row per
/// answered exercise.
class Results {
  final int userId;
  final String lang;
  final int? courseId;
  final int? moduleId;
  final int? lessonId;
  final int? exerciseId;
  final int? sentenceId;
  final String word1;
  final String word2;
  final String word3;
  final String answerDelayMs;
  final int attempts;
  final bool correct;
  // Fraction of the exercise's correct options the user picked (1 of 2
  // correct → 0.5). Server derives the final mark from this.
  final double correctRatio;
  // How many wrong options the user picked.
  final int incorrectCount;

  const Results({
    required this.userId,
    required this.lang,
    this.courseId,
    this.moduleId,
    this.lessonId,
    this.exerciseId,
    this.sentenceId,
    this.word1 = '',
    this.word2 = '',
    this.word3 = '',
    this.answerDelayMs = '',
    this.attempts = 1,
    this.correct = false,
    this.correctRatio = 0.0,
    this.incorrectCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'lang': lang,
        'course_id': courseId,
        'module_id': moduleId,
        'lesson_id': lessonId,
        'exercise_id': exerciseId,
        'sentence_id': sentenceId,
        'word1': word1,
        'word2': word2,
        'word3': word3,
        'answer_delay_ms': answerDelayMs,
        'attempts': attempts,
        'correct': correct,
        'correct_ratio': correctRatio,
        'incorrect_count': incorrectCount,
      };
}

/// Aggregate per-user mastery counts returned by
/// `GET /api/v1/user_stats/?user_id=…&lang=…`.
class UserStats {
  final int lessons;
  final int words;
  final int sentences;
  final int exercises;

  const UserStats({
    this.lessons = 0,
    this.words = 0,
    this.sentences = 0,
    this.exercises = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        lessons: (j['lessons'] as int?) ?? 0,
        words: (j['words'] as int?) ?? 0,
        sentences: (j['sentences'] as int?) ?? 0,
        exercises: (j['exercises'] as int?) ?? 0,
      );
}

/// Shape returned by `GET /api/v1/lesson/?module_id=…` — one lesson
/// card. `completed` is the server's 0/1 flag (derived from
/// `maxScore > 0`); the score + attempts fields come from the user's
/// own lesson_status aggregate so the UI can surface progress.
class Lesson {
  final int id;
  final String title;
  final String description;
  final List<String> words;
  final bool completed;
  // Best single attempt the user has scored on this lesson, 0 when
  // never attempted. The lesson-row badge surfaces this as "Best".
  final double maxScore;
  // Cumulative score across all attempts. Useful for the
  // achievement threshold (sum >= 1 → "learned" in the server).
  final double sumScore;
  final int numAttempts;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.words,
    required this.completed,
    this.maxScore = 0.0,
    this.sumScore = 0.0,
    this.numAttempts = 0,
  });

  bool get hasAttempted => numAttempts > 0;

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['lesson_id'] as int,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        words: ((j['words'] as List?) ?? const []).cast<String>(),
        completed: ((j['completed'] as int?) ?? 0) == 1,
        maxScore: (j['max_score'] as num?)?.toDouble() ?? 0.0,
        sumScore: (j['sum_score'] as num?)?.toDouble() ?? 0.0,
        numAttempts: (j['num_attempts'] as num?)?.toInt() ?? 0,
      );
}

/// Mirrors the server's `AchievementType` enum. Unknown values from the
/// server map to [AchievementType.unknown] so a new badge type doesn't
/// crash older clients.
enum AchievementType {
  lessonsCompleted('lessons_completed'),
  wordsLearned('words_learned'),
  unknown('');

  final String wire;
  const AchievementType(this.wire);

  static AchievementType fromWire(String? s) {
    for (final t in AchievementType.values) {
      if (t.wire == s) return t;
    }
    return AchievementType.unknown;
  }
}

/// Shape returned by `GET /api/v1/achievement/get_achievements` and the
/// `POST .../check_new_achievements` endpoint. `isNew` is true only on
/// the freshly-awarded entries returned by the check endpoint.
class Achievement {
  final int achievementId;
  final int userId;
  final int courseId;
  final String lang;
  final AchievementType type;
  final int countElements;
  final DateTime? createdAt;
  final bool isNew;

  const Achievement({
    required this.achievementId,
    required this.userId,
    required this.courseId,
    required this.lang,
    required this.type,
    required this.countElements,
    required this.createdAt,
    required this.isNew,
  });

  factory Achievement.fromJson(Map<String, dynamic> j) {
    final created = j['created_at'];
    return Achievement(
      achievementId: (j['achievement_id'] as int?) ?? 0,
      userId: (j['user_id'] as int?) ?? 0,
      courseId: (j['course_id'] as int?) ?? 0,
      lang: (j['lang'] as String?) ?? '',
      type: AchievementType.fromWire(j['achievement_type'] as String?),
      countElements: (j['count_elements'] as int?) ?? 0,
      createdAt: created is String ? DateTime.tryParse(created) : null,
      isNew: (j['is_new'] as bool?) ?? false,
    );
  }
}

/// One row from `GET /api/v1/practice/words`. `score` is the
/// server-side mastery aggregate — higher = better recalled, can be
/// negative for words the user repeatedly gets wrong. `lastPracticed`
/// is null when the server omits the field.
class LearnedWord {
  final String word;
  final DateTime? lastPracticed;
  final double score;

  const LearnedWord({
    required this.word,
    required this.lastPracticed,
    required this.score,
  });

  factory LearnedWord.fromJson(Map<String, dynamic> j) {
    final lp = j['last_practiced'];
    return LearnedWord(
      word: (j['word'] as String?) ?? '',
      lastPracticed: lp is String ? DateTime.tryParse(lp) : null,
      score: (j['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
