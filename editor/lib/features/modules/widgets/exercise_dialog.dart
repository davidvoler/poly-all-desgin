import 'package:flutter/material.dart';

import '../data/module.dart';

/// Adds or edits an exercise, with fields that fit its type. Pops the
/// edited exercise, or null when cancelled.
class ExerciseDialog extends StatefulWidget {
  const ExerciseDialog({
    required this.exercise,
    this.words = const [],
    super.key,
  });

  /// The exercise to edit; one without an id is new.
  final Exercise exercise;

  /// The module's words, offered for the word field.
  final List<Word> words;

  @override
  State<ExerciseDialog> createState() => _ExerciseDialogState();
}

/// One answer option of a choice exercise.
class _Option {
  _Option([String text = '', this.correct = false])
    : controller = TextEditingController(text: text);

  final TextEditingController controller;
  bool correct;
}

class _ExerciseDialogState extends State<ExerciseDialog> {
  /// Options a new choice exercise starts with.
  static const defaultOptionCount = 4;

  final formKey = GlobalKey<FormState>();
  late String type = exerciseTypes.containsKey(widget.exercise.type)
      ? widget.exercise.type
      : exerciseTypes.keys.first;
  late final word = TextEditingController(text: widget.exercise.word);
  final wordFocus = FocusNode();
  late final question = TextEditingController(text: widget.exercise.question);
  late final translation = TextEditingController(
    text: widget.exercise.translation,
  );
  late final explanation = TextEditingController(
    text: widget.exercise.explanation,
  );
  late final List<_Option> options = _initialOptions();
  late bool statementIsTrue = widget.exercise.answer.toLowerCase() != 'false';

  /// Shown under the options when they are not valid.
  String? optionsError;

  /// Types answered by picking from options.
  bool get isChoice => const {
    'single_choice',
    'multiple_choice',
    'fill_in_the_blank',
  }.contains(type);

  /// Choice types with exactly one correct option.
  bool get hasOneCorrect => type != 'multiple_choice';

  List<_Option> _initialOptions() {
    final exercise = widget.exercise;
    return [
      for (final option in exercise.correctOptions) _Option(option, true),
      for (final option in exercise.incorrectOptions) _Option(option),
      for (
        var i =
            exercise.correctOptions.length + exercise.incorrectOptions.length;
        i < defaultOptionCount;
        i++
      )
        _Option(),
    ];
  }

  @override
  void dispose() {
    for (final controller in [
      word,
      question,
      translation,
      explanation,
      for (final option in options) option.controller,
    ]) {
      controller.dispose();
    }
    wordFocus.dispose();
    super.dispose();
  }

  void _setCorrect(_Option option, bool correct) {
    setState(() {
      // Single choice and fill in the blank have exactly one correct option.
      if (hasOneCorrect && correct) {
        for (final other in options) {
          other.correct = false;
        }
      }
      option.correct = correct;
      optionsError = null;
    });
  }

  /// The option problem to show, or null when the options are valid.
  String? _validateOptions() {
    final filled = options.where((o) => o.controller.text.trim().isNotEmpty);
    final correct = filled.where((o) => o.correct).length;
    if (filled.length < 2) return 'Add at least 2 options.';
    if (correct == 0) return 'Mark the correct option.';
    if (hasOneCorrect && correct > 1) return 'Mark only one correct option.';
    return null;
  }

