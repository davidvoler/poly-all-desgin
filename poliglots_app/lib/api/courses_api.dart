import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/lang.dart';
import 'models.dart';

/// Base URL for the Polyglots API. Override at compile-time via
///
///     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8004
///
/// Common values:
///   • iOS Simulator / macOS desktop : http://127.0.0.1:8004  (default)
///   • Android Emulator              : http://10.0.2.2:8004
///   • Real phone on same Wi-Fi      : `http://<your-mac-LAN-ip>:8004`
const String _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8004',
);

/// Base URL for exercise audio (served by the nginx audio container).
/// Override with `--dart-define=AUDIO_BASE_URL=…`. Exercise `audio`
/// paths are absolute (e.g. `/ar/ara/x.mp3`) so they append directly.
const String _kAudioBaseUrl = String.fromEnvironment(
  'AUDIO_BASE_URL',
  defaultValue: 'http://127.0.0.1:3002/audio',
);

/// Full URL for an exercise's `audio` path, or `null` when empty.
String? audioUrl(String audioPath) {
  if (audioPath.isEmpty) return null;
  final sep = audioPath.startsWith('/') ? '' : '/';
  return '$_kAudioBaseUrl$sep$audioPath';
}

/// Single shared Dio instance for the app. Kept as a Provider so tests
/// can `overrideWith` a mock client.
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
    ),
  );
});

/// Thin repository wrapping the courses endpoints. Pure data access —
/// no Riverpod calls inside, so it's easy to test in isolation.
class CoursesRepository {
  final Dio _dio;
  CoursesRepository(this._dio);

  /// `GET /api/v1/course/?lang=…&to_lang=…` — courses for the given pair.
  /// Server contract: `lang` is the language being **learned**,
  /// `to_lang` is the student's **native** language.
  Future<List<CourseSummary>> fetchCourses({
    required Lang learning,
    required Lang native,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/course/',
      queryParameters: {
        'lang': learning.code,
        'to_lang': native.code,
      },
    );
    final data = res.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(CourseSummary.fromJson)
        .toList();
  }

  /// `GET /api/v1/module/?course_id=…` — modules for a single course.
  Future<List<Module>> fetchModules(int courseId) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/module/',
      queryParameters: {'course_id': courseId},
    );
    final data = res.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(Module.fromJson)
        .toList();
  }

  /// `GET /api/v1/lesson/?module_id=…` — lessons for a single module.
  Future<List<Lesson>> fetchLessons(int moduleId) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/lesson/',
      queryParameters: {'module_id': moduleId},
    );
    final data = res.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(Lesson.fromJson)
        .toList();
  }

  /// `GET /api/v1/exercise/?lesson_id=…` — exercises for a single lesson.
  Future<List<Exercise>> fetchExercises(int lessonId) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/exercise/',
      queryParameters: {'lesson_id': lessonId},
    );
    final data = res.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList();
  }

  /// `GET /api/v1/preference/?user_id=…` — null when the user has no row.
  Future<Preference?> fetchPreference(int userId) async {
    final res = await _dio.get<dynamic>(
      '/api/v1/preference/',
      queryParameters: {'user_id': userId},
    );
    final data = res.data;
    if (data is! Map) return null;
    return Preference.fromJson(data.cast<String, dynamic>());
  }

  /// `POST /api/v1/preference/` — server upserts on `user_id`.
  Future<void> updatePreference(Preference pref) async {
    await _dio.post<dynamic>(
      '/api/v1/preference/',
      data: pref.toJson(),
    );
  }

  /// `POST /api/v1/user_data/` — append one answered-exercise result.
  Future<void> saveResults(Results results) async {
    await _dio.post<dynamic>(
      '/api/v1/user_data/',
      data: results.toJson(),
    );
  }

  /// `POST /api/v1/lesson/completed` — record that the user finished a
  /// lesson, with the summary the client computed at end-of-quiz. Called
  /// once when the lesson-complete screen first appears.
  Future<void> saveLessonCompleted({
    required String lang,
    required int? courseId,
    required int? moduleId,
    required int lessonId,
    required double score,
    required int correctCount,
    required int wrongCount,
    required int skippedCount,
    int courseLessonsCount = 0,
  }) async {
    await _dio.post<dynamic>(
      '/api/v1/lesson/completed',
      data: {
        'user_id': kCurrentUserId,
        'lang': lang,
        'course_id': courseId,
        'module_id': moduleId,
        'lesson_id': lessonId,
        'score': score,
        'skipped_count': skippedCount,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'course_lessons_count': courseLessonsCount,
      },
    );
  }

  /// `GET /api/v1/user_stats/?user_id=…&lang=…` — mastered counts.
  Future<UserStats> fetchUserStats(int userId, String lang) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/user_stats/',
      queryParameters: {'user_id': userId, 'lang': lang},
    );
    return UserStats.fromJson(res.data ?? const {});
  }

  /// `GET /api/v1/practice/words?user_id=…&lang=…` — every distinct
  /// word the user has encountered, with the server-side mastery score
  /// and the timestamp of the last practice attempt.
  Future<List<LearnedWord>> fetchWords(String lang) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/practice/words',
      queryParameters: {'user_id': kCurrentUserId, 'lang': lang},
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(LearnedWord.fromJson)
        .where((w) => w.word.trim().isNotEmpty)
        .toList();
  }

  /// `GET /api/v1/practice/<kind>?user_id=…&lang=…` — a fresh set of
  /// exercises to drill, scoped to the language being learned.
  Future<List<Exercise>> fetchPractice(PracticeKind kind, String lang) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/practice/${kind.path}',
      queryParameters: {'user_id': kCurrentUserId, 'lang': lang},
    );
    final data = res.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList();
  }

  /// `GET /api/v1/achievement/get_achievements` — most recent badges
  /// for the user on the given course/lang.
  Future<List<Achievement>> fetchAchievements({
    required int courseId,
    required String lang,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/achievement/get_achievements',
      queryParameters: {
        'user_id': kCurrentUserId,
        'course_id': courseId,
        'lang': lang,
      },
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Achievement.fromJson)
        .toList();
  }

  /// `POST /api/v1/achievement/check_new_achievements` — server-side
  /// scan that issues any newly-earned badges and returns them. Empty
  /// list when nothing new was unlocked.
  Future<List<Achievement>> checkNewAchievements({
    required int courseId,
    required String lang,
  }) async {
    final res = await _dio.post<List<dynamic>>(
      '/api/v1/achievement/check_new_achievements',
      queryParameters: {
        'user_id': kCurrentUserId,
        'course_id': courseId,
        'lang': lang,
      },
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Achievement.fromJson)
        .toList();
  }

  /// `POST /api/v1/practice/by_selected_words` — exercises focused on
  /// the explicit list of words the user picked on the Words page.
  Future<List<Exercise>> fetchPracticeByWords({
    required List<String> words,
    required String lang,
  }) async {
    final res = await _dio.post<List<dynamic>>(
      '/api/v1/practice/by_selected_words',
      data: {
        'user_id': kCurrentUserId,
        'lang': lang,
        'words': words,
      },
    );
    final data = res.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList();
  }
}

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepository(ref.watch(dioProvider));
});

