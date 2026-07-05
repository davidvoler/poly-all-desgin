import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared building blocks for the "Create with AI" pages
/// (create_course_page.dart, create_course_steps_page.dart) — the
/// exercise-type catalogue + per-type YAML example, and the small form
/// controls both pages need. Extracted once a second page needed the
/// exact same pieces so the two prompts can't drift out of sync.

/// A supported exercise type and how it maps onto the import format. Keys
/// match `exercise_type` in content/example_course.yaml exactly.
class ExerciseType {
  final String key;
  final String label;
  final String hint;
  const ExerciseType(this.key, this.label, this.hint);
}

const List<ExerciseType> kExerciseTypes = [
  ExerciseType('single_choice', 'Single choice',
      'One correct option, the rest distractors.'),
  ExerciseType('multiple_choice', 'Multiple choice',
      'More than one correct option in the same question.'),
  ExerciseType('description', 'Description',
      'A free-text note or context — no question or answer.'),
  ExerciseType('annotated_sentence', 'Annotated sentence',
      'A sentence with per-word annotations (meaning/notes).'),
  ExerciseType('words_in_sentence', 'Words in sentence',
      'Pick the words that do (and don\'t) appear in the sentence.'),
];

/// Per-type YAML snippet for the LLM prompt, matching the exact shape
/// content/example_course.yaml uses (and utils/course_import.py parses).
String exerciseTypeExample(
  String key, {
  required String lang,
  required String studentLang,
}) {
  switch (key) {
    case 'single_choice':
      return '''type: exercise
exercise_type: single_choice
sentence: <sentence in $lang>
options:
- text: <correct answer in $studentLang>
  correct: true
- text: <distractor>
- text: <distractor>
hint: <optional short hint>
weight: <order within the lesson>''';
    case 'multiple_choice':
      return '''type: exercise
exercise_type: multiple_choice
sentence: <question or sentence in $lang>
options:
- text: <correct option>
  correct: true
- text: <correct option>
  correct: true
- text: <distractor>
weight: <order within the lesson>''';
    case 'description':
      return '''type: exercise
exercise_type: description
description: <free-text note or context — no sentence or options>
weight: <order within the lesson>''';
    case 'annotated_sentence':
      return '''type: exercise
exercise_type: annotated_sentence
sentence: <sentence in $lang>
annotations:
  - word: <a word from the sentence>
    annotation: <its meaning or a short note>
description: <optional short note>
weight: <order within the lesson>''';
    case 'words_in_sentence':
      return '''type: exercise
exercise_type: words_in_sentence
sentence: <sentence in $lang>
correct_options:
  - <word that appears in the sentence>
incorrect_options:
  - <word that does not appear in the sentence>
weight: <order within the lesson>''';
    default:
      return '';
  }
}

class GroupLabel extends StatelessWidget {
  final String text;
  const GroupLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      );
}

class CourseField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final VoidCallback onChanged;
  const CourseField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          // Rebuild the page (and the live prompt) on every keystroke.
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: DashColors.w(0.35)),
            filled: true,
            fillColor: DashColors.w(0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide: BorderSide(color: DashColors.w(0.14)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide: BorderSide(color: DashColors.w(0.14)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide:
                  BorderSide(color: DashColors.brand.withValues(alpha: 0.55)),
            ),
          ),
        ),
      ],
    );
  }
}

class Segment extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const Segment({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final o in options) ...[
          if (o != options.first) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(o),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: o == selected
                      ? DashColors.brand.withValues(alpha: 0.30)
                      : DashColors.w(0.06),
                  borderRadius: DashRadii.pill,
                  border: Border.all(
                    color: o == selected
                        ? DashColors.brand
                        : DashColors.w(0.16),
                  ),
                ),
                child: Text(
                  o,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white
                        .withValues(alpha: o == selected ? 1 : 0.75),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Labelled +/- stepper for a bounded int value. Named to avoid colliding
/// with Flutter's own `Stepper` widget.
class NumberStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        RoundStep(
          icon: Icons.remove,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        RoundStep(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class RoundStep extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const RoundStep({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: DashColors.w(enabled ? 0.10 : 0.04),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DashColors.w(0.16)),
          ),
          child: Icon(icon,
              size: 16,
              color: Colors.white.withValues(alpha: enabled ? 1 : 0.30)),
        ),
      ),
    );
  }
}

class TypeChip extends StatelessWidget {
  final ExerciseType type;
  final bool selected;
  final VoidCallback? onTap;
  const TypeChip(
      {super.key, required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? DashColors.brand.withValues(alpha: 0.28)
            : DashColors.w(disabled ? 0.03 : 0.06),
        borderRadius: DashRadii.chip,
        border: Border.all(
          color: selected ? DashColors.brand : DashColors.w(0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.add_circle_outline,
            size: 15,
            color: disabled
                ? DashColors.w(0.30)
                : (selected ? DashColors.brand : DashColors.w(0.55)),
          ),
          const SizedBox(width: 7),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: disabled ? 0.40 : 1),
            ),
          ),
        ],
      ),
    );
    return Tooltip(
      message: type.hint,
      child: disabled ? chip : GestureDetector(onTap: onTap, child: chip),
    );
  }
}

class SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const SwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: DashColors.brand,
          ),
        ],
      ),
    );
  }
}
