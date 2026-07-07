import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../theme.dart';
import '../widgets/ai_prompt_controls.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';
import '../widgets/terms_gate.dart';

/// "Create with AI — step by step" — the incremental variant of
/// create_course_page.dart (see MVP.md's "Build in steps" checklist under
/// mvp-phase-4-create-with-ai): plan the course's vocabulary first, then
/// author it module by module using that vocabulary, previewing at each
/// stage. Still Phase 1 (copy a prompt into any LLM, paste the result
/// back) — nothing is sent to the server until the final "Import course".
class CreateCourseStepsPage extends ConsumerStatefulWidget {
  const CreateCourseStepsPage({super.key});

  @override
  ConsumerState<CreateCourseStepsPage> createState() =>
      _CreateCourseStepsPageState();
}

/// One parsed module from the Step 1 word-list response.
class _ModuleWords {
  final String title;
  final List<String> words;
  const _ModuleWords({required this.title, required this.words});
}

/// Parses `=== Module N: title ===` headers followed by one word/phrase
/// per line (blank lines ignored). A module with no words between its
/// header and the next is kept with an empty list rather than dropped,
/// so the preview can flag it.
List<_ModuleWords> _parseModuleWords(String text) {
  final headerRe = RegExp(
    r'^===\s*Module\s+(\d+)\s*[:.]?\s*(.*?)\s*===\s*$',
    multiLine: true,
  );
  final matches = headerRe.allMatches(text).toList();
  final modules = <_ModuleWords>[];
  for (var i = 0; i < matches.length; i++) {
    final m = matches[i];
    final start = m.end;
    final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    final words = text
        .substring(start, end)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final rawTitle = m.group(2)?.trim() ?? '';
    modules.add(_ModuleWords(
      title: rawTitle.isNotEmpty ? rawTitle : 'Module ${m.group(1)}',
      words: words,
    ));
  }
  return modules;
}

