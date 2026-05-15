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
  Future<List<CourseSummary>> fetchCourses({required Lang source, required Lang target}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/course/',
      queryParameters: {
        'lang': source.code,
        'to_lang': target.code,
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
}

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepository(ref.watch(dioProvider));
});

/// Auto-refetches when the user switches their speak/learning languages
/// (the courses list is conceptually scoped to the current pair).
final coursesListProvider = FutureProvider<List<CourseSummary>>((ref) {
  final repo = ref.watch(coursesRepositoryProvider);
  final source = ref.watch(speakLangProvider);
  final target = ref.watch(learningLangProvider);
  return repo.fetchCourses(source: source, target: target);
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

/// Which module is currently open on the course page. `null` means
/// "no explicit choice yet" — the page falls back to the first module
/// returned by [modulesProvider].
class SelectedModuleIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? id) => state = id;
}

final selectedModuleIdProvider =
    NotifierProvider<SelectedModuleIdNotifier, int?>(SelectedModuleIdNotifier.new);
