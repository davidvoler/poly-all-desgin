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

/// One dialogue line extracted from an .srt block (text only — timestamps
/// and block indices aren't useful to the LLM prompt).
class SrtLine {
  final String text;
  const SrtLine(this.text);
}

bool _isJunkCaption(String s) {
  final t = s.trim();
  if (t.isEmpty) return true;
  // Sound-effect / music captions like "[music playing]" or "(door creaks)".
  return (t.startsWith('[') && t.endsWith(']')) ||
      (t.startsWith('(') && t.endsWith(')'));
}

/// Parses a .srt file's dialogue text, dropping block indices, timing
/// lines, sound-effect captions, and immediate consecutive duplicates
/// (common in karaoke-style caption tracks). Multi-line dialogue within a
/// single subtitle block is joined with a space.
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
    if (start < blockLines.length && blockLines[start].contains('-->')) {
      start++;
    }
    if (start >= blockLines.length) continue;
    final text = blockLines.sublist(start).join(' ').trim();
    if (_isJunkCaption(text) || text == prev) continue;
    lines.add(SrtLine(text));
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
  int _maxLines = 150;
  int _linesPerLesson = 12;
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

  /// Assemble the LLM prompt: course settings + the capped subtitle
  /// excerpt + the same exercise-type/output-format spec the other
  /// Create-with-AI pages embed.
  String _buildPrompt() {
    final lines = _parsedLines ?? const <SrtLine>[];
    final used = lines.take(_maxLines).toList();
    final excerpt = [
      for (var i = 0; i < used.length; i++) '${i + 1}. ${used[i].text}',
    ].join('\n');
    final truncationNote = lines.length > used.length
        ? '\n(Showing the first ${used.length} of ${lines.length} lines.)'
        : '';

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

    return '''You are an expert language-course author. Turn a movie's dialogue lines into a complete course as a single YAML document for our import format.

Source: "${_source.text.trim()}" (dialogue lines below, in order).
Course to create:
- Teaches: ${_language.text.trim()}
- For students who speak: ${_studentLanguage.text.trim()}
- CEFR level: $_level
- Group every ~$_linesPerLesson consecutive dialogue lines into one lesson, in the order given.
${enrich.isEmpty ? '' : '- $enrich\n'}${extra.isEmpty ? '' : '\nAdditional instructions from the editor:\n$extra\n'}
Dialogue lines to use (translate each into ${_studentLanguage.text.trim()} as needed; skip lines that don't make good exercises rather than forcing them):$truncationNote
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
---
$examples

Exercise types to use (vary them across lessons):
${selected.isEmpty ? '- any of the types shown above' : selected.map((t) => '- ${t.key}: ${t.hint}').join('\n')}

Rules:
- Every lesson needs at least one exercise.
- weight controls order within the parent — number sequentially from 1.
- Use the dialogue lines as the exercise sentences (translated), in order; keep it natural and level-appropriate.
- One module only, named after the source.''';
  }

  void _copyPrompt() {
    Clipboard.setData(ClipboardData(text: _buildPrompt()));
    _toast('Prompt copied — paste it into your LLM.');
  }

  @override
  Widget build(BuildContext context) {
    final needsTerms = ref.watch(meProvider).value?.needsTerms ?? false;
    return DashboardShell(
      title: 'Create from subtitles',
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
                label: 'Max lines to use',
                value: state._maxLines,
                min: 10,
                max: 500,
                onChanged: (v) => state.apply(() => state._maxLines = v),
              ),
              const SizedBox(height: 10),
              NumberStepper(
                label: 'Lines / lesson',
                value: state._linesPerLesson,
                min: 3,
                max: 40,
                onChanged: (v) => state.apply(() => state._linesPerLesson = v),
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
