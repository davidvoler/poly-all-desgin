import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import 'common.dart';

/// Per-lesson editor — load via [lessonDetailProvider], edit title /
/// words / exercises in a working copy, then `POST /editor/lesson/`
/// on save. The dialog reuses the response shape as the write payload
/// so add/edit/reorder operations all flow through a single endpoint.
class LessonEditorDialog extends ConsumerWidget {
  final int lessonId;
  const LessonEditorDialog({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lessonDetailProvider(lessonId));
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, _) => Center(
              child: Text(
                'Could not load lesson\n$e',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
              ),
            ),
            data: (lesson) => _Editor(lesson: lesson),
          ),
        ),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  final LessonDetailRemote lesson;
  const _Editor({required this.lesson});

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final TextEditingController _title;
  // Mutable working copy of the exercises array. Each entry mirrors
  // what the server returns; the save POST hands it back unchanged.
  late final List<Map<String, dynamic>> _exercises;
  late final List<String> _words;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.lesson.title);
    _exercises = [
      for (final e in widget.lesson.exercises) Map<String, dynamic>.from(e),
    ];
    _words = List<String>.from(widget.lesson.words);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(dashboardApiProvider).saveLessonDetail(
            courseId: widget.lesson.courseId,
            moduleId: widget.lesson.moduleId,
            lessonId: widget.lesson.lessonId,
            title: _title.text.trim(),
            words: _words,
            exercises: _exercises,
          );
      // Invalidate the parent course detail + this lesson so reopen
      // shows fresh data.
      ref.invalidate(courseDetailProvider(widget.lesson.courseId));
      ref.invalidate(lessonDetailProvider(widget.lesson.lessonId));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Could not save: $e';
        _busy = false;
      });
    }
  }

  void _addExercise() {
    setState(() {
      _exercises.add({
        'type': 'simple',
        'text': '',
        'options': <Map<String, dynamic>>[],
        'voice': '',
        'word1': '',
        'word2': '',
        'word3': '',
      });
    });
  }

  void _removeExercise(int i) {
    setState(() => _exercises.removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Edit lesson',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, size: 18, color: DashColors.w(0.70)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            labelText: 'TITLE',
            labelStyle: DashText.sectionLabel(size: 10),
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
        const SizedBox(height: 14),
        Row(
          children: [
            Text('${_exercises.length} EXERCISES',
                style: DashText.sectionLabel(size: 10)),
            const Spacer(),
            GhostButton(
              label: 'Add exercise',
              leading: Icons.add,
              onTap: _addExercise,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: _exercises.isEmpty
              ? _EmptyHint(onAdd: _addExercise)
              : ListView.separated(
                  itemCount: _exercises.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ExerciseRow(
                    index: i,
                    data: _exercises[i],
                    onChange: () => setState(() {}),
                    onRemove: () => _removeExercise(i),
                  ),
                ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: TextStyle(fontSize: 12, color: DashColors.red400)),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                  foregroundColor: DashColors.w(0.70)),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            PrimaryButton(
              label: _busy ? 'Saving…' : 'Save lesson',
              leading: Icons.save_outlined,
              onTap: _busy ? null : _save,
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHint({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined,
              size: 28, color: DashColors.w(0.35)),
          const SizedBox(height: 8),
          Text(
            'No exercises yet.',
            style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
          ),
          const SizedBox(height: 8),
          GhostButton(
              label: 'Add first exercise',
              leading: Icons.add,
              onTap: onAdd),
        ],
      ),
    );
  }
}

/// Single exercise row — type chip, sentence text field, options
/// (text + correct flag), removal button. Edits mutate the shared map
/// in place; the parent calls `setState` via [onChange] when the row
/// adds/removes options so the listview re-measures.
class _ExerciseRow extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  const _ExerciseRow({
    required this.index,
    required this.data,
    required this.onChange,
    required this.onRemove,
  });

  @override
  State<_ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<_ExerciseRow> {
  late final TextEditingController _text;

  static const _kTypes = ['simple', 'read', 'recognize'];

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: (widget.data['text'] as String?) ?? '');
    _text.addListener(() => widget.data['text'] = _text.text);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _options {
    final raw = widget.data['options'];
    if (raw is List) {
      return raw.cast<Map<String, dynamic>>();
    }
    final list = <Map<String, dynamic>>[];
    widget.data['options'] = list;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final type = (widget.data['type'] as String?) ?? 'simple';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        borderRadius: DashRadii.cardSm,
        border: Border.all(color: DashColors.w(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('#${widget.index + 1}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DashColors.w(0.55))),
              const SizedBox(width: 10),
              for (final t in _kTypes) ...[
                ChoiceChip(
                  label: Text(t,
                      style: const TextStyle(fontSize: 10)),
                  selected: type == t,
                  onSelected: (_) => setState(() {
                    widget.data['type'] = t;
                  }),
                  selectedColor: DashColors.brand,
                  backgroundColor: DashColors.w(0.06),
                  labelStyle: TextStyle(
                    color: type == t ? Colors.white : DashColors.w(0.70),
                  ),
                  side: BorderSide(color: DashColors.w(0.14)),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
              ],
              const Spacer(),
              IconButton(
                tooltip: 'Remove',
                onPressed: widget.onRemove,
                icon: Icon(Icons.delete_outline,
                    size: 16, color: DashColors.w(0.55)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Sentence / prompt',
              hintStyle:
                  TextStyle(fontSize: 12, color: DashColors.w(0.35)),
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
          const SizedBox(height: 10),
          Text('OPTIONS', style: DashText.sectionLabel(size: 10)),
          const SizedBox(height: 6),
          for (var i = 0; i < _options.length; i++) _optionRow(i),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _options.add({'text': '', 'correct': false});
                });
                widget.onChange();
              },
              style: TextButton.styleFrom(
                foregroundColor: DashColors.w(0.70),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add option', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionRow(int i) {
    final opt = _options[i];
    final correct = opt['correct'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Checkbox(
            value: correct,
            onChanged: (v) => setState(() => opt['correct'] = v ?? false),
            activeColor: DashColors.green500,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: TextFormField(
              initialValue: (opt['text'] as String?) ?? '',
              onChanged: (v) => opt['text'] = v,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Option text',
                hintStyle:
                    TextStyle(fontSize: 12, color: DashColors.w(0.35)),
                filled: true,
                fillColor: DashColors.w(0.04),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
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
          ),
          IconButton(
            tooltip: 'Remove option',
            onPressed: () {
              setState(() => _options.removeAt(i));
              widget.onChange();
            },
            icon:
                Icon(Icons.close, size: 14, color: DashColors.w(0.55)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
