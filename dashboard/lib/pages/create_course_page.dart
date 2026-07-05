import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../theme.dart';
import '../widgets/ai_prompt_controls.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';
import '../widgets/terms_gate.dart';

/// "Create with AI" — collects the shape of a course an editor wants and
/// assembles a ready-to-run LLM prompt that targets our import format (see
/// content/example_course.yaml). Phase 1 (this page): build + copy the
/// prompt, run it in any LLM, then upload the result on the Courses page.
/// Phase 2 (not built): a backend `/editor/ai/generate` that runs the LLM
/// and enrichment server-side. See CREATE_COURSE_WITH_AI.md.
///
/// See also create_course_steps_page.dart — the step-by-step variant
/// (words first, then module by module) that shares the exercise-type
/// catalogue and form controls from widgets/ai_prompt_controls.dart.
class CreateCoursePage extends ConsumerStatefulWidget {
  const CreateCoursePage({super.key});

  @override
  ConsumerState<CreateCoursePage> createState() => _CreateCoursePageState();
}

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

  // Sentence length guidance, passed to the LLM per module.
  int _minWordsPerSentence = 3;
  int _maxWordsPerSentence = 10;

  // Selected exercise-type keys.
  final Set<String> _types = {
    'single_choice',
    'multiple_choice',
    'annotated_sentence',
    'words_in_sentence',
  };

  bool _audio = false;
  bool _ruby = false;

  // Free-text instructions folded into the prompt as-is.
  final _extraInstructions = TextEditingController();

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
    _extraInstructions.dispose();
    _pasted.dispose();
    super.dispose();
  }

  /// Import the pasted YAML document via the server text-import endpoint,
  /// then jump to the new course's detail page.
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

  /// Assemble the LLM prompt from the current form state. Embeds the
  /// content/example_course.yaml shape so the model returns text the
  /// import endpoint (POST /api/v1/edit/course/import/) can parse as-is.
  String _buildPrompt() {
    final selected =
        kExerciseTypes.where((t) => _types.contains(t.key)).toList();
    final examples = (selected.isEmpty ? kExerciseTypes : selected)
        .map((t) => exerciseTypeExample(
              t.key,
              lang: _language.text.trim(),
              studentLang: _studentLanguage.text.trim(),
            ))
        .join('\n---\n');

    final enrich = <String>[
      if (_audio)
        'Audio will be generated separately by the platform — do not include audio fields.',
      if (_ruby && _isJapanese)
        'Japanese furigana (ruby) is added by the platform after import — write plain Japanese only.',
    ].join(' ');

    final extra = _extraInstructions.text.trim();

    return '''You are an expert language-course author. Write a complete course as a single YAML document for our import format.

Course to create:
- Title: ${_title.text.trim()}
- Teaches: ${_language.text.trim()}
- For students who speak: ${_studentLanguage.text.trim()}
- CEFR level: $_level
- Focus: ${_topic.text.trim()}
- Size: $_modules modules, $_lessonsPerModule lessons per module, ~$_exercisesPerLesson exercises per lesson.
- Sentence length: every exercise sentence should be $_minWordsPerSentence to $_maxWordsPerSentence words long, in every module.
${enrich.isEmpty ? '' : '- $enrich\n'}${extra.isEmpty ? '' : '\nAdditional instructions from the editor:\n$extra\n'}
OUTPUT FORMAT — return ONE YAML document, no markdown fences, no commentary.
It is a flat sequence of sections separated by a line containing only "---".
Each section starts with a "type" key: course, module, lesson, or exercise.
Nesting is implied by ORDER, not indentation: every module/lesson/exercise
section belongs to the most recent section of the next-higher type above it
— so a module's lessons (and their exercises) must all appear, in order,
before the next module section starts.

type: course
title: <course title>
description: <one-line blurb>
lang: ${_language.text.trim()}
to_lang: ${_studentLanguage.text.trim()}
level: $_level
---
type: module
title: <module 1 title>
weight: 1
---
type: lesson
title: <lesson 1 title>
weight: 1
---
$examples

Exercise types to use (vary them across lessons):
${selected.isEmpty ? '- any of the types shown above' : selected.map((t) => '- ${t.key}: ${t.hint}').join('\n')}

Rules:
- Every module needs at least one lesson; every lesson needs at least one exercise.
- weight controls order within the parent (module order, lesson order, exercise order) — number sequentially from 1.
- Keep it natural and level-appropriate; avoid duplicate sentences.
- Produce $_modules modules, $_lessonsPerModule lessons per module, and ~$_exercisesPerLesson exercises per lesson.''';
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
    // Create with AI is always reachable, but authoring content requires
    // accepting the editor Terms & Conditions first. When unsigned the server
    // reports permissions['signed_terms'] == true and we replace the builder
    // with the terms gate (and drop the "Upload result" CTA).
    final needsTerms = ref.watch(meProvider).value?.needsTerms ?? false;
    return DashboardShell(
      title: 'Create with AI',
      activeRoute: '/create-course',
      topbarTrailing: needsTerms
          ? const []
          : [
              GhostButton(
                label: 'Upload result',
                leading: Icons.file_upload_outlined,
                onTap: () => Navigator.pushReplacementNamed(context, '/courses'),
              ),
            ],
      child: needsTerms
          ? const TermsGate(
              explanation:
                  'Accepting the editor terms is required before you can add '
                  'content. Review and accept below to start creating courses.',
            )
          : LayoutBuilder(
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
              const GroupLabel('Basics'),
              const SizedBox(height: 12),
              CourseField(
                controller: state._title,
                label: 'Course title',
                onChanged: rebuild,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CourseField(
                      controller: state._language,
                      label: 'Teaches (language)',
                      hint: 'Japanese or ja',
                      onChanged: rebuild,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CourseField(
                      controller: state._studentLanguage,
                      label: 'Student speaks',
                      hint: 'Hebrew or he',
                      onChanged: rebuild,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CourseField(
                controller: state._topic,
                label: 'Topic / focus',
                hint: 'e.g. travel, greetings, business',
                onChanged: rebuild,
              ),
              const SizedBox(height: 16),
              Text('LEVEL', style: DashText.sectionLabel(size: 10)),
              const SizedBox(height: 6),
              Segment(
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
              const GroupLabel('Structure'),
              const SizedBox(height: 12),
              NumberStepper(
                label: 'Modules',
                value: state._modules,
                min: 1,
                max: 20,
                onChanged: (v) => state.apply(() => state._modules = v),
              ),
              const SizedBox(height: 10),
              NumberStepper(
                label: 'Lessons / module',
                value: state._lessonsPerModule,
                min: 1,
                max: 20,
                onChanged: (v) =>
                    state.apply(() => state._lessonsPerModule = v),
              ),
              const SizedBox(height: 10),
              NumberStepper(
                label: 'Exercises / lesson',
                value: state._exercisesPerLesson,
                min: 1,
                max: 30,
                onChanged: (v) =>
                    state.apply(() => state._exercisesPerLesson = v),
              ),
              const SizedBox(height: 10),
              NumberStepper(
                label: 'Min words / sentence',
                value: state._minWordsPerSentence,
                min: 1,
                max: state._maxWordsPerSentence,
                onChanged: (v) =>
                    state.apply(() => state._minWordsPerSentence = v),
              ),
              const SizedBox(height: 10),
              NumberStepper(
                label: 'Max words / sentence',
                value: state._maxWordsPerSentence,
                min: state._minWordsPerSentence,
                max: 40,
                onChanged: (v) =>
                    state.apply(() => state._maxWordsPerSentence = v),
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
              const GroupLabel('Exercise mix'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in kExerciseTypes)
                    TypeChip(
                      type: t,
                      selected: state._types.contains(t.key),
                      onTap: () => state.apply(() {
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
              const GroupLabel('Enrichment'),
              const SizedBox(height: 6),
              SwitchRow(
                title: 'Generate audio',
                subtitle: 'Synthesise a recording per sentence (Azure / Google).',
                value: state._audio,
                onChanged: (v) => state.apply(() => state._audio = v),
              ),
              SwitchRow(
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
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GroupLabel('Additional instructions'),
              const SizedBox(height: 6),
              Text(
                'Optional — folded into the prompt as-is (tone, topics to '
                'avoid, specific vocabulary, etc.).',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: state._extraInstructions,
                minLines: 2,
                maxLines: 6,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                onChanged: (_) => rebuild(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText:
                      'e.g. focus on restaurant vocabulary, avoid slang…',
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
                    borderSide: BorderSide(
                        color: DashColors.brand.withValues(alpha: 0.55)),
                  ),
                ),
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
              const Expanded(child: GroupLabel('AI prompt')),
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

/// Paste the LLM's YAML output and import it straight into the catalogue
/// via the server text-import endpoint.
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
              hintText: 'type: course\ntitle: …',
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

