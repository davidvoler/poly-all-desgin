import 'dart:convert';

import '../state/lang.dart';

/// One reading / sentence-alternative variant a course declares in its
/// `metadata`: a display [name], an optional material-icon name, an optional
/// [tooltip], and (for sentence-alt variants) the alt [slot] it labels.
class VariantDescriptor {
  final String name;
  final String? icon;
  final String? tooltip;
  final int? slot;
  const VariantDescriptor({
    required this.name,
    this.icon,
    this.tooltip,
    this.slot,
  });

  factory VariantDescriptor.fromJson(Map<String, dynamic> j) =>
      VariantDescriptor(
        name: (j['name'] as String?) ?? '',
        icon: j['icon'] as String?,
        tooltip: j['tooltip_text'] as String?,
        slot: (j['slot'] as num?)?.toInt(),
      );
}

/// Course-level display metadata: which reading (`ruby_text`) and full-
/// sentence (`sentence_alt`) variants the course offers and how to label
/// them in the quiz. Empty when the course declares none — the UI then falls
/// back to its built-in per-language labels.
class CourseMeta {
  final List<VariantDescriptor> rubyText;
  final List<VariantDescriptor> sentenceAlt;
  const CourseMeta({this.rubyText = const [], this.sentenceAlt = const []});

  static const empty = CourseMeta();

  bool get isEmpty => rubyText.isEmpty && sentenceAlt.isEmpty;

  /// The sentence-alt descriptor that labels [slot] (1/2/3), or null.
  VariantDescriptor? altForSlot(int slot) {
    for (final d in sentenceAlt) {
      if (d.slot == slot) return d;
    }
    return null;
  }

  /// The ruby descriptor matching [key] (e.g. 'hiragana') or display [label]
  /// (e.g. 'Romaji'), case-insensitive. Lets a [RubyMode] resolve its label /
  /// tooltip from the course metadata regardless of naming convention.
  VariantDescriptor? rubyFor({required String key, required String label}) {
    final k = key.toLowerCase();
    final l = label.toLowerCase();
    for (final d in rubyText) {
      final n = d.name.toLowerCase();
      if (n == k || n == l) return d;
    }
    // 'romanji' (content spelling) vs 'romaji' (label) — accept either.
    if (k == 'romanji' || l == 'romaji') {
      for (final d in rubyText) {
        final n = d.name.toLowerCase();
        if (n == 'romaji' || n == 'romanji') return d;
      }
    }
    return null;
  }

