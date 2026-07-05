import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../util/download.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

/// Drill-in view for a single course. Course editing was simplified
/// server-side to title/description/publish-unpublish only (see
/// server/EDITOR.md "option 2") — this is a flat metadata form, not a
/// module/lesson tree (there's no server endpoint left to back one).
class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final courseId = arg is int ? arg : 0;
    final headAsync = ref.watch(courseHeadProvider(courseId));
    return DashboardShell(
      title: headAsync.value?.title.isNotEmpty == true
          ? headAsync.value!.title
          : 'Course',
      activeRoute: '/courses',
      topbarTrailing: [
        GhostButton(
          label: 'Back to courses',
          leading: Icons.arrow_back,
          onTap: () => Navigator.pushReplacementNamed(context, '/courses'),
        ),
      ],
      child: headAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              'Could not load course\n$e',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
            ),
          ),
        ),
        data: (course) {
          if (course == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Course not found.',
                  style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
                ),
              ),
            );
          }
          return _CourseEditForm(course: course);
        },
      ),
    );
  }
}

class _CourseEditForm extends ConsumerStatefulWidget {
  final EditorCourse course;
  const _CourseEditForm({required this.course});

  @override
  ConsumerState<_CourseEditForm> createState() => _CourseEditFormState();
}

class _CourseEditFormState extends ConsumerState<_CourseEditForm> {
  late final _title = TextEditingController(text: widget.course.title);
  late final _description =
      TextEditingController(text: widget.course.description);
  late bool _published = widget.course.published;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(dashboardApiProvider).updateCourse(
            widget.course.copyWith(
              title: _title.text.trim(),
              description: _description.text.trim(),
              published: _published,
            ),
          );
      ref.invalidate(courseHeadProvider(widget.course.courseId));
      ref.invalidate(editorCoursesProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text('Exporting ${widget.course.title}…'),
      duration: const Duration(seconds: 30),
    ));
    try {
      final bytes = await ref
          .read(dashboardApiProvider)
          .exportCourse(widget.course.courseId);
      final filename = 'course_${widget.course.courseId}.yaml';
      final saved = await saveBytes(filename: filename, bytes: bytes);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content:
              Text(saved == null ? 'Export cancelled' : 'Saved $filename'),
        ));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DashColors.darkBg,
        title:
            const Text('Delete course?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This permanently deletes "${widget.course.title}". '
          'This cannot be undone.',
          style: TextStyle(color: DashColors.w(0.70)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: DashColors.red400)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(dashboardApiProvider)
          .deleteCourse(widget.course.courseId);
      ref.invalidate(editorCoursesProvider);
      navigator.pushReplacementNamed('/courses');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  StatusPill _publishedPill(bool published) => published
      ? const StatusPill(
          label: 'Published', kind: PillKind.active, swatch: true)
      : const StatusPill(label: 'Draft', kind: PillKind.muted, swatch: true);

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
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

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _publishedPill(_published),
              StatusPill(
                label:
                    '${course.lang.toUpperCase()} → ${course.toLang.toUpperCase()}',
                kind: PillKind.neutral,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _field('TITLE', _title),
          const SizedBox(height: 14),
          _field('DESCRIPTION', _description, maxLines: 4),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('PUBLISHED', style: DashText.sectionLabel(size: 10)),
              const Spacer(),
              Switch(
                value: _published,
                onChanged: (v) => setState(() => _published = v),
              ),
            ],
          ),
          if (!course.meta.isEmpty) ...[
            const SizedBox(height: 14),
            _VariantMeta(meta: course.meta),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              PrimaryButton(
                label: _saving ? 'Saving…' : 'Save',
                leading: Icons.save_outlined,
                onTap: _saving ? null : _save,
              ),
              const SizedBox(width: 10),
              GhostButton(
                label: 'Export',
                leading: Icons.download,
                onTap: _export,
              ),
              const Spacer(),
              GhostButton(
                label: 'Delete',
                leading: Icons.delete_outline,
                onTap: _delete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Read-only display of the course's display metadata — the reading
/// (`ruby_text`) and full-sentence (`sentence_alt`) variants it declares,
/// each as a small chip with its icon + name. Surfaces what the quiz will
/// offer learners for this course.
class _VariantMeta extends StatelessWidget {
  final CourseMeta meta;
  const _VariantMeta({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.rubyText.isNotEmpty) ...[
          _label('READING VARIANTS'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final d in meta.rubyText) _VariantChip(d: d)],
          ),
        ],
        if (meta.sentenceAlt.isNotEmpty) ...[
          if (meta.rubyText.isNotEmpty) const SizedBox(height: 12),
          _label('SENTENCE ALTERNATIVES'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final d in meta.sentenceAlt) _VariantChip(d: d)],
          ),
        ],
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: DashColors.w(0.45),
        ),
      );
}

class _VariantChip extends StatelessWidget {
  final VariantDescriptor d;
  const _VariantChip({required this.d});

  // Minimal name→icon resolver for the icons the metadata uses; unknown
  // names fall back to a neutral glyph.
  static const _icons = <String, IconData>{
    'translate': Icons.translate,
    'abc': Icons.abc,
    'format_size': Icons.format_size,
    'spellcheck': Icons.spellcheck,
    'subtitles': Icons.subtitles,
  };

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DashColors.w(0.06),
        borderRadius: DashRadii.pill,
        border: Border.all(color: DashColors.w(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[d.icon] ?? Icons.label_outline,
              size: 13, color: DashColors.w(0.70)),
          const SizedBox(width: 6),
          Text(
            d.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    final tip = d.tooltip;
    if (tip == null || tip.isEmpty) return chip;
    return Tooltip(message: tip, child: chip);
  }
}
