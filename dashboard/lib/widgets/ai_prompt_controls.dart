import 'package:flutter/material.dart';

import '../api/models.dart';
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

/// Common language names offered in the [LanguageField] dropdown. This is
/// a list of suggestions, not a whitelist — course creation does not limit
/// which languages an editor can use (see TASKS.md), so the field still
/// accepts any typed value, matching or not.
const List<String> kLanguageSuggestions = [
  'Arabic',
  'Chinese (Mandarin)',
  'Czech',
  'Danish',
  'Dutch',
  'English',
  'Finnish',
  'French',
  'German',
  'Greek',
  'Hebrew',
  'Hindi',
  'Hungarian',
  'Indonesian',
  'Italian',
  'Japanese',
  'Korean',
  'Norwegian',
  'Polish',
  'Portuguese',
  'Romanian',
  'Russian',
  'Spanish',
  'Swedish',
  'Thai',
  'Turkish',
  'Ukrainian',
  'Vietnamese',
];

/// A language picker: a dropdown of [kLanguageSuggestions] backed by a
/// plain text field, so an editor can either pick a common language or
/// type any other name/code the platform doesn't enumerate.
class LanguageField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final VoidCallback onChanged;
  const LanguageField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.hint,
  });

  @override
  State<LanguageField> createState() => _LanguageFieldState();
}

class _LanguageFieldState extends State<LanguageField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(widget.onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(widget.onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: DashRadii.input,
      borderSide: BorderSide(color: DashColors.w(0.14)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label.toUpperCase(), style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 6),
        DropdownMenu<String>(
          controller: widget.controller,
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          requestFocusOnTap: true,
          hintText: widget.hint,
          textStyle: const TextStyle(fontSize: 13, color: Colors.white),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(DashColors.darkBg),
          ),
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            hintStyle: TextStyle(fontSize: 13, color: DashColors.w(0.35)),
            filled: true,
            fillColor: DashColors.w(0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide:
                  BorderSide(color: DashColors.brand.withValues(alpha: 0.55)),
            ),
          ),
          dropdownMenuEntries: [
            for (final l in kLanguageSuggestions)
              DropdownMenuEntry(value: l, label: l),
          ],
        ),
      ],
    );
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

/// Editor for the course generation options (`CourseOptions` — mirrors the
/// server `CourseOption` stored on `course_simple.course.metadata`):
/// content source, AI provider/model, sentence length, distractor
/// similarity and the exercise-type mix. Used by the create-course dialog
/// (ai_courses_page.dart) and the workspace "Edit Course" tab
/// (ai_course_workspace_page.dart). Collapsible; manages its own
/// expand/collapse state.
class CourseOptionsEditor extends StatefulWidget {
  final CourseOptions options;
  final ValueChanged<CourseOptions> onChanged;
  final bool initiallyExpanded;
  final String heading;

  const CourseOptionsEditor({
    super.key,
    required this.options,
    required this.onChanged,
    this.initiallyExpanded = false,
    this.heading = 'GENERATION OPTIONS',
  });

  @override
  State<CourseOptionsEditor> createState() => _CourseOptionsEditorState();
}

class _CourseOptionsEditorState extends State<CourseOptionsEditor> {
  late bool _expanded = widget.initiallyExpanded;

  CourseOptions get _o => widget.options;
  void _set(CourseOptions next) => widget.onChanged(next);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: DashRadii.input,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: DashColors.w(0.7),
                ),
                const SizedBox(width: 6),
                Text(widget.heading, style: DashText.sectionLabel(size: 10)),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Text('CONTENT SOURCE', style: DashText.sectionLabel(size: 10)),
          const SizedBox(height: 6),
          Segment(
            options: kContentSources,
            selected: _o.contentSource,
            onSelect: (v) => _set(_o.copyWith(contentSource: v)),
          ),
          const SizedBox(height: 12),
          Text('AI PROVIDER', style: DashText.sectionLabel(size: 10)),
          const SizedBox(height: 6),
          Segment(
            options: kAiProviders,
            selected: _o.provider,
            onSelect: (v) => _set(_o.copyWith(provider: v)),
          ),
          const SizedBox(height: 12),
          Text('MODEL', style: DashText.sectionLabel(size: 10)),
          const SizedBox(height: 6),
          Segment(
            options: kAiModels,
            selected: _o.model,
            onSelect: (v) => _set(_o.copyWith(model: v)),
          ),
          const SizedBox(height: 14),
          NumberStepper(
            label: 'Min words / sentence',
            value: _o.minSentencesWords,
            min: 1,
            max: _o.maxSentencesWords,
            onChanged: (v) => _set(_o.copyWith(minSentencesWords: v)),
          ),
          const SizedBox(height: 10),
          NumberStepper(
            label: 'Max words / sentence',
            value: _o.maxSentencesWords,
            min: _o.minSentencesWords,
            max: 40,
            onChanged: (v) => _set(_o.copyWith(maxSentencesWords: v)),
          ),
          const SizedBox(height: 6),
          RatioSlider(
            label: 'Distractor similarity',
            value: _o.distractorSimilarity,
            onChanged: (v) => _set(_o.copyWith(distractorSimilarity: v)),
          ),
          const SizedBox(height: 10),
          Text('EXERCISE MIX', style: DashText.sectionLabel(size: 10)),
          const SizedBox(height: 2),
          RatioSlider(
            label: 'Single choice',
            value: _o.singleChoice,
            onChanged: (v) => _set(_o.copyWith(singleChoice: v)),
          ),
          RatioSlider(
            label: 'Multiple choice',
            value: _o.multipleChoice,
            onChanged: (v) => _set(_o.copyWith(multipleChoice: v)),
          ),
          RatioSlider(
            label: 'Identify words',
            value: _o.identifyWords,
            onChanged: (v) => _set(_o.copyWith(identifyWords: v)),
          ),
          RatioSlider(
            label: 'Description',
            value: _o.description,
            onChanged: (v) => _set(_o.copyWith(description: v)),
          ),
        ],
      ],
    );
  }
}

/// Label + 0.0–1.0 slider for a weight/ratio option.
class RatioSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const RatioSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
        ),
        Expanded(
          flex: 5,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: DashColors.brand,
              inactiveTrackColor: DashColors.w(0.16),
              thumbColor: DashColors.brand,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: (v) => onChanged(double.parse(v.toStringAsFixed(2))),
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
