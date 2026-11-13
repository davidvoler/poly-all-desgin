import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// Sends prompts to the server's prompt router. The server queues each
/// prompt as a task, so [send] polls until the task result is ready.
class PromptClient {
  const PromptClient(this._dio);

  final Dio _dio;

  static const pollInterval = Duration(milliseconds: 500);

  /// Local models can take several minutes, e.g. extracting a video part.
  static const timeout = Duration(minutes: 10);

  /// The options to offer at the start of a course's conversation.
  Future<List<Map<String, dynamic>>> defaultOptions(int courseId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/prompt/default_options',
      queryParameters: {'course_id': courseId},
    );
    return response.data!.cast<Map<String, dynamic>>();
  }

  /// Returns the task result: `ready`, `success`, `errors`,
  /// `prompt_response` and `execution_time`.
  Future<Map<String, dynamic>> send(Map<String, Object?> request) async {
    final task = await _dio.post<Map<String, dynamic>>(
      '/api/v1/prompt/prompt',
      data: request,
    );
    final deadline = DateTime.now().add(timeout);
    var pollCount = 0;
    while (true) {
      await Future<void>.delayed(pollInterval);
      final results = await _dio.post<List<dynamic>>(
        '/api/v1/tasks/tasks_results',
        data: [
          {...?task.data, 'poll_count': ++pollCount},
        ],
      );
      final result = results.data!.first as Map<String, dynamic>;
      if (result['ready'] == true) return result;
      if (DateTime.now().isAfter(deadline)) {
        throw PromptTimeoutException(result['task_id'] as String?);
      }
    }
  }
}

class PromptTimeoutException implements Exception {
  const PromptTimeoutException(this.taskId);

  final String? taskId;

  @override
  String toString() =>
      'The prompt router did not answer within ${PromptClient.timeout.inMinutes} '
      'minutes (task $taskId).';
}

final promptClientProvider = Provider<PromptClient>(
  (ref) => PromptClient(ref.watch(dioProvider)),
);
