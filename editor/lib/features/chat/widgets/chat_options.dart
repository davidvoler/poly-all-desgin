import 'package:flutter/material.dart';

import '../data/chat_message.dart';

typedef OptionSelected = void Function(ChatOption option, String? input);

/// Option chips under an assistant reply. An option that needs input opens a
/// text field and is only sent once the user submits a value.
class ChatOptions extends StatefulWidget {
  const ChatOptions({required this.options, this.onSelected, super.key});

  final List<ChatOption> options;

  /// Null disables the options.
  final OptionSelected? onSelected;

  @override
  State<ChatOptions> createState() => _ChatOptionsState();
}

class _ChatOptionsState extends State<ChatOptions> {
  final inputController = TextEditingController();
  final inputKey = GlobalKey();
  ChatOption? inputOption;

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  void _pick(ChatOption option) {
    if (option.needsInput) {
      setState(() => inputOption = option);
      // The field can open below the visible part of the chat.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final inputContext = inputKey.currentContext;
        if (inputContext == null) return;
        Scrollable.ensureVisible(
          inputContext,
          alignment: 1,
          duration: const Duration(milliseconds: 200),
        );
      });
      return;
    }
    widget.onSelected!(option, null);
  }

  void _submitInput() {
    final value = inputController.text.trim();
    if (value.isEmpty) return;
    widget.onSelected!(inputOption!, value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onSelected != null;
    final option = enabled ? inputOption : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in widget.options)
              ActionChip(
                avatar: option.needsInput
                    ? const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF2B7771),
                      )
                    : null,
                label: Text(option.label),
                onPressed: enabled ? () => _pick(option) : null,
                backgroundColor: option == inputOption
                    ? const Color(0xFFE3EAE5)
                    : Colors.white,
                side: const BorderSide(color: Color(0xFFD7E4DC)),
                labelStyle: const TextStyle(
                  color: Color(0xFF2B7771),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (option != null)
          Padding(
            key: inputKey,
            padding: const EdgeInsets.only(top: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: TextField(
                key: ValueKey(option.label),
                controller: inputController,
                autofocus: true,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitInput(),
                decoration: InputDecoration(
                  hintText: option.inputHint,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    tooltip: 'Submit ${option.inputHint}',
                    onPressed: _submitInput,
                    icon: const Icon(Icons.check_rounded, size: 18),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD7E4DC)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
