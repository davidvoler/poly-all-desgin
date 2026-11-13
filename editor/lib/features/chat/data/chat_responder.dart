import '../../courses/data/course.dart';
import 'chat_message.dart';

/// Produces the assistant's reply to a prompt.
abstract interface class Responder {
  /// The options offered before the user has sent anything.
  Future<List<ChatOption>> startingOptions();

  /// [option] and [input] are set when the prompt came from picking an
  /// option, with [input] holding the value the user entered for it.
  /// [lastReply] is the previous assistant message, if any.
  Future<ChatMessage> respond(
    String prompt, {
    ChatOption? option,
    String? input,
    ChatMessage? lastReply,
  });
}

/// Offline responder that returns canned replies based on keywords.
class ChatResponder implements Responder {
  const ChatResponder({required this.course});

  final Course course;

  /// Simulated backend latency.
  static const responseDelay = Duration(seconds: 3);

  static const nameModule = ChatOption(
    'Name the module',
    inputHint: 'Module name',
  );
  static const ownTopic = ChatOption('Your own topic', inputHint: 'Topic');

  static const startOptions = [
    ChatOption('Create a module'),
    ChatOption('Suggest words'),
    ChatOption('Create exercises'),
  ];
  static const topics = ['Greetings', 'Numbers', 'Ordering food', 'Family'];
  static const wordLists = [
    'Basic list (10 words)',
    'Extended list (20 words)',
    'Useful phrases (10 phrases)',
  ];
  static const exerciseTypes = [
    'Multiple choice',
    'Fill in the blank',
    'Matching',
  ];
  static const grammarPoints = ['Present tense', 'Articles', 'Question words'];

  @override
  Future<List<ChatOption>> startingOptions() async => startOptions;

  @override
  Future<ChatMessage> respond(
    String prompt, {
    ChatOption? option,
    String? input,
    ChatMessage? lastReply,
  }) async {
    final startedAt = DateTime.now();
    await Future<void>.delayed(responseDelay);
    final reply = _inputReply(option, input) ?? _reply(prompt);

    return ChatMessage(
      text: reply.text,
      fromUser: false,
      options: reply.options,
      debug: {
        'responder': 'ChatResponder (canned keyword replies)',
        'prompt': prompt,
        'selected_option': option?.label,
        'input': input,
        'matched_rule': reply.rule,
        'options': [
          for (final option in reply.options)
            {'label': option.label, 'input_hint': option.inputHint},
        ],
        'course': {
          'title': course.title,
          'learning_language': course.learningLanguage,
          'student_language': course.studentLanguage,
          'level': course.level,
          'lessons': course.lessons,
        },
        'started_at': startedAt.toIso8601String(),
        'duration_ms': DateTime.now().difference(startedAt).inMilliseconds,
      },
    );
  }

  _Reply? _inputReply(ChatOption? option, String? input) {
    if (input == null) return null;
    if (option?.label == nameModule.label) {
      return _Reply(
        'module_named',
        'Module "$input" is ready to set up. What should it cover?',
        [..._plain(topics), ownTopic],
      );
    }
    if (option?.label == ownTopic.label) {
      return _topicReply(input);
    }
    return null;
  }

  _Reply _topicReply(String topic) => _Reply(
    'topic',
    'Here are three ways to build the "$topic" vocabulary for '
        '${course.learningLanguage}. Which one do you want?',
    _plain(wordLists),
  );

  // Rules are checked in order, so option texts must hit their own rule
  // before a broader keyword (e.g. "Basic list (10 words)" before "word").
  _Reply _reply(String prompt) {
    final text = prompt.toLowerCase();

    final topic = _pick(text, topics);
    if (topic != null) return _topicReply(topic);
    final wordList = _pick(text, wordLists);
    if (wordList != null) {
      return _Reply(
        'word_list',
        'Great, I would draft the ${wordList.toLowerCase()} now. '
            'Generation is not connected yet. What next?',
        const [ChatOption('Create exercises'), ChatOption('Create a module')],
      );
    }
    final exerciseType = _pick(text, exerciseTypes);
    if (exerciseType != null) {
      return _Reply(
        'exercise_type',
        'I would create $exerciseType exercises for this course. '
            'Generation is not connected yet.',
        startOptions,
      );
    }
    final grammarPoint = _pick(text, grammarPoints);
    if (grammarPoint != null) {
      return _Reply(
        'grammar_point',
        'I would explain "$grammarPoint" in ${course.studentLanguage}. '
            'Generation is not connected yet.',
        startOptions,
      );
    }
    if (_matches(text, ['hi', 'hello', 'hey']) || text.contains('start over')) {
      return _Reply(
        'greeting',
        'Hi! I can help you build "${course.title}". What would you like to do?',
        startOptions,
      );
    }
    if (text.contains('module')) {
      return _Reply(
        'module',
        'Let\'s create a new module. Give it a name, or start from a topic '
            'that fits a ${course.level} ${course.learningLanguage} course:',
        [nameModule, ..._plain(topics)],
      );
    }
    if (text.contains('word') || text.contains('vocab')) {
      return _Reply(
        'words',
        'Which topic should the ${course.learningLanguage} words cover?',
        [..._plain(topics), ownTopic],
      );
    }
    if (text.contains('exercise') || text.contains('quiz')) {
      return _Reply(
        'exercise',
        'Which exercise type would you like?',
        _plain(exerciseTypes),
      );
    }
    if (text.contains('explain') || text.contains('explanation')) {
      return _Reply(
        'explanation',
        'I will write explanations in ${course.studentLanguage}. '
            'Which grammar point?',
        _plain(grammarPoints),
      );
    }
    if (text.contains('course') || text.contains('info')) {
      return _Reply(
        'course_info',
        '"${course.title}" teaches ${course.learningLanguage} to '
            '${course.studentLanguage} speakers at level ${course.level}. '
            'It has ${course.lessons} lessons so far.',
        startOptions,
      );
    }
    return _Reply(
      'fallback',
      'Got it: "$prompt". I cannot act on this yet. '
          'Here is what I can help with:',
      startOptions,
    );
  }

  List<ChatOption> _plain(List<String> labels) => [
    for (final label in labels) ChatOption(label),
  ];

  String? _pick(String text, List<String> options) {
    for (final option in options) {
      if (text.contains(option.toLowerCase())) return option;
    }
    return null;
  }

  bool _matches(String text, List<String> words) {
    final tokens = text.split(RegExp(r'[^a-z]+'));
    return words.any(tokens.contains);
  }
}

class _Reply {
  const _Reply(this.rule, this.text, this.options);

  final String rule;
  final String text;
  final List<ChatOption> options;
}
