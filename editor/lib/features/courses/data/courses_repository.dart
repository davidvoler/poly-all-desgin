import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'course.dart';
import 'language.dart';

class CoursesRepository {
  const CoursesRepository(this._dio);

  final Dio _dio;

  Future<List<Course>> fetchCourses({
    Map<String, String> languageNames = const {},
  }) async {
    final response = await _dio.get<List<dynamic>>('/api/v1/courses/courses');
    return [
      for (final row in response.data ?? const [])
        Course.fromJson(
          row as Map<String, dynamic>,
          languageNames: languageNames,
        ),
    ];
  }

  /// Saves a new course and returns it with its server id.
  Future<Course> createCourse(Course course) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/courses/course',
      data: course.toJson(),
    );
    final created = Course.fromJson(response.data!);
    if (created.id == null) {
      throw StateError('The server did not save the course.');
    }
    return created;
  }

  /// Saves changes to an existing course and returns it as saved.
  Future<Course> updateCourse(Course course) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/courses/course',
      data: course.toJson(),
    );
    return Course.fromJson(response.data!);
  }
}

final coursesRepositoryProvider = Provider<CoursesRepository>(
  (ref) => CoursesRepository(ref.watch(dioProvider)),
);

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  // Courses still load, with the built-in names, when languages cannot.
  List<Language> languages;
  try {
    languages = await ref.watch(languagesProvider.future);
  } catch (_) {
    languages = builtInLanguages;
  }
  return ref
      .watch(coursesRepositoryProvider)
      .fetchCourses(
        languageNames: {
          for (final language in languages) language.code: language.name,
        },
      );
});