  void submit() {
    final formValid = formKey.currentState!.validate();
    setState(() => optionsError = isChoice ? _validateOptions() : null);
    if (!formValid || optionsError != null) return;
    final current = widget.exercise;
    final filled = [
      for (final option in options)
        if (option.controller.text.trim().isNotEmpty) option,
    ];
    final (
      String questionText,
      String answerText,
      List<String> correct,
      List<String> wrong,
    ) = switch (type) {
      'true_false' => (
        question.text.trim(),
        '$statementIsTrue',
        ['$statementIsTrue'],
        ['${!statementIsTrue}'],
      ),
      'explanation' => ('', '', <String>[], <String>[]),
      _ => (
        question.text.trim(),
        filled.firstWhere((o) => o.correct).controller.text.trim(),
        [
          for (final o in filled)
            if (o.correct) o.controller.text.trim(),
        ],
        [
          for (final o in filled)
            if (!o.correct) o.controller.text.trim(),
        ],
      ),
    };
    Navigator.of(context).pop(
      Exercise(
        id: current.id,
        courseId: current.courseId,
        moduleId: current.moduleId,
        lessonId: current.lessonId,
        type: type,
        word: word.text.trim(),
        question: questionText,
        answer: answerText,
        correctOptions: correct,
        incorrectOptions: wrong,
        translation: type == 'explanation' ? '' : translation.text.trim(),
        explanation: explanation.text.trim(),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final isNew = widget.exercise.id == null;
    const gap = SizedBox(height: 14);
    return Dialog(
      backgroundColor: const Color(0xFFFFFCF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(32, 30, 32, 28),
            children: [
              Text(
                isNew ? 'Add an exercise' : 'Edit exercise',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17252D),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: type,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: [
                        for (final entry in exerciseTypes.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        type = value!;
                        optionsError = null;
                        if (hasOneCorrect) _keepOneCorrect();
                      }),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _buildWordField()),
                ],
              ),
              gap,
              ..._buildTypeFields(isNew),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: submit,
                    child: Text(isNew ? 'Add' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Switching to a one-correct type keeps only the first correct option.
  void _keepOneCorrect() {
    var seen = false;
    for (final option in options) {
      if (option.correct && seen) option.correct = false;
      seen = seen || option.correct;
    }
  }

  List<Widget> _buildTypeFields(bool isNew) {
    const gap = SizedBox(height: 14);
    final translationField = TextFormField(
      controller: translation,
      maxLines: null,
      decoration: const InputDecoration(labelText: 'Translation'),
    );
    switch (type) {
      case 'true_false':
        return [
          TextFormField(
            controller: question,
            autofocus: isNew,
            maxLines: null,
            validator: _required,
            decoration: const InputDecoration(labelText: 'Statement'),
          ),
          gap,
          const Text(
            'The statement is',
            style: TextStyle(color: Color(0xFF748087), fontSize: 13),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('True')),
              ButtonSegment(value: false, label: Text('False')),
            ],
            selected: {statementIsTrue},
            onSelectionChanged: (value) =>
                setState(() => statementIsTrue = value.single),
          ),
          gap,
          translationField,
        ];
      case 'explanation':
        return [
          TextFormField(
            controller: explanation,
            autofocus: isNew,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Explanation',
              alignLabelWithHint: true,
            ),
          ),
        ];
      default:
        final blank = type == 'fill_in_the_blank';
        return [
          TextFormField(
            controller: question,
            autofocus: isNew,
            maxLines: null,
            validator: _required,
            decoration: InputDecoration(
              labelText: blank ? 'Question' : 'Sentence',
              hintText: blank
                  ? 'Use ___ for the blank'
                  : 'A sentence that uses the word',
            ),
          ),
          gap,
          ..._buildOptions(),
          gap,
          translationField,
          gap,
          TextFormField(
            controller: explanation,
            maxLines: null,
            decoration: const InputDecoration(labelText: 'Explanation'),
          ),
        ];
    }
  }

  /// Option rows with a checkbox marking the correct ones.
  List<Widget> _buildOptions() => [
    Text(
      hasOneCorrect
          ? 'Options · check the correct one'
          : 'Options · check every correct one',
      style: const TextStyle(color: Color(0xFF748087), fontSize: 13),
    ),
    for (final (index, option) in options.indexed)
      Row(
        children: [
          Checkbox(
            value: option.correct,
            onChanged: (value) => _setCorrect(option, value ?? false),
          ),
          Expanded(
            child: TextField(
              controller: option.controller,
              onChanged: (_) {
                if (optionsError != null) setState(() => optionsError = null);
              },
              decoration: InputDecoration(hintText: 'Option ${index + 1}'),
            ),
          ),
          IconButton(
            tooltip: 'Remove option',
            onPressed: options.length <= 2
                ? null
                : () {
                    setState(() => options.remove(option));
                    // Disposed after the row that uses it is gone.
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => option.controller.dispose(),
                    );
                  },
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => options.add(_Option())),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add option'),
      ),
    ),
    if (optionsError != null)
      Text(
        optionsError!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
  ];

  /// A text field that suggests the module's words as you type.
  Widget _buildWordField() => RawAutocomplete<String>(
    textEditingController: word,
    focusNode: wordFocus,
    optionsBuilder: (value) {
      final text = value.text.trim().toLowerCase();
      return [
        for (final w in widget.words)
          if (text.isEmpty || w.text.toLowerCase().contains(text)) w.text,
      ];
    },
    fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Word',
            hintText: 'The word it practises',
          ),
        ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 240),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              for (final option in options)
                ListTile(
                  dense: true,
                  title: Text(option),
                  onTap: () => onSelected(option),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