/// Auto-refetches when the user switches their speak/learning languages
/// (the courses list is conceptually scoped to the current pair).
final coursesListProvider = FutureProvider<List<CourseSummary>>((ref) {
  final repo = ref.watch(coursesRepositoryProvider);
  final native = ref.watch(speakLangProvider);
  final learning = ref.watch(learningLangProvider);
  return repo.fetchCourses(learning: learning, native: native);
});

/// Mastery counts for the current user, scoped to the language being
/// learned. Sources the language from the saved preference (the
/// authoritative `lang`), falling back to the in-memory learning lang
/// before preferences have loaded. Refetches when either changes.
final userStatsProvider = FutureProvider<UserStats>((ref) {
  final repo = ref.watch(coursesRepositoryProvider);
  final prefLang = ref.watch(preferenceProvider.select((p) => p.value?.lang));
  final learning = ref.watch(learningLangProvider);
  return repo.fetchUserStats(kCurrentUserId, prefLang ?? learning.code);
});

/// Every word the user has seen so far, scoped to the language being
/// learned (same lang source as [userStatsProvider]). Refetches when
/// the learning language changes.
final wordsListProvider = FutureProvider<List<LearnedWord>>((ref) {
  final repo = ref.watch(coursesRepositoryProvider);
  final prefLang = ref.watch(preferenceProvider.select((p) => p.value?.lang));
  final learning = ref.watch(learningLangProvider);
  return repo.fetchWords(prefLang ?? learning.code);
});

/// Achievements earned by the current user for the active course/lang.
/// Resolves the lang the same way [userStatsProvider] does (saved
/// preference, fall back to in-memory learning lang) and is keyed on the
/// course id from the preference. Refetches whenever either changes.
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final repo = ref.watch(coursesRepositoryProvider);
  final courseId =
      ref.watch(preferenceProvider.select((p) => p.value?.courseId));
  final prefLang = ref.watch(preferenceProvider.select((p) => p.value?.lang));
  final learning = ref.watch(learningLangProvider);
  if (courseId == null) return const [];
  return repo.fetchAchievements(
    courseId: courseId,
    lang: prefLang ?? learning.code,
  );
});

