import '../state/lang.dart';

/// State of a module within a course.
enum ModuleState {
  done,
  selected,    // in-progress / current
  locked;

  static ModuleState fromString(String s) =>
      values.firstWhere((e) => e.name == s, orElse: () => ModuleState.locked);
}

/// One lesson within a module.
class Lesson {
  final String id;
  final String native;
  final String translation;
  final bool done;
  final bool selected;

  const Lesson({
    required this.id,
    required this.native,
    required this.translation,
    this.done = false,
    this.selected = false,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        native: j['native'] as String,
        translation: j['translation'] as String,
        done: j['done'] as bool? ?? false,
        selected: j['selected'] as bool? ?? false,
      );
}

/// One module within a course. `lessons` may be empty on summary
/// responses — only the *selected* module typically ships with its
/// lessons inlined.
class CourseModule {
  final String id;
  final String name;
  final int lessonCount;
  final int completedCount;
  final ModuleState state;
  final List<Lesson> lessons;

  const CourseModule({
    required this.id,
    required this.name,
    required this.lessonCount,
    required this.completedCount,
    required this.state,
    this.lessons = const [],
  });

  factory CourseModule.fromJson(Map<String, dynamic> j) => CourseModule(
        id: j['id'] as String,
        name: j['name'] as String,
        lessonCount: j['lesson_count'] as int,
        completedCount: j['completed_count'] as int,
        state: ModuleState.fromString(j['state'] as String),
        lessons: ((j['lessons'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(Lesson.fromJson)
            .toList(),
      );
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

  factory CourseSummary.fromJson(Map<String, dynamic> j) => CourseSummary(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        icon: (j['icon'] as String?) ?? 'play_arrow',
        levelPill: j['level_pill'] as String,
        sourceLang: Lang.byCode(j['source_lang'] as String),
        targetLang: Lang.byCode(j['target_lang'] as String),
        inProgress: (j['in_progress'] as bool?) ?? false,
        progress: (j['progress'] as num?)?.toDouble(),
        footer: j['footer'] as String?,
      );
}

/// Full shape returned by `GET /courses/{course_id}` — adds module
/// breakdown and totals on top of [CourseSummary].
class CourseDetail extends CourseSummary {
  final int totalLessons;
  final int completedLessons;
  final int totalWords;
  final List<CourseModule> modules;

  const CourseDetail({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.icon,
    required super.levelPill,
    required super.sourceLang,
    required super.targetLang,
    super.inProgress,
    super.progress,
    super.footer,
    required this.totalLessons,
    required this.completedLessons,
    required this.totalWords,
    required this.modules,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> j) => CourseDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        icon: (j['icon'] as String?) ?? 'play_arrow',
        levelPill: j['level_pill'] as String,
        sourceLang: Lang.byCode(j['source_lang'] as String),
        targetLang: Lang.byCode(j['target_lang'] as String),
        inProgress: (j['in_progress'] as bool?) ?? false,
        progress: (j['progress'] as num?)?.toDouble(),
        footer: j['footer'] as String?,
        totalLessons: j['total_lessons'] as int,
        completedLessons: j['completed_lessons'] as int,
        totalWords: j['total_words'] as int,
        modules: ((j['modules'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(CourseModule.fromJson)
            .toList(),
      );
}
