class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    this.options = const [],
    this.results,
    this.debug,
    this.routerState,
  });

  final String text;
  final bool fromUser;

  /// Suggested answers the user can pick instead of typing.
  final List<ChatOption> options;

  /// What a prompt produced, such as suggested words, shown under the
  /// reply.
  final Map<String, Object?>? results;

  /// Data about how a reply was produced, shown in the debug window.
  final Map<String, Object?>? debug;

  /// Server state the next prompt must send back, such as the last
  /// router and action types.
  final Map<String, Object?>? routerState;
}

class ChatOption {
  const ChatOption(this.label, {this.inputHint, this.data});

  final String label;

  /// The option as the server sent it, returned when the option is picked.
  final Map<String, Object?>? data;

  /// When set, picking the option asks the user for a value first,
  /// using this as the text field hint.
  final String? inputHint;

  bool get needsInput => inputHint != null;
}
