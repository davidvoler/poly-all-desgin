import 'package:flutter/material.dart';

import '../../../core/widgets/navigation_rail_panel.dart';
import '../../courses/data/course.dart';

class ModuleEditingPage extends StatefulWidget {
  const ModuleEditingPage({
    required this.course,
    required this.moduleTitle,
    super.key,
  });

  final Course course;
  final String moduleTitle;

  @override
  State<ModuleEditingPage> createState() => _ModuleEditingPageState();
}

class _ModuleEditingPageState extends State<ModuleEditingPage> {
  static const providers = [
    'Ollama',
    'OpenAI',
    'Gemini',
    'Anthropic',
    'Copilot',
  ];
  static const models = ['muse-glimmer', 'gemma4'];

  final promptController = TextEditingController();
  final messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Tell me what you want learners to practice, and I will draft lessons and exercises for this module.',
      fromUser: false,
    ),
  ];
  String selectedProvider = 'Ollama';
  String selectedModel = 'muse-glimmer';

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  void _sendPrompt() {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      messages.add(_ChatMessage(text: prompt, fromUser: true));
      messages.add(
        _ChatMessage(
          text:
              'I will use $selectedModel via $selectedProvider to draft lessons and exercises about "$prompt".',
          fromUser: false,
        ),
      );
      promptController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const NavigationRailPanel(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Row(
                    children: [
                      _buildOutline(),
                      Expanded(child: _buildEditor()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 42),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E0D9))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to course',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 16),
          Text(
            widget.course.title,
            style: const TextStyle(color: Color(0xFF8A979A), fontSize: 13),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFB2B9B8),
            ),
          ),
          Text(
            widget.moduleTitle,
            style: const TextStyle(
              color: Color(0xFF17252D),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const Text(
            'Unsaved changes',
            style: TextStyle(color: Color(0xFF9A6B45), fontSize: 12),
          ),
          const SizedBox(width: 18),
          FilledButton(onPressed: () {}, child: const Text('Save')),
        ],
      ),
    );
  }

  Widget _buildOutline() {
    return Container(
      width: 260,
      color: const Color(0xFFFBF8F3),
      padding: const EdgeInsets.fromLTRB(26, 30, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MODULE OUTLINE',
            style: TextStyle(
              color: Color(0xFF9AA4A6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EAE5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 18,
                  color: Color(0xFF2B7771),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.moduleTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17252D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No lessons yet',
            style: TextStyle(color: Color(0xFF8A979A), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.moduleTitle,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17252D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask your AI partner to shape lessons and exercises for your learners.',
            style: TextStyle(color: Color(0xFF748087), fontSize: 14),
          ),
          const SizedBox(height: 22),
          _buildSettings(),
          const SizedBox(height: 16),
          Expanded(child: _buildChat()),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E4DC)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.tune_rounded, color: Color(0xFF2B7771), size: 20),
          const Text(
            'AI provider',
            style: TextStyle(
              color: Color(0xFF17252D),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              initialValue: selectedProvider,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Provider',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
              items: providers
                  .map(
                    (provider) => DropdownMenuItem(
                      value: provider,
                      child: Text(provider),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedProvider = value!),
            ),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: selectedModel,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Model',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
              items: models
                  .map(
                    (model) =>
                        DropdownMenuItem(value: model, child: Text(model)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedModel = value!),
            ),
          ),
          const Text(
            'Ready to generate',
            style: TextStyle(
              color: Color(0xFF2B7771),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E0D9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4E0D9))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFB86F46),
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Module generation',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17252D),
                  ),
                ),
                const Spacer(),
                Text(
                  '$selectedProvider · $selectedModel',
                  style: const TextStyle(
                    color: Color(0xFF8A979A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(22),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 620),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: message.fromUser
                          ? const Color(0xFF2B7771)
                          : const Color(0xFFF5F1EA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.fromUser
                            ? Colors.white
                            : const Color(0xFF17252D),
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: TextField(
              controller: promptController,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendPrompt(),
              decoration: InputDecoration(
                hintText: 'Describe the lessons or exercises you need...',
                suffixIcon: IconButton(
                  tooltip: 'Send prompt',
                  onPressed: _sendPrompt,
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

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}
