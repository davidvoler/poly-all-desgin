import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../courses/data/course.dart';
import '../../courses/data/prompts_context.dart';
import '../../modules/data/module.dart';
import 'ai_models.dart';
import 'chat_message.dart';
import 'chat_responder.dart';
import 'prompt_client.dart';

/// Answers prompts through the server's prompt router.
class PromptRouterResponder implements Responder {
  const PromptRouterResponder({
    required this.client,
    required this.course,
    this.context,
    this.onReply,
    this.aiChoice,
  });

  final PromptClient client;
  final Course course;

  /// Reads the course's current context when a prompt is sent.
  final PromptsContext? Function()? context;

  /// Called after the server answers, to reload what a prompt may change.
  final void Function()? onReply;

  /// Reads the provider and model picked in the chat when a prompt is sent.
  final AiChoice Function()? aiChoice;

  @override
  Future<List<ChatOption>> startingOptions() async {
    final id = course.id;
    if (id == null) return const [];
    return [
      for (final option in await client.defaultOptions(id))
        ChatOption(option['option_text'] as String, data: option),
    ];
  }

  @override
  Future<ChatMessage> respond(
    String prompt, {
    ChatOption? option,
    String? input,
    ChatMessage? lastReply,
  }) async {
    final startedAt = DateTime.now();
    final request = _buildRequest(prompt, option, input, lastReply);
    Map<String, dynamic>? result;
    Object? error;
    try {
      result = await client.send(request);
    } catch (e) {
      error = e;
    }

    if (result?['success'] == true) onReply?.call();
    final response = result?['prompt_response'] as Map<String, dynamic>?;
    final debug = {
      'responder': 'PromptRouterResponder',
      'request': request,
      'result': result,
      'error': error?.toString(),
      'started_at': startedAt.toIso8601String(),
      'duration_ms': DateTime.now().difference(startedAt).inMilliseconds,
    };

    if (error != null || result?['success'] != true) {
      return ChatMessage(
        text:
            'Something went wrong talking to the server: '
            '${error ?? result?['errors']}',
        fromUser: false,
        debug: debug,
      );
    }
    if (response == null) {
      return ChatMessage(
        text: 'The prompt router returned no reply.',
        fromUser: false,
        debug: debug,
      );
    }
    final results = response['results'] as Map<String, dynamic>?;
    final hasResults = results != null && results.isNotEmpty;
    var options = [
      for (final option in response['option'] as List? ?? const [])
        ChatOption(
          (option as Map<String, dynamic>)['option_text'] as String,
          data: option,
        ),
    ];
    // A reply without its own options offers the next steps for where the
    // course now is.
    if (options.isEmpty) {
      try {
        options = await startingOptions();
      } catch (_) {
        // The reply still shows; the user can type the next request.
      }
    }
    return ChatMessage(
      text: _chatText(response, hasResults: hasResults),
      fromUser: false,
      results: hasResults ? results : null,
      options: options,
      debug: debug,
      routerState: {
        'last_router_type': response['prompt_router_type'],
        'last_prompt_type': response['prompt_type'],
      },
    );
  }

  Map<String, Object?> _buildRequest(
    String prompt,
    ChatOption? option,
    String? input,
    ChatMessage? lastReply,
  ) {
    // Send back the options from the last reply with the picked one marked.
    final options = [
      for (final offered in lastReply?.options ?? const <ChatOption>[])
        if (offered.data != null)
          {...offered.data!, 'selected': offered.label == option?.label},
    ];
    final context = this.context?.call();
    final ai = aiChoice?.call() ?? defaultAiChoice;
    return {
      'course': course.id == null ? null : course.toJson(),
      'module': null,
      'words_list': null,
      'course_id': course.id,
      'module_id': context?.moduleId,
      'lesson_id': context?.lessonId,
      'user_message': input ?? prompt,
      'provider': ai.provider,
      'model': ai.model,
      'options': options.isEmpty ? null : options,
      'router_type': option?.data?['router_type'],
      'prompt_type': option?.data?['prompt_type'],
      // What the option acts on, such as its words or a video part length.
      'prompt_values': option?.data?['prompt_values'] ?? const [],
      'last_router_type': lastReply?.routerState?['last_router_type'],
      'last_prompt_type': lastReply?.routerState?['last_prompt_type'],
    };
  }

  /// `ui_chat_response` is a free-form object; show its text when it has
  /// one, otherwise the raw JSON. Without one, the reply introduces the
  /// results when there are any.
  String _chatText(Map<String, dynamic> response, {required bool hasResults}) {
    final ui = response['ui_chat_response'] as Map<String, dynamic>?;
    if (ui == null || ui.isEmpty) {
      return hasResults ? 'Here are the results:' : 'Done.';
    }
    for (final key in const ['text', 'message', 'response']) {
      final value = ui[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return const JsonEncoder.withIndent('  ').convert(ui);
  }
}

/// Builds the responder for a course. Tests override this with the
/// offline [ChatResponder].
final responderFactoryProvider = Provider<Responder Function(Course course)>((
  ref,
) {
  final client = ref.watch(promptClientProvider);
  return (course) {
    final id = course.id;
    return PromptRouterResponder(
      client: client,
      course: course,
      context: id == null
          ? null
          : () => ref.read(courseContextProvider(id)).value,
      aiChoice: () => ref.read(aiChoiceProvider),
      // Prompts can add words, lessons and modules, and move the context.
      onReply: () {
        if (id != null) ref.invalidate(courseContextProvider(id));
        ref.invalidate(modulesProvider);
        ref.invalidate(lessonsProvider);
        ref.invalidate(wordsProvider);
        ref.invalidate(sentencesProvider);
      },
    );
  };
});