  factory CourseMeta.fromJson(Object? raw) {
    Map? map;
    if (raw is Map) {
      map = raw;
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) map = decoded;
      } catch (_) {}
    }
    if (map == null) return CourseMeta.empty;
    List<VariantDescriptor> parse(Object? v) => v is List
        ? v
            .whereType<Map>()
            .map((m) => VariantDescriptor.fromJson(m.cast<String, dynamic>()))
            .where((d) => d.name.isNotEmpty)
            .toList()
        : const [];
    return CourseMeta(
      rubyText: parse(map['ruby_text']),
      sentenceAlt: parse(map['sentence_alt']),
    );
  }
}

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
  // The user's last-touched module + lesson on THIS course. Non-null
  // on every course the user has any lesson_status row for — the
  // course-detail page uses this to anchor the modules strip + the
  // "current lesson" highlight without waiting on /preference.
  final int? currentModuleId;
  final int? currentLessonId;
  // True for exactly the user's globally most-recent course; drives
  // the "CURRENT" pill on the courses list. Independent of the
  // per-course cursor above so the detail page can still resume any
  // touched course.
  final bool isCurrentCourse;
  // Course-level display metadata (reading / sentence-alt variant
  // descriptors). Empty when the course declares none.
  final CourseMeta meta;

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
    this.isCurrentCourse = false,
    this.meta = CourseMeta.empty,
  });

  /// True when the user has activity here but hasn't finished.
  bool get inProgress => lessonsDone > 0 && lessonsDone < lessonCount;

  /// True when this is the user's most recently studied course (the
  /// server picks exactly one across the list).
  bool get isCurrent => isCurrentCourse;

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
      isCurrentCourse: (j['is_current_course'] as bool?) ?? false,
      meta: CourseMeta.fromJson(j['metadata']),
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
  final String? courseName;
  final String? moduleName;
  final String? lessonName;
  // Free-form quiz display preferences (text size, text-alternative, ruby
  // mode, annotations…). Shape owned by QuizSettings; null when unset.
  final Map<String, dynamic>? quizSettings;

  const Preference({
    required this.userId,
    this.courseId,
    this.moduleId,
    this.lessonId,
    this.uiLang,
    this.lang,
    this.toLang,
    this.courseName,
    this.moduleName,
    this.lessonName,
    this.quizSettings,
  });

  factory Preference.fromJson(Map<String, dynamic> j) => Preference(
        userId: j['user_id'] as int,
        courseId: j['course_id'] as int?,
        moduleId: j['module_id'] as int?,
        lessonId: j['lesson_id'] as int?,
        uiLang: j['ui_lang'] as String?,
        lang: j['lang'] as String?,
        toLang: j['to_lang'] as String?,
        courseName: j['course_name'] as String?,
        moduleName: j['module_name'] as String?,
        lessonName: j['lesson_name'] as String?,
        quizSettings: (j['quiz_settings'] as Map?)?.cast<String, dynamic>(),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'course_id': courseId,
        'module_id': moduleId,
        'lesson_id': lessonId,
        'ui_lang': uiLang,
        'lang': lang,
        'to_lang': toLang,
        'course_name': courseName,
        'module_name': moduleName,
        'lesson_name': lessonName,
        'quiz_settings': quizSettings,
      };

  Preference copyWith({
    int? courseId,
    int? moduleId,
    int? lessonId,
    String? uiLang,
    String? lang,
    String? toLang,
    String? courseName,
    String? moduleName,
    String? lessonName,
    Map<String, dynamic>? quizSettings,
  }) =>
      Preference(
        userId: userId,
        courseId: courseId ?? this.courseId,
        moduleId: moduleId ?? this.moduleId,
        lessonId: lessonId ?? this.lessonId,
        uiLang: uiLang ?? this.uiLang,
        lang: lang ?? this.lang,
        toLang: toLang ?? this.toLang,
        courseName: courseName ?? this.courseName,
        moduleName: moduleName ?? this.moduleName,
        lessonName: lessonName ?? this.lessonName,
        quizSettings: quizSettings ?? this.quizSettings,
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

/// One token of an exercise's `ruby_text` — a base run plus an optional
/// reading ("ruby"/furigana) above it. The server's `ruby_text` is a sparse
/// list: only the runs that carry a reading are present, so the tokens do
/// NOT reconstruct the whole sentence on their own (see
/// `buildSentenceTokens` in the quiz, which re-aligns them).
class RubyToken {
  final String text;
  final String? ruby;
  const RubyToken({required this.text, this.ruby});

  bool get hasRuby => ruby != null && ruby!.isNotEmpty;

  factory RubyToken.fromJson(Map<String, dynamic> j) => RubyToken(
        text: (j['text'] as String?) ?? '',
        ruby: (j['ruby'] as String?),
      );
}

/// One per-word translation from an exercise's `annotations`: the [word] is
/// a substring of the sentence; [translation] is in the user's native
/// language.
class WordAnnotation {
  final String word;
  final String translation;
  const WordAnnotation({required this.word, required this.translation});

  factory WordAnnotation.fromJson(Map<String, dynamic> j) => WordAnnotation(
        word: (j['word'] as String?) ?? '',
        translation: (j['translation'] as String?) ?? '',
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
  // Alternative renderings of [sentence]. Meaning is a per-language content
  // convention — Japanese: alt1=hiragana, alt2=romaji, alt3=katakana;
  // Arabic: alt1=diacritized, alt2=transliteration. Empty when the content
  // didn't supply that variant. Powers the quiz "text alternative" toggle.
  final String sentenceAlt1;
  final String sentenceAlt2;
  final String sentenceAlt3;
  // Per-token furigana keyed by reading system ('hiragana' | 'katakana' |
  // 'romanji'). Empty when the content didn't supply ruby. Sparse: only the
  // runs that carry a reading are present (see [RubyToken]).
  final Map<String, List<RubyToken>> rubyText;
  // Per-word translations for the sentence's key words. Empty when none.
  final List<WordAnnotation> annotations;

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
    this.sentenceAlt1 = '',
    this.sentenceAlt2 = '',
    this.sentenceAlt3 = '',
    this.rubyText = const {},
    this.annotations = const [],
  });

  /// Furigana tokens for a reading system ('hiragana'/'katakana'/'romanji'),
  /// or empty when this exercise has none for that system.
  List<RubyToken> rubyTokens(String key) => rubyText[key] ?? const [];

  /// True when this exercise carries furigana for at least one reading system.
  bool get hasRubyText => rubyText.values.any((t) => t.isNotEmpty);

  /// True when this exercise carries any per-word annotation.
  bool get hasAnnotations => annotations.isNotEmpty;

  /// The non-empty alternatives in slot order (alt1, alt2, alt3) — used to
  /// gate the text-alternative control: only shown when this is non-empty.
  List<String> get alternatives =>
      [sentenceAlt1, sentenceAlt2, sentenceAlt3].where((a) => a.isNotEmpty).toList();

  bool get hasAlternatives => alternatives.isNotEmpty;

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
        sentenceAlt1: (j['sentence_alt1'] as String?) ?? '',
        sentenceAlt2: (j['sentence_alt2'] as String?) ?? '',
        sentenceAlt3: (j['sentence_alt3'] as String?) ?? '',
        rubyText: _parseRubyText(j['ruby_text']),
        annotations: _parseAnnotations(j['annotations']),
      );

  /// Parse the server's `ruby_text` into per-system token lists. Defensive
  /// against the historical jsonb inconsistencies (object / null / a
  /// double-encoded JSON string) — anything unexpected yields an empty map.
  static Map<String, List<RubyToken>> _parseRubyText(Object? raw) {
    final map = _asMap(raw);
    if (map == null) return const {};
    final out = <String, List<RubyToken>>{};
    map.forEach((key, value) {
      if (value is List) {
        out[key] = value
            .whereType<Map>()
            .map((m) => RubyToken.fromJson(m.cast<String, dynamic>()))
            .toList();
      }
    });
    return out;
  }

  /// Parse the server's `annotations` into a list of per-word translations.
  /// Defensive against array / null / double-encoded-string jsonb shapes.
  static List<WordAnnotation> _parseAnnotations(Object? raw) {
    final list = _asList(raw);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((m) => WordAnnotation.fromJson(m.cast<String, dynamic>()))
        .where((a) => a.word.isNotEmpty)
        .toList();
  }

  static Map? _asMap(Object? raw) {
    if (raw is Map) return raw;
    if (raw is String && raw.isNotEmpty) {
      final decoded = _tryDecode(raw);
      if (decoded is Map) return decoded;
    }
    return null;
  }

  static List? _asList(Object? raw) {
    if (raw is List) return raw;
    if (raw is String && raw.isNotEmpty) {
      final decoded = _tryDecode(raw);
      if (decoded is List) return decoded;
    }
    return null;
  }

  static Object? _tryDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }
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
