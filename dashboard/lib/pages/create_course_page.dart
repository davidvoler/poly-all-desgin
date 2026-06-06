import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

/// "Create with AI" — collects the shape of a course an editor wants and
/// assembles a ready-to-run LLM prompt that targets our import format (see
/// content/example_course/README.md). Phase 1 (this page): build + copy the
/// prompt, run it in any LLM, then upload the result on the Courses page.
/// Phase 2 (not built): a backend `/editor/ai/generate` that runs the LLM
/// and enrichment server-side. See CREATE_COURSE_WITH_AI.md.
class CreateCoursePage extends ConsumerStatefulWidget {
  const CreateCoursePage({super.key});

  @override
  ConsumerState<CreateCoursePage> createState() => _CreateCoursePageState();
}

/// A supported exercise type and how it maps onto the import format. Types
/// the importer can't express yet are [supported] = false (shown, disabled).
class _ExerciseType {
  final String key;
  final String label;
  final String hint;
  final bool supported;
  const _ExerciseType(this.key, this.label, this.hint, {this.supported = true});
}

const List<_ExerciseType> _exerciseTypes = [
  _ExerciseType('single', 'Single option',
      'One correct translation, the rest distractors.'),
  _ExerciseType('multiple', 'Multiple correct',
      'Several correct options in one question.'),
  _ExerciseType('identify', 'Identify words',
      'Pick the words that appear in the sentence.'),
  _ExerciseType('explanation', 'Explanations',
      'A short note shown after answering.'),
  _ExerciseType('match', 'Word match',
      'Format extension needed — not importable yet.',
      supported: false),
  _ExerciseType('alphabet', 'Learn alphabet',
      'New exercise type needed — not importable yet.',
      supported: false),
];

class _CreateCoursePageState extends ConsumerState<CreateCoursePage> {
  final _title = TextEditingController(text: 'Japanese for Hebrew Speakers');
  final _language = TextEditingController(text: 'Japanese');
  final _studentLanguage = TextEditingController(text: 'Hebrew');
  final _topic = TextEditingController(
      text: 'Everyday conversation for absolute beginners');

  String _level = 'A1';
  int _modules = 4;
  int _lessonsPerModule = 5;
  int _exercisesPerLesson = 8;

  // Selected exercise-type keys (supported ones only).
  final Set<String> _types = {'single', 'multiple', 'identify', 'explanation'};

  bool _audio = false;
  bool _ruby = false;

  // Paste-and-import: the LLM output and the in-flight import state.
  final _pasted = TextEditingController();
  bool _importing = false;
  String? _importError;

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  @override
  void dispose() {
    _title.dispose();
    _language.dispose();
    _studentLanguage.dispose();
    _topic.dispose();
    _pasted.dispose();
    super.dispose();
  }

  /// Import the pasted `=== path ===` document via the server text-import
  /// endpoint, then jump to the new course's detail page.
  Future<void> _importPasted() async {
    final doc = _pasted.text.trim();
    if (doc.isEmpty || _importing) return;
    setState(() {
      _importing = true;
      _importError = null;
    });
    try {
      final id =
          await ref.read(dashboardApiProvider).importCourseText(document: doc);
      if (!mounted) return;
      ref.invalidate(editorCoursesProvider);
      setState(() => _importing = false);
      if (id != null) {
        Navigator.pushReplacementNamed(context, '/course', arguments: id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _importError = '$e';
      });
    }
  }

  int get _totalExercises =>
      _modules * _lessonsPerModule * _exercisesPerLesson;

  /// Public mutator so the (stateless) form sub-widgets can update state and
  /// trigger a rebuild — including the live prompt preview.
  void apply(VoidCallback fn) => setState(fn);

  bool get _isJapanese {
    final l = _language.text.trim().toLowerCase();
    return l == 'ja' || l == 'japanese' || l.contains('日本');
  }