/// Modules for a course; keyed by course id.
final modulesProvider =
    FutureProvider.family<List<Module>, int>((ref, courseId) {
  final repo = ref.watch(coursesRepositoryProvider);
  return repo.fetchModules(courseId);
});

/// Lessons for a module; keyed by module id.
final lessonsProvider =
    FutureProvider.family<List<Lesson>, int>((ref, moduleId) {
  final repo = ref.watch(coursesRepositoryProvider);
  return repo.fetchLessons(moduleId);
});

/// Exercises for a lesson; keyed by lesson id.
final exercisesProvider =
    FutureProvider.family<List<Exercise>, int>((ref, lessonId) {
  final repo = ref.watch(coursesRepositoryProvider);
  return repo.fetchExercises(lessonId);
});

/// Practice modes — each maps to a `/api/v1/practice/<path>` endpoint
/// and the quiz-screen title shown when drilling that set.
enum PracticeKind {
  words('by_words', 'Practicing words'),
  sentences('by_sentences', 'Practicing sentences'),
  exercises('by_exercises', 'Practicing exercises');

  final String path;
  final String title;
  const PracticeKind(this.path, this.title);
}

/// Practice exercises for a given mode, scoped to the language being
/// learned (same lang source as [userStatsProvider]).
final practiceExercisesProvider =
    FutureProvider.family<List<Exercise>, PracticeKind>((ref, kind) {
  final repo = ref.watch(coursesRepositoryProvider);
  final prefLang = ref.watch(preferenceProvider.select((p) => p.value?.lang));
  final learning = ref.watch(learningLangProvider);
  return repo.fetchPractice(kind, prefLang ?? learning.code);
});

/// Family key for [practiceByWordsProvider]. List equality is by element
/// so re-entering the quiz with the same word selection hits the cache
/// instead of re-fetching.
class PracticeByWordsKey {
  final String lang;
  final List<String> words;
  const PracticeByWordsKey({required this.lang, required this.words});

  @override
  bool operator ==(Object other) {
    if (other is! PracticeByWordsKey) return false;
    if (other.lang != lang) return false;
    if (other.words.length != words.length) return false;
    for (var i = 0; i < words.length; i++) {
      if (other.words[i] != words[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(lang, Object.hashAll(words));
}

/// Practice exercises for a user-picked subset of words. autoDispose so
/// each unique selection doesn't pile up in the provider cache.
final practiceByWordsProvider = FutureProvider.autoDispose
    .family<List<Exercise>, PracticeByWordsKey>((ref, key) {
  final repo = ref.watch(coursesRepositoryProvider);
  return repo.fetchPracticeByWords(words: key.words, lang: key.lang);
});

/// Which module is currently open on the course page. `null` means
/// "no explicit choice yet" — the page falls back to the first module
/// returned by [modulesProvider]. The setter also pushes the chosen
/// module id to the server so it survives across sessions.
class SelectedModuleIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? id) {
    state = id;
    if (id != null) {
      ref.read(preferenceProvider.notifier).save(moduleId: id);
    }
  }

  /// Seed from server preferences without echoing back a POST.
  void setSilently(int? id) => state = id;
}

final selectedModuleIdProvider =
    NotifierProvider<SelectedModuleIdNotifier, int?>(SelectedModuleIdNotifier.new);

/// Current user id. Hard-coded to 1 in dev; refactor when auth lands.
const int kCurrentUserId = 1;

/// Owns server-side per-user state. `build()` fetches once on first
/// watch; mutating methods POST and refresh local state synchronously.
class PreferenceNotifier extends AsyncNotifier<Preference?> {
  @override
  Future<Preference?> build() async {
    final repo = ref.read(coursesRepositoryProvider);
    return repo.fetchPreference(kCurrentUserId);
  }

  /// Merge new fields into the current preference, push to server, and
  /// update local state optimistically. Named `save` (not `update`) so
  /// it doesn't collide with [AsyncNotifier.update].
  Future<void> save({
    int? courseId,
    int? moduleId,
    int? lessonId,
    String? uiLang,
    String? lang,
    String? toLang,
  }) async {
    final current = state.value ?? const Preference(userId: kCurrentUserId);
    final next = current.copyWith(
      courseId: courseId,
      moduleId: moduleId,
      lessonId: lessonId,
      uiLang: uiLang,
      lang: lang,
      toLang: toLang,
    );
    state = AsyncValue.data(next);
    final repo = ref.read(coursesRepositoryProvider);
    await repo.updatePreference(next);
  }
}

final preferenceProvider =
    AsyncNotifierProvider<PreferenceNotifier, Preference?>(
        PreferenceNotifier.new);
