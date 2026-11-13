import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// Where the user is working in a course: the module and lesson that
/// prompts apply to. A `0` id means none.
class PromptsContext {
  const PromptsContext({
    required this.courseId,
    this.moduleId = 0,
    this.lessonId = 0,
  });

  factory PromptsContext.fromJson(Map<String, dynamic> json) => PromptsContext(
    courseId: json['course_id'] as int? ?? 0,
    moduleId: json['module_id'] as int? ?? 0,
    lessonId: json['lesson_id'] as int? ?? 0,
  );

  Map<String, Object?> toJson() => {
    'course_id': courseId,
    'module_id': moduleId,
    'lesson_id': lessonId,
  };

  final int courseId;
  final int moduleId;
  final int lessonId;
}

class ContextRepository {
  const ContextRepository(this._dio);

  final Dio _dio;

  /// The course's last saved context. The server creates one, with a first
  /// module and lesson, when the course has none.
  Future<PromptsContext> getOrCreate(int courseId) =>
      _post('get_or_create', PromptsContext(courseId: courseId));

  Future<PromptsContext> save(PromptsContext context) => _post('save', context);

  Future<PromptsContext> _post(String path, PromptsContext context) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/context/$path',
      data: context.toJson(),
    );
    return PromptsContext.fromJson(response.data!);
  }
}

final contextRepositoryProvider = Provider<ContextRepository>(
  (ref) => ContextRepository(ref.watch(dioProvider)),
);

/// Holds a course's context and saves it when the module or lesson changes.
class CourseContextNotifier extends AsyncNotifier<PromptsContext> {
  CourseContextNotifier(this.courseId);

  final int courseId;

  @override
  Future<PromptsContext> build() =>
      ref.watch(contextRepositoryProvider).getOrCreate(courseId);

  /// Makes [moduleId] and [lessonId] current and saves the change. The
  /// selection applies right away; a failed save throws.
  Future<void> select({required int moduleId, int lessonId = 0}) async {
    final current = state.value;
    if (current?.moduleId == moduleId && current?.lessonId == lessonId) return;
    final selected = PromptsContext(
      courseId: courseId,
      moduleId: moduleId,
      lessonId: lessonId,
    );
    state = AsyncData(selected);
    await ref.read(contextRepositoryProvider).save(selected);
  }
}

/// The context of a course, by course id.
final courseContextProvider =
    AsyncNotifierProvider.family<CourseContextNotifier, PromptsContext, int>(
      CourseContextNotifier.new,
    );
