import 'package:flutter/material.dart';

import '../data/chat_message.dart';
import '../data/chat_responder.dart';
import 'chat_options.dart';
import 'chat_results.dart';
import 'debug_dialog.dart';

class ChatPanel extends StatefulWidget {
  const ChatPanel({required this.responder, super.key});

  final Responder responder;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final promptController = TextEditingController();
  final scrollController = ScrollController();
  static const greeting =
      'Hi! Tell me what you want to build for this course and I will help you shape it.';

  final messages = <ChatMessage>[
    const ChatMessage(text: greeting, fromUser: false),
  ];
  bool waiting = false;

  @override
  void initState() {
    super.initState();
    _loadStartingOptions();
  }

  Future<void> _loadStartingOptions() async {
    final List<ChatOption> options;
    try {
      options = await widget.responder.startingOptions();
    } catch (_) {
      // The chat still works by typing when the options cannot be loaded.
      return;
    }
    if (!mounted) return;
    setState(() {
      messages[0] = ChatMessage(
        text: greeting,
        fromUser: false,
        options: options,
      );
    });
  }

  @override
  void dispose() {
    promptController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _sendTyped() => _sendPrompt(promptController.text);

  void _sendOption(ChatOption option, String? input) => _sendPrompt(
    input == null ? option.label : '${option.label}: $input',
    option: option,
    input: input,
  );

  Future<void> _sendPrompt(
    String text, {
    ChatOption? option,
    String? input,
  }) async {
    final prompt = text.trim();
    if (prompt.isEmpty || waiting) return;
    final lastReply = messages.lastWhere(
      (message) => !message.fromUser,
      orElse: () => const ChatMessage(text: '', fromUser: false),
    );
    setState(() {
      messages.add(ChatMessage(text: prompt, fromUser: true));
      waiting = true;
      promptController.clear();
    });
    _scrollToBottom();

    final reply = await widget.responder.respond(
      prompt,
      option: option,
      input: input,
      lastReply: lastReply,
    );
    if (!mounted) return;
    setState(() {
      messages.add(reply);
      waiting = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4E0D9))),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFB86F46),
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Course assistant',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17252D),
                  ),
                ),
              ],
            ),
          ),
          // Flexible + shrinkWrap keeps the input right under the last message
          // until the list fills the pane, then the list scrolls above it.
          Flexible(
            child: ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length + (waiting ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const ThinkingBubble();
                }
                final isLatest = index == messages.length - 1;
                return ChatBubble(
                  message: messages[index],
                  onOptionSelected: isLatest && !waiting ? _sendOption : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: promptController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTyped(),
              decoration: InputDecoration(
                hintText: 'Ask the assistant...',
                suffixIcon: IconButton(
                  tooltip: 'Send message',
                  onPressed: waiting ? null : _sendTyped,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                filled: true,
                fillColor: const Color(0xFFFBF8F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F1EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2B7771),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Thinking…',
              style: TextStyle(color: Color(0xFF748087), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, this.onOptionSelected, super.key});

  final ChatMessage message;

  /// Called with the picked option. Null disables the options.
  final OptionSelected? onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final debug = message.debug;
    final results = message.results;
    final bubble = Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: message.fromUser
              ? const Color(0xFF2B7771)
              : const Color(0xFFF5F1EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.fromUser ? Colors.white : const Color(0xFF17252D),
            height: 1.4,
            fontSize: 14,
          ),
        ),
      ),
    );

    final row = Row(
      mainAxisAlignment: message.fromUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bubble,
        if (debug != null)
          IconButton(
            tooltip: 'Show debug data',
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            color: const Color(0xFF8A979A),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => DebugDialog(debug: debug),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row,
          if (results != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ChatResults(results: results),
            ),
          if (message.options.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ChatOptions(
                options: message.options,
                onSelected: onOptionSelected,
              ),
            ),
        ],
      ),
    );
  }
}
