import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../theme.dart';
import '../widgets/ai_prompt_controls.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';
import '../widgets/terms_gate.dart';

/// "Create from subtitles" — MVP.md's "build on movie subtitles" phase.
/// Paste a movie/show's .srt file, and the dashboard builds a prompt that
/// embeds the dialogue lines so an LLM can translate/select/vary them into
/// exercises in our import format. Same Phase 1 pattern as
/// create_course_page.dart (copy prompt → any LLM → paste result → import)
/// — no server-side translation or YouTube integration.
class CreateFromSubtitlesPage extends ConsumerStatefulWidget {
  const CreateFromSubtitlesPage({super.key});

  @override
  ConsumerState<CreateFromSubtitlesPage> createState() =>
      _CreateFromSubtitlesPageState();
}

/// One dialogue line extracted from an .srt block, plus its timing (start
/// and end, in seconds) — carried through to the prompt so the LLM can
/// stamp lessons/exercises with the start_second/end_second of the
/// dialogue they're built from. Null when the timing line couldn't be
/// parsed (malformed input); the prompt falls back to "?" for that line.
class SrtLine {
  final String text;
  final double? startSeconds;
  final double? endSeconds;
  const SrtLine(this.text, {this.startSeconds, this.endSeconds});
}

bool _isJunkCaption(String s) {
  final t = s.trim();
  if (t.isEmpty) return true;
  // Sound-effect / music captions like "[music playing]" or "(door creaks)".
  return (t.startsWith('[') && t.endsWith(']')) ||
      (t.startsWith('(') && t.endsWith(')'));
}

/// Parses one side of a "-->" timing line into seconds. Accepts standard
/// .srt timecodes ("00:02:16,612" or "00:02:16.612") as well as the plain
/// decimal-seconds format some transcript tools emit ("16.612"). Returns
/// null if it doesn't look like either.
double? _parseSrtTimestamp(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  if (!s.contains(':')) return double.tryParse(s.replaceAll(',', '.'));
  final parts = s.split(':');
  if (parts.length < 2) return null;
  final lastSeconds = double.tryParse(parts.removeLast().replaceAll(',', '.'));
  if (lastSeconds == null) return null;
  var total = lastSeconds;
  var multiplier = 60.0;
  for (var i = parts.length - 1; i >= 0; i--) {
    final v = double.tryParse(parts[i]);
    if (v == null) return null;
    total += v * multiplier;
    multiplier *= 60;
  }
  return total;
}

/// Parses a .srt file's dialogue text, dropping block indices, sound-effect
/// captions, and immediate consecutive duplicates (common in karaoke-style
/// caption tracks). Multi-line dialogue within a single subtitle block is
/// joined with a space; the block's timing line (if present) is kept as
/// each line's start/end seconds.
List<SrtLine> parseSrt(String raw) {
  final blocks = raw.split(RegExp(r'\n\s*\n'));
  final lines = <SrtLine>[];
  String? prev;
  for (final block in blocks) {
    final blockLines = block
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (blockLines.isEmpty) continue;
    var start = 0;
    if (RegExp(r'^\d+$').hasMatch(blockLines[start])) start++;
    double? startSeconds;
    double? endSeconds;
    if (start < blockLines.length && blockLines[start].contains('-->')) {
      final timing = blockLines[start].split('-->');
      if (timing.length == 2) {
        startSeconds = _parseSrtTimestamp(timing[0]);
        endSeconds = _parseSrtTimestamp(timing[1]);
      }
      start++;
    }
    if (start >= blockLines.length) continue;
    final text = blockLines.sublist(start).join(' ').trim();
    if (_isJunkCaption(text) || text == prev) continue;
    lines.add(SrtLine(text, startSeconds: startSeconds, endSeconds: endSeconds));
    prev = text;
  }
  return lines;
}