class _CreateCourseStepsPageState
    extends ConsumerState<CreateCourseStepsPage> {
  // Course basics — same fields/defaults as CreateCoursePage.
  final _title = TextEditingController();
  final _language = TextEditingController(text: 'Japanese');
  final _studentLanguage = TextEditingController(text: 'Hebrew');
  final _topic = TextEditingController(
      text: 'Everyday conversation for absolute beginners');
  String _level = 'A1';
  int _modules = 4;
  int _lessonsPerModule = 5;
  int _exercisesPerLesson = 8;
  int _minWordsPerSentence = 3;
  int _maxWordsPerSentence = 10;
  final Set<String> _types = {
    'single_choice',
    'multiple_choice',
    'annotated_sentence',
    'words_in_sentence',
  };
  bool _audio = false;
  bool _ruby = false;
  final _extraInstructions = TextEditingController();

  // Step 1 — vocabulary.
  int _wordsPerModule = 20;
  bool _includeNames = false;
  final _wordsPasted = TextEditingController();
  List<_ModuleWords>? _parsedWords;
  String? _parseError;

  // Step 2 — per-module generation.
  int _currentStep = 0;
  final Map<int, TextEditingController> _moduleControllers = {};
  final Map<int, String> _moduleResults = {};

  // Final import.
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
    _wordsPasted.dispose();
    for (final c in _moduleControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void apply(VoidCallback fn) => setState(fn);

  bool get _isJapanese {
    final l = _language.text.trim().toLowerCase();
    return l == 'ja' || l == 'japanese' || l.contains('日本');
  }

  int get _totalExercises =>
      _modules * _lessonsPerModule * _exercisesPerLesson;

  TextEditingController _moduleController(int i) =>
      _moduleControllers.putIfAbsent(i, () => TextEditingController());

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1600),
        content: Text(message),
      ));
  }

  // ── Step 1: vocabulary ──────────────────────────────────────────────

  String _buildWordsPrompt() {
    final names = _includeNames
        ? '\n- Some vocabulary items are character names used in example '
            'dialogues. Suggest names as a mix of about 70% names native to '
            '${_language.text.trim()}\'s culture and 30% common/'
            'international names, so dialogues feel authentic but still '
            'approachable.'
        : '';
    final extra = _extraInstructions.text.trim();
    return '''You are a language-course vocabulary planner. Suggest the core vocabulary for a course, split by module.

Course:
- Title: ${_title.text.trim()}
- Teaches: ${_language.text.trim()}
- For students who speak: ${_studentLanguage.text.trim()}
- CEFR level: $_level
- Focus: ${_topic.text.trim()}
- $_modules modules, ~$_wordsPerModule words or short phrases per module.$names
${extra.isEmpty ? '' : '\nAdditional instructions from the editor:\n$extra\n'}
OUTPUT FORMAT — plain text, no markdown, no commentary, exactly like this:

=== Module 1: <short module theme> ===
<word or short phrase>
<word or short phrase>
... (~$_wordsPerModule words)

=== Module 2: <short module theme> ===
...

Repeat for all $_modules modules, numbered in order. Keep words/phrases relevant to each module's theme and level-appropriate. Avoid duplicates across modules.''';
  }

  void _copyWordsPrompt() {
    Clipboard.setData(ClipboardData(text: _buildWordsPrompt()));
    _toast('Prompt copied — paste it into your LLM.');
  }

  void _parseWords() {
    final parsed = _parseModuleWords(_wordsPasted.text);
    setState(() {
      if (parsed.isEmpty) {
        _parseError = 'No "=== Module N: ... ===" sections found.';
        _parsedWords = null;
      } else {
        _parseError = null;
        _parsedWords = parsed;
      }
    });
  }

  void _goToModules() {
    if (_parsedWords == null || _parsedWords!.isEmpty) return;
    setState(() => _currentStep = 1);
  }

  // ── Step 2: modules ─────────────────────────────────────────────────

  String _buildModulePrompt(int index) {
    final module = _parsedWords![index];
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
    return '''You are an expert language-course author. Write ONE module of a course as YAML sections for our import format — not the whole course.

Course: ${_title.text.trim()} (${_language.text.trim()} for ${_studentLanguage.text.trim()} speakers, level $_level, focus: ${_topic.text.trim()}).
This is module ${index + 1} of ${_parsedWords!.length}: "${module.title}".
Vocabulary to build exercises around (use these naturally across the lessons): ${module.words.join(', ')}
- $_lessonsPerModule lessons, ~$_exercisesPerLesson exercises per lesson.
- Sentence length: every exercise sentence should be $_minWordsPerSentence to $_maxWordsPerSentence words long.
${enrich.isEmpty ? '' : '- $enrich\n'}${extra.isEmpty ? '' : '\nAdditional instructions from the editor:\n$extra\n'}
OUTPUT — return ONLY this module's sections: no "type: course" section, no other modules, no markdown fences, no commentary. Flat sections separated by a line containing only "---", nesting implied by order:

type: module
title: ${module.title}
weight: ${index + 1}
---
type: lesson
title: <lesson 1 title>
weight: 1
---
$examples

Exercise types to use (vary them across lessons):
${selected.isEmpty ? '- any of the types shown above' : selected.map((t) => '- ${t.key}: ${t.hint}').join('\n')}

Rules:
- Every lesson needs at least one exercise.
- weight controls order — number sequentially from 1 within each lesson/module.
- Keep it natural and level-appropriate; avoid duplicate sentences.
- Use the vocabulary list above across the module's exercises.''';
  }

  void _copyModulePrompt(int i) {
    Clipboard.setData(ClipboardData(text: _buildModulePrompt(i)));
    _toast('Prompt copied — paste it into your LLM.');
  }

  void _saveModule(int i) {
    final text = _moduleController(i).text.trim();
    if (text.isEmpty) return;
    setState(() => _moduleResults[i] = text);
    _toast('Module ${i + 1} saved.');
  }

  // ── Preview & import ────────────────────────────────────────────────

  String get _courseHeader => '''type: course
title: ${_title.text.trim()}
description: ${_topic.text.trim()}
lang: ${_language.text.trim()}
to_lang: ${_studentLanguage.text.trim()}
level: $_level''';

  int get _doneModuleCount => _moduleResults.length;

  /// The full document to import, or null if no module has been saved yet.
  String? _assembleDocument() {
    if (_parsedWords == null) return null;
    final parts = <String>[_courseHeader];
    for (var i = 0; i < _parsedWords!.length; i++) {
      final r = _moduleResults[i];
      if (r != null && r.isNotEmpty) parts.add(r);
    }
    if (parts.length < 2) return null;
    return parts.join('\n---\n');
  }

  Future<void> _importAssembled() async {
    final doc = _assembleDocument();
    if (doc == null || _importing) return;
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

  @override
  Widget build(BuildContext context) {
    final needsTerms = ref.watch(meProvider).value?.needsTerms ?? false;
    return DashboardShell(
      title: 'Create with AI — steps',
      activeRoute: '/create-course-steps',
      topbarTrailing: needsTerms
          ? const []
          : [
              GhostButton(
                label: 'Single prompt',
                leading: Icons.auto_awesome_outlined,
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/create-course'),
              ),
            ],
      child: needsTerms
          ? const TermsGate(
              explanation:
                  'Accepting the editor terms is required before you can add '
                  'content. Review and accept below to start creating courses.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Segment(
                  options: const ['1. Words', '2. Modules'],
                  selected: _currentStep == 0 ? '1. Words' : '2. Modules',
                  onSelect: (v) {
                    if (v == '2. Modules' &&
                        (_parsedWords == null || _parsedWords!.isEmpty)) {
                      _toast('Parse a word list in Step 1 first.');
                      return;
                    }
                    setState(() => _currentStep = v == '1. Words' ? 0 : 1);
                  },
                ),
                const SizedBox(height: 16),
                if (_currentStep == 0)
                  _WordsStep(state: this)
                else
                  _ModulesStep(state: this),
              ],
            ),
    );
  }
}

