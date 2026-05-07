import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/lang.dart';
import 'models.dart';

/// Base URL for the Polyglots API. Override at compile-time via
///
///     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001
///
/// Common values:
///   • iOS Simulator / macOS desktop : http://127.0.0.1:8001  (default)
///   • Android Emulator              : http://10.0.2.2:8001
///   • Real phone on same Wi-Fi      : `http://<your-mac-LAN-ip>:8001`
const String _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8001',
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

  /// `GET /courses` — optionally filtered by language pair.
  Future<List<CourseSummary>> fetchCourses({Lang? source, Lang? target}) async {
    final res = await _dio.get<List<dynamic>>(
      '/courses',
      queryParameters: {
        if (source != null) 'source': source.code,
        if (target != null) 'target': target.code,
      },
    );
    final data = res.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(CourseSummary.fromJson)
        .toList();
  }

  /// `GET /courses/{course_id}` — full module + lesson breakdown.
  Future<CourseDetail> fetchCourse(String courseId) async {
    final res = await _dio.get<Map<String, dynamic>>('/courses/$courseId');
    return CourseDetail.fromJson(res.data!);
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

/// One-off fetch of a course's detail; keyed by course id.
final courseDetailProvider =
    FutureProvider.family<CourseDetail, String>((ref, courseId) {
  final repo = ref.watch(coursesRepositoryProvider);
  return repo.fetchCourse(courseId);
});