  /// Assemble the LLM prompt from the current form state. Embeds a compact
  /// version of the import-format spec so the model returns importable text.
  String _buildPrompt() {
    final selected = _exerciseTypes
        .where((t) => t.supported && _types.contains(t.key))
        .toList();
    final typeLines = selected.isEmpty
        ? '- single option (one [+], rest [-])'
        : selected.map((t) {
            switch (t.key) {
              case 'single':
                return '- single option: one [+] correct, the rest [-] distractors';
              case 'multiple':
                return '- multiple correct: more than one [+] line';
              case 'identify':
                return '- identify words: options are candidate words; [+] for words that appear in the sentence';
              case 'explanation':
                return '- explanations: add a "--- Explanation" note after some exercises';
              default:
                return '- ${t.label}';
            }
          }).join('\n');

    final enrich = <String>[
      if (_audio)
        'Audio will be generated separately by the platform — do not include audio.',
      if (_ruby && _isJapanese)
        'Japanese furigana (ruby) is added by the platform after import — write plain Japanese only.',
    ].join(' ');

    return '''You are an expert language-course author. Write a complete course for our import format.

Course to create:
- Title: ${_title.text.trim()}
- Teaches: ${_language.text.trim()}
- For students who speak: ${_studentLanguage.text.trim()}
- CEFR level: $_level
- Focus: ${_topic.text.trim()}
- Size: $_modules modules, $_lessonsPerModule lessons per module, ~$_exercisesPerLesson exercises per lesson.

Exercise types to use (vary them across lessons):
$typeLines
${enrich.isEmpty ? '' : '\n$enrich\n'}
OUTPUT FORMAT — return ONE plain-text document with a header line before each
file, exactly like this (no markdown, no commentary):

=== course.txt ===
name: <course title>
description: <one-line blurb>
language: ${_language.text.trim()}
student_languages: ${_studentLanguage.text.trim()}

=== module1/module.txt ===
module: <module title>

=== module1/lesson1/lesson.txt ===
lesson: <lesson title>

=== module1/lesson1/exercises.txt ===
---
<prompt sentence in ${_language.text.trim()}>
[+] <correct answer in ${_studentLanguage.text.trim()}>
[-] <distractor>
[-] <distractor>
--- Explanation
<optional short note>

Rules:
- Separate exercises with a line containing only ---.
- The first non-blank line of each block is the prompt sentence.
- Every exercise needs at least one [+]. Distractors are plausible but wrong.
- Number folders module1..module$_modules and lesson1..lesson$_lessonsPerModule to control order.
- Keep it natural and level-appropriate; avoid duplicate sentences.''';
  }