class _WordsStep extends StatelessWidget {
  final _CreateCourseStepsPageState state;
  const _WordsStep({required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 900;
      final form = _WordsForm(state: state);
      final preview = _WordsPromptPanel(state: state);
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
    });
  }
}

class _WordsForm extends StatelessWidget {
  final _CreateCourseStepsPageState state;
  const _WordsForm({required this.state});

  @override
  Widget build(BuildContext context) {
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
                    child: LanguageField(
                      controller: state._language,
                      label: 'Teaches (language)',
                      hint: 'Japanese or ja',
                      onChanged: rebuild,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LanguageField(
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
                options: _CreateCourseStepsPageState._levels,
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
              const GroupLabel('Vocabulary'),
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
                label: 'Words / module',
                value: state._wordsPerModule,
                min: 5,
                max: 60,
                onChanged: (v) => state.apply(() => state._wordsPerModule = v),
              ),
              const SizedBox(height: 6),
              SwitchRow(
                title: 'Include character names',
                subtitle: '70% names native to the target language, '
                    '30% common/international — for dialogue exercises.',
                value: state._includeNames,
                onChanged: (v) => state.apply(() => state._includeNames = v),
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
                'Optional — folded into both the words prompt and every '
                'module prompt in Step 2.',
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

class _WordsPromptPanel extends StatelessWidget {
  final _CreateCourseStepsPageState state;
  const _WordsPromptPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final prompt = state._buildWordsPrompt();
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: GroupLabel('Vocabulary prompt')),
              GhostButton(
                label: 'Copy',
                leading: Icons.copy_all_outlined,
                onTap: state._copyWordsPrompt,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Run this in any LLM, then paste its output below.',
            style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
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
            onTap: state._copyWordsPrompt,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.content_paste_go_outlined,
                  size: 15, color: DashColors.w(0.6)),
              const SizedBox(width: 8),
              Text('PASTE WORD LIST', style: DashText.sectionLabel(size: 10)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: state._wordsPasted,
            minLines: 4,
            maxLines: 10,
            style: const TextStyle(
                fontSize: 12, fontFamily: 'monospace', color: Colors.white),
            decoration: InputDecoration(
              hintText: '=== Module 1: … ===\nword\nword…',
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
          const SizedBox(height: 10),
          GhostButton(
            label: 'Parse & preview',
            leading: Icons.visibility_outlined,
            onTap: state._parseWords,
          ),
          if (state._parseError != null) ...[
            const SizedBox(height: 8),
            Text(
              state._parseError!,
              style: const TextStyle(fontSize: 12, color: DashColors.red400),
            ),
          ],
          if (state._parsedWords != null) ...[
            const SizedBox(height: 12),
            for (final m in state._parsedWords!) ...[
              _ModuleWordsPreview(module: m),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Continue to modules',
              leading: Icons.arrow_forward,
              onTap: state._goToModules,
            ),
          ],
        ],
      ),
    );
  }
}

class _ModuleWordsPreview extends StatelessWidget {
  final _ModuleWords module;
  const _ModuleWordsPreview({required this.module});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${module.words.length} words',
                style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
              ),
            ],
          ),
          if (module.words.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'No words parsed for this module.',
              style: TextStyle(fontSize: 12, color: DashColors.red400),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final w in module.words)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DashColors.w(0.06),
                      borderRadius: DashRadii.pill,
                      border: Border.all(color: DashColors.w(0.14)),
                    ),
                    child: Text(
                      w,
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ModulesStep extends StatelessWidget {
  final _CreateCourseStepsPageState state;
  const _ModulesStep({required this.state});

  @override
  Widget build(BuildContext context) {
    final modules = state._parsedWords ?? const <_ModuleWords>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GroupLabel('Structure & exercise mix'),
              Text(
                'Applied to every module\'s prompt below.',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: DashColors.brand.withValues(alpha: 0.10),
                  borderRadius: DashRadii.input,
                  border: Border.all(
                      color: DashColors.brand.withValues(alpha: 0.30)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.functions, size: 16, color: DashColors.w(0.75)),
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
              const SizedBox(height: 8),
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
        const SizedBox(height: 16),
        for (var i = 0; i < modules.length; i++) ...[
          _ModuleCard(state: state, index: i, module: modules[i]),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        _PreviewAndImportPanel(state: state),
      ],
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final _CreateCourseStepsPageState state;
  final int index;
  final _ModuleWords module;
  const _ModuleCard(
      {required this.state, required this.index, required this.module});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final i = widget.index;
    final done = state._moduleResults.containsKey(i);
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: DashRadii.card,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Icon(_open ? Icons.expand_more : Icons.chevron_right,
                      size: 18, color: DashColors.w(0.55)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Module ${i + 1}: ${widget.module.title}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  StatusPill(
                    label: done ? 'Done' : 'Pending',
                    kind: done ? PillKind.active : PillKind.muted,
                    swatch: true,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            Divider(color: DashColors.w(0.08), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final w in widget.module.words)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: DashColors.w(0.06),
                            borderRadius: DashRadii.pill,
                            border: Border.all(color: DashColors.w(0.14)),
                          ),
                          child: Text(w,
                              style: const TextStyle(
                                  fontSize: 11.5, color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GhostButton(
                        label: 'Copy prompt',
                        leading: Icons.copy_all_outlined,
                        onTap: () => state._copyModulePrompt(i),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: DashRadii.input,
                      border: Border.all(color: DashColors.w(0.10)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        state._buildModulePrompt(i),
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          fontFamily: 'monospace',
                          color: DashColors.w(0.85),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: state._moduleController(i),
                    minLines: 3,
                    maxLines: 8,
                    style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'type: module\ntitle: …',
                      hintStyle:
                          TextStyle(fontSize: 12, color: DashColors.w(0.30)),
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
                        borderSide: BorderSide(
                            color: DashColors.brand.withValues(alpha: 0.55)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: done ? 'Save module (update)' : 'Save module',
                    leading: Icons.check_circle_outline,
                    onTap: () => state._saveModule(i),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewAndImportPanel extends StatelessWidget {
  final _CreateCourseStepsPageState state;
  const _PreviewAndImportPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final doc = state._assembleDocument();
    final total = state._parsedWords?.length ?? 0;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GroupLabel('Preview & import'),
          const SizedBox(height: 6),
          Text(
            '${state._doneModuleCount} / $total modules saved.',
            style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: DashRadii.input,
              border: Border.all(color: DashColors.w(0.10)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                doc ?? 'Save at least one module to preview the assembled '
                    'course document.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontFamily: 'monospace',
                  color: DashColors.w(0.85),
                ),
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
          const SizedBox(height: 12),
          PrimaryButton(
            label: state._importing ? 'Importing…' : 'Import course',
            leading: Icons.download_done_outlined,
            onTap: (doc == null || state._importing)
                ? null
                : state._importAssembled,
          ),
        ],
      ),
    );
  }
}
