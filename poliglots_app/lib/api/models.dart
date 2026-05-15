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
  final bool inProgress;
  final double? progress;     // 0..1, only when inProgress
  final String? footer;       // free-form footer text

  const CourseSummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.levelPill,
    required this.sourceLang,
    required this.targetLang,
    this.inProgress = false,
    this.progress,
    this.footer,
  });

  factory CourseSummary.fromJson(Map<String, dynamic> j) {
    final progress = j['user_course_progress'] as Map<String, dynamic>?;
    final progressValue = (progress?['progress'] as num?)?.toDouble();
    final tags = ((j['tags'] as List?) ?? const []).cast<String>();
    return CourseSummary(
      id: (j['course_id']).toString(),
      title: (j['title'] as String?) ?? '',
      subtitle: (j['description'] as String?) ?? '',
      icon: 'play_arrow',
      levelPill: tags.isNotEmpty ? tags.first : '',
      sourceLang: Lang.byCode(j['lang'] as String),
      targetLang: Lang.byCode(j['to_lang'] as String),
      inProgress: progressValue != null && progressValue > 0 && progressValue < 1,
      progress: progressValue,
      footer: progressValue != null
          ? '${(progressValue * 100).round()}% complete'
          : null,
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

  const Exercise({
    required this.id,
    required this.sentence,
    required this.exerciseType,
    required this.options,
    required this.audio,
    required this.word1,
    required this.word2,
    required this.word3,
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
      );
}

/// Shape returned by `GET /api/v1/lesson/?module_id=…` — one lesson
/// card. `completed` is the server's 0/1 flag.
class Lesson {
  final int id;
  final String title;
  final String description;
  final List<String> words;
  final bool completed;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.words,
    required this.completed,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['lesson_id'] as int,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        words: ((j['words'] as List?) ?? const []).cast<String>(),
        completed: ((j['completed'] as int?) ?? 0) == 1,
      );
}