  void _copyPrompt() {
    Clipboard.setData(ClipboardData(text: _buildPrompt()));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1400),
          content: Text('Prompt copied — paste it into your LLM.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Create with AI',
      activeRoute: '/create-course',
      topbarTrailing: [
        GhostButton(
          label: 'Upload result',
          leading: Icons.file_upload_outlined,
          onTap: () => Navigator.pushReplacementNamed(context, '/courses'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth > 900;
          final form = _FormColumn(state: this);
          final preview = _PromptColumn(state: this);
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [form, const SizedBox(height: 16), preview],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: form),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: preview),
            ],
          );
        },
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  final _CreateCoursePageState state;
  const _FormColumn({required this.state});

  @override
  Widget build(BuildContext context) {
    // Rebuild the page (so the live prompt tracks text edits).
    void rebuild() => state.apply(() {});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GroupLabel('Basics'),
              const SizedBox(height: 12),
              _CourseField(
                controller: state._title,
                label: 'Course title',
                onChanged: rebuild,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CourseField(
                      controller: state._language,
                      label: 'Teaches (language)',
                      hint: 'Japanese or ja',
                      onChanged: rebuild,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CourseField(
                      controller: state._studentLanguage,
                      label: 'Student speaks',
                      hint: 'Hebrew or he',
                      onChanged: rebuild,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CourseField(
                controller: state._topic,
                label: 'Topic / focus',
                hint: 'e.g. travel, greetings, business',
                onChanged: rebuild,
              ),
              const SizedBox(height: 16),
              Text('LEVEL', style: DashText.sectionLabel(size: 10)),
              const SizedBox(height: 6),
              _Segment(
                options: _CreateCoursePageState._levels,
                selected: state._level,
                onSelect: (v) => state.apply(() => state._level = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GroupLabel('Structure'),
              const SizedBox(height: 12),
              _Stepper(
                label: 'Modules',
                value: state._modules,
                min: 1,
                max: 20,
                onChanged: (v) => state.apply(() => state._modules = v),
              ),
              const SizedBox(height: 10),
              _Stepper(
                label: 'Lessons / module',
                value: state._lessonsPerModule,
                min: 1,
                max: 20,
                onChanged: (v) =>
                    state.apply(() => state._lessonsPerModule = v),
              ),
              const SizedBox(height: 10),
              _Stepper(
                label: 'Exercises / lesson',
                value: state._exercisesPerLesson,
                min: 1,
                max: 30,
                onChanged: (v) =>
                    state.apply(() => state._exercisesPerLesson = v),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: DashColors.brand.withValues(alpha: 0.10),
                  borderRadius: DashRadii.input,
                  border: Border.all(
                      color: DashColors.brand.withValues(alpha: 0.30)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.functions,
                        size: 16, color: DashColors.w(0.75)),
                    const SizedBox(width: 8),
                    Text(
                      '≈ ${state._totalExercises} exercises total',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GroupLabel('Exercise mix'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _exerciseTypes)
                    _TypeChip(
                      type: t,
                      selected: t.supported && state._types.contains(t.key),
                      onTap: !t.supported
                          ? null
                          : () => state.apply(() {
                                if (!state._types.add(t.key)) {
                                  state._types.remove(t.key);
                                }
                              }),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GroupLabel('Enrichment'),
              const SizedBox(height: 6),
              _SwitchRow(
                title: 'Generate audio',
                subtitle: 'Synthesise a recording per sentence (Azure / Google).',
                value: state._audio,
                onChanged: (v) => state.apply(() => state._audio = v),
              ),
              _SwitchRow(
                title: 'Generate Japanese ruby',
                subtitle: state._isJapanese
                    ? 'Add furigana after import (backend utility).'
                    : 'Only applies to Japanese courses.',
                value: state._ruby && state._isJapanese,
                onChanged: state._isJapanese
                    ? (v) => state.apply(() => state._ruby = v)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromptColumn extends StatelessWidget {
  final _CreateCoursePageState state;
  const _PromptColumn({required this.state});

  @override
  Widget build(BuildContext context) {
    final prompt = state._buildPrompt();
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: _GroupLabel('AI prompt')),
              GhostButton(
                label: 'Copy',
                leading: Icons.copy_all_outlined,
                onTap: state._copyPrompt,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Run this in any LLM, then upload the result on the Courses page.',
            style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 460),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: DashRadii.input,
              border: Border.all(color: DashColors.w(0.10)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                prompt,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontFamily: 'monospace',
                  color: DashColors.w(0.85),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Copy prompt',
            leading: Icons.auto_awesome,
            onTap: state._copyPrompt,
          ),
          const SizedBox(height: 12),
          _CostEstimate(
            exercises: state._totalExercises,
            audio: state._audio,
          ),
          const SizedBox(height: 12),
          _PasteImport(state: state),
        ],
      ),
    );
  }
}

/// Estimated cost of generating this course, per the pricing in
/// CREATE_COURSE_WITH_AI.md: ~1 credit / exercise, plus audio billed per
/// 1k characters when the audio enrichment is on (rough sentence-length
/// assumption). Indicative only — final rates TBD.
class _CostEstimate extends StatelessWidget {
  final int exercises;
  final bool audio;
  const _CostEstimate({required this.exercises, required this.audio});

  @override
  Widget build(BuildContext context) {
    // Rough: ~40 characters of synthesised audio per exercise sentence.
    final audioK = (exercises * 40 / 1000).ceil();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        borderRadius: DashRadii.input,
        border: Border.all(color: DashColors.w(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 15, color: DashColors.w(0.6)),
              const SizedBox(width: 8),
              Text('ESTIMATED COST', style: DashText.sectionLabel(size: 10)),
            ],
          ),
          const SizedBox(height: 8),
          _costRow('Generation', '≈ $exercises credits', '1 / exercise'),
          if (audio) ...[
            const SizedBox(height: 4),
            _costRow('Audio', '≈ $audioK k chars', 'TTS, per 1k chars'),
          ],
          const SizedBox(height: 6),
          Text(
            'Indicative — billed when generation runs. Final rates TBD.',
            style: TextStyle(fontSize: 11, color: DashColors.w(0.45)),
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value, String note) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.white)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(width: 8),
        Text(note, style: TextStyle(fontSize: 11, color: DashColors.w(0.45))),
      ],
    );
  }
}

/// Paste the LLM's `=== path ===` output and import it straight into the
/// catalogue (server text-import endpoint), skipping the zip round-trip.
class _PasteImport extends StatelessWidget {
  final _CreateCoursePageState state;
  const _PasteImport({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        borderRadius: DashRadii.input,
        border: Border.all(color: DashColors.w(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.content_paste_go_outlined,
                  size: 15, color: DashColors.w(0.6)),
              const SizedBox(width: 8),
              Text('PASTE RESULT & IMPORT',
                  style: DashText.sectionLabel(size: 10)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Paste the model's output here to create the course directly.",
            style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: state._pasted,
            minLines: 4,
            maxLines: 10,
            style: const TextStyle(
                fontSize: 12, fontFamily: 'monospace', color: Colors.white),
            decoration: InputDecoration(
              hintText: '=== course.txt ===\nname: …',
              hintStyle: TextStyle(fontSize: 12, color: DashColors.w(0.30)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.28),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: DashRadii.input,
                borderSide: BorderSide(color: DashColors.w(0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: DashRadii.input,
                borderSide: BorderSide(color: DashColors.w(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: DashRadii.input,
                borderSide:
                    BorderSide(color: DashColors.brand.withValues(alpha: 0.55)),
              ),
            ),
          ),
          if (state._importError != null) ...[
            const SizedBox(height: 8),
            Text(
              'Import failed — ${state._importError}',
              style: const TextStyle(fontSize: 12, color: DashColors.red400),
            ),
          ],
          const SizedBox(height: 10),
          PrimaryButton(
            label: state._importing ? 'Importing…' : 'Import course',
            leading: Icons.download_done_outlined,
            onTap: state._importing ? null : state._importPasted,
          ),
        ],
      ),
    );
  }
}

// ── Small form widgets ──────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);
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

class _CourseField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final VoidCallback onChanged;
  const _CourseField({
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

class _Segment extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _Segment({
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

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper({
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
        _RoundStep(
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
        _RoundStep(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _RoundStep extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundStep({required this.icon, required this.onTap});

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

class _TypeChip extends StatelessWidget {
  final _ExerciseType type;
  final bool selected;
  final VoidCallback? onTap;
  const _TypeChip({required this.type, required this.selected, required this.onTap});

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

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _SwitchRow({
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