class _CreateFromSubtitlesPageState
    extends ConsumerState<CreateFromSubtitlesPage> {
  // Source.
  final _source = TextEditingController(text: 'Attack of the Clones');
  final _language = TextEditingController(text: 'English');
  final _studentLanguage = TextEditingController(text: 'Hebrew');
  String _level = 'A1';

  // Subtitles input.
  final _srtPasted = TextEditingController();
  List<SrtLine>? _parsedLines;
  String? _parseError;

  // Generation controls.
  int _linesPerLesson = 12;
  int _sentencesPerWord = 2;
  final Set<String> _types = {
    'single_choice',
    'multiple_choice',
    'annotated_sentence',
    'words_in_sentence',
  };
  bool _audio = false;
  bool _ruby = false;
  final _extraInstructions = TextEditingController();

  // Paste-and-import.
  final _pasted = TextEditingController();
  bool _importing = false;
  String? _importError;

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  @override
  void dispose() {
    _source.dispose();
    _language.dispose();
    _studentLanguage.dispose();
    _srtPasted.dispose();
    _extraInstructions.dispose();
    _pasted.dispose();
    super.dispose();
  }

  void apply(VoidCallback fn) => setState(fn);

  /// Lessons the prompt will ask the LLM to produce — all parsed dialogue
  /// lines, grouped [_linesPerLesson] at a time. Stated explicitly in the
  /// prompt so the LLM produces the same fixed count of "type: lesson"
  /// sections the other Create-with-AI pages ask for, instead of inferring
  /// it from a "group every ~N lines" hint alone.
  int get _lessonCount {
    final used = _parsedLines?.length ?? 0;
    if (used == 0) return 0;
    return (used + _linesPerLesson - 1) ~/ _linesPerLesson;
  }

  bool get _isJapanese {
    final l = _language.text.trim().toLowerCase();
    return l == 'ja' || l == 'japanese' || l.contains('日本');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1600),
        content: Text(message),
      ));
  }

  void _parseSubtitles() {
    final parsed = parseSrt(_srtPasted.text);
    setState(() {
      if (parsed.isEmpty) {
        _parseError = 'No dialogue lines found — check the pasted .srt text.';
        _parsedLines = null;
      } else {
        _parseError = null;
        _parsedLines = parsed;
      }
    });
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

  /// Assemble the LLM prompt: course settings + the full subtitle excerpt
  /// + the same exercise-type/output-format spec the other Create-with-AI
  /// pages embed.
  String _buildPrompt() {
    final used = _parsedLines ?? const <SrtLine>[];
    String fmtSec(double? v) => v == null ? '?' : v.toStringAsFixed(2);
    final excerpt = [
      for (var i = 0; i < used.length; i++)
        '${i + 1}. [${fmtSec(used[i].startSeconds)}-${fmtSec(used[i].endSeconds)}] ${used[i].text}',
    ].join('\n');

    final selected =
        kExerciseTypes.where((t) => _types.contains(t.key)).toList();
    // Same per-type field examples the other Create-with-AI pages show,
    // plus start_second/end_second — meaningful here (and only here)
    // because these prompts carry real .srt timestamps per dialogue line.
    final examples = (selected.isEmpty ? kExerciseTypes : selected)
        .map((t) => '${exerciseTypeExample(
              t.key,
              lang: _language.text.trim(),
              studentLang: _studentLanguage.text.trim(),
            )}\n'
            'start_second: <start time of the underlying dialogue line(s), in seconds>\n'
            'end_second: <end time of the underlying dialogue line(s), in seconds>')
        .join('\n---\n');

    final enrich = <String>[
      if (_audio)
        'Audio will be generated separately by the platform — do not include audio fields.',
      if (_ruby && _isJapanese)
        'Japanese furigana (ruby) is added by the platform after import — write plain Japanese only.',
    ].join(' ');

    final extra = _extraInstructions.text.trim();

    return '''You are an expert language-course author. Turn a movie's dialogue lines into a complete course as a single YAML document for our import format.

Source: "${_source.text.trim()}" (dialogue lines below, in order).
Course to create:
- Teaches: ${_language.text.trim()}
- For students who speak: ${_studentLanguage.text.trim()}
- CEFR level: $_level
- Produce exactly $_lessonCount lessons in the module, each covering ~$_linesPerLesson consecutive dialogue lines, in the order given.
- Vocabulary: from the dialogue lines, pick out the less common words or phrases (skip basic/high-frequency vocabulary) — these are the course's key vocabulary.
- For each key vocabulary word, include one quiz exercise (single_choice or multiple_choice) testing its meaning, plus at least $_sentencesPerWord other example sentences using it elsewhere in the course.
- Generate exercises from the existing dialogue lines rather than inventing unrelated sentences.
- Long dialogue lines may be simplified and shortened for an exercise sentence, as long as the meaning and key vocabulary are preserved.
- For sentences that contain difficult words, use the annotated_sentence exercise type and annotate those words (meaning/short note) instead of a plain single_choice/multiple_choice exercise.
- Every lesson and exercise section must include start_second and end_second (seconds) taken from the timestamps shown on the dialogue lines below.
${enrich.isEmpty ? '' : '- $enrich\n'}${extra.isEmpty ? '' : '\nAdditional instructions from the editor:\n$extra\n'}
Dialogue lines to use, each prefixed with its "[start-end]" timing in seconds (translate each into ${_studentLanguage.text.trim()} as needed; skip lines that don't make good exercises rather than forcing them):
$excerpt

OUTPUT FORMAT — return ONE YAML document, no markdown fences, no commentary.
It is a flat sequence of sections separated by a line containing only "---".
Each section starts with a "type" key: course, module, lesson, or exercise.
Nesting is implied by ORDER, not indentation: every module/lesson/exercise
section belongs to the most recent section of the next-higher type above it
— so a module's lessons (and their exercises) must all appear, in order,
before the next module section starts.

type: course
title: ${_source.text.trim()}
description: <one-line blurb>
lang: ${_language.text.trim()}
to_lang: ${_studentLanguage.text.trim()}
level: $_level
---
type: module
title: ${_source.text.trim()}
weight: 1
---
type: lesson
title: <lesson 1 title>
weight: 1
start_second: <start time of this lesson's first dialogue line, in seconds>
end_second: <end time of this lesson's last dialogue line, in seconds>
---
$examples

Exercise types to use (vary them across lessons):
${selected.isEmpty ? '- any of the types shown above' : selected.map((t) => '- ${t.key}: ${t.hint}').join('\n')}

Rules:
- Every lesson needs at least one exercise.
- weight controls order within the parent — number sequentially from 1.
- Use the dialogue lines as the basis for exercise sentences (translated), in order; simplify or shorten long ones, and keep it natural and level-appropriate.
- One module only, named after the source.
- Produce exactly $_lessonCount lesson sections in that module, weight 1 to $_lessonCount, in dialogue order.
- Each key vocabulary word's meaning quiz is a single_choice or multiple_choice exercise (see the format above) whose sentence field asks for the word's meaning and whose options are candidate meanings, one correct.
- A lesson's start_second is its first dialogue line's start time and end_second is its last dialogue line's end time. An exercise's start_second/end_second match the dialogue line(s) it was built from; for an invented vocabulary-quiz or extra example sentence, use the start_second/end_second of the dialogue line containing that word.''';
  }

  void _copyPrompt() {
    Clipboard.setData(ClipboardData(text: _buildPrompt()));
    _toast('Prompt copied — paste it into your LLM.');
  }

  @override
  Widget build(BuildContext context) {
    final needsTerms = ref.watch(meProvider).value?.needsTerms ?? false;
    return DashboardShell(
      title: 'Video Courses',
      activeRoute: '/create-from-subtitles',
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
                final form = _SourceForm(state: this);
                final preview = _PromptPanel(state: this);
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

class _SourceForm extends StatelessWidget {
  final _CreateFromSubtitlesPageState state;
  const _SourceForm({required this.state});

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
              const GroupLabel('Source'),
              const SizedBox(height: 12),
              CourseField(
                controller: state._source,
                label: 'Movie / show title',
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
              const SizedBox(height: 16),
              Text('LEVEL', style: DashText.sectionLabel(size: 10)),
              const SizedBox(height: 6),
              Segment(
                options: _CreateFromSubtitlesPageState._levels,
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
              const GroupLabel('Subtitles'),
              const SizedBox(height: 6),
              Text(
                'Paste the movie\'s .srt file contents.',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: state._srtPasted,
                minLines: 4,
                maxLines: 10,
                style: const TextStyle(
                    fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                // Parse as soon as text lands (paste or keystroke) so the
                // prompt preview on the right updates live — matching the
                // other Create-with-AI pages, instead of leaving the prompt
                // panel on its placeholder until "Parse subtitles" is
                // clicked separately.
                onChanged: (_) => state._parseSubtitles(),
                decoration: InputDecoration(
                  hintText: '1\n00:02:16,612 --> 00:02:19,376\nDialogue line…',
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
                    borderSide: BorderSide(
                        color: DashColors.brand.withValues(alpha: 0.55)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GhostButton(
                label: 'Parse subtitles',
                leading: Icons.subtitles_outlined,
                onTap: state._parseSubtitles,
              ),
              if (state._parseError != null) ...[
                const SizedBox(height: 8),
                Text(
                  state._parseError!,
                  style: const TextStyle(fontSize: 12, color: DashColors.red400),
                ),
              ],
              if (state._parsedLines != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${state._parsedLines!.length} dialogue lines parsed.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DashColors.w(0.75),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DashColors.w(0.04),
                    borderRadius: DashRadii.input,
                    border: Border.all(color: DashColors.w(0.10)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      state._parsedLines!
                          .take(15)
                          .map((l) => '• ${l.text}')
                          .join('\n'),
                      style: TextStyle(fontSize: 11.5, color: DashColors.w(0.70)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GroupLabel('Generation'),
              const SizedBox(height: 12),
              NumberStepper(
                label: 'Lines / lesson',
                value: state._linesPerLesson,
                min: 3,
                max: 40,
                onChanged: (v) => state.apply(() => state._linesPerLesson = v),
              ),
              const SizedBox(height: 10),
              NumberStepper(
                label: 'Sentences / word',
                value: state._sentencesPerWord,
                min: 1,
                max: 5,
                onChanged: (v) =>
                    state.apply(() => state._sentencesPerWord = v),
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
                      state._lessonCount == 0
                          ? 'Parse subtitles to see the lesson count'
                          : '≈ ${state._lessonCount} lessons total',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
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
              const SizedBox(height: 10),
              Text('ADDITIONAL INSTRUCTIONS',
                  style: DashText.sectionLabel(size: 10)),
              const SizedBox(height: 6),
              TextField(
                controller: state._extraInstructions,
                minLines: 2,
                maxLines: 6,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                onChanged: (_) => rebuild(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'e.g. skip action-only lines, keep it PG…',
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

class _PromptPanel extends StatelessWidget {
  final _CreateFromSubtitlesPageState state;
  const _PromptPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasLines =
        state._parsedLines != null && state._parsedLines!.isNotEmpty;
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
                onTap: hasLines ? state._copyPrompt : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasLines
                ? 'Run this in any LLM, then paste the result below.'
                : 'Parse a subtitle file on the left to build the prompt.',
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
                hasLines
                    ? state._buildPrompt()
                    : '(Prompt preview appears once subtitles are parsed.)',
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
            onTap: hasLines ? state._copyPrompt : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.content_paste_go_outlined,
                  size: 15, color: DashColors.w(0.6)),
              const SizedBox(width: 8),
              Text('PASTE RESULT & IMPORT', style: DashText.sectionLabel(size: 10)),
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
