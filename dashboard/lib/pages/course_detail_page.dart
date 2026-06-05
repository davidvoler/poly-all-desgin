import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/lesson_editor_dialog.dart';
import '../widgets/shell.dart';

/// Drill-in view for a single course. Loads in pages so a large course
/// renders fast: the course head + a lightweight module list come first
/// (no lessons), and each module fetches its own lessons on demand when
/// expanded. This replaces the old single `/detail` round-trip that pulled
/// every lesson up front.
class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final courseId = arg is int ? arg : 0;
    final headAsync = ref.watch(courseHeadProvider(courseId));
    final modulesAsync = ref.watch(courseModulesProvider(courseId));
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CourseHeader(course: course),
              const SizedBox(height: 22),
              const HeadRow(label: 'Modules'),
              modulesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'Could not load modules\n$e',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
                    ),
                  ),
                ),
                data: (modules) {
                  if (modules.isEmpty) return _empty();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final m in modules) ...[
                        _ModuleCard(courseId: courseId, module: m),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Text(
        'No modules yet — re-upload a course archive to populate this.',
        style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  final EditorCourse course;
  const _CourseHeader({required this.course});

  StatusPill _statusPill() {
    switch (course.status) {
      case CourseStatusWire.draft:
        return const StatusPill(
            label: 'Draft', kind: PillKind.muted, swatch: true);
      case CourseStatusWire.review:
        return const StatusPill(
            label: 'In review', kind: PillKind.draft, swatch: true);
      case CourseStatusWire.published:
        return const StatusPill(
            label: 'Published', kind: PillKind.active, swatch: true);
      case CourseStatusWire.archived:
        return const StatusPill(
            label: 'Archived', kind: PillKind.error, swatch: true);
      case CourseStatusWire.unknown:
        return const StatusPill(
            label: 'Unknown', kind: PillKind.muted, swatch: true);
    }
  }

  StatusPill _accessPill() {
    switch (course.access) {
      case CourseAccessWire.public:
        return const StatusPill(
            label: 'Public', kind: PillKind.public, leading: Icons.public);
      case CourseAccessWire.members:
        return const StatusPill(
            label: 'Members',
            kind: PillKind.members,
            leading: Icons.lock_outline);
      case CourseAccessWire.unknown:
        return const StatusPill(label: '—', kind: PillKind.muted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _statusPill(),
              _accessPill(),
              _Counter(label: 'Modules', value: '${course.moduleCount}'),
              _Counter(label: 'Lessons', value: '${course.lessonCount}'),
              _Counter(label: 'Students', value: '${course.studentCount}'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.22,
            ),
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              course.description,
              style: TextStyle(fontSize: 13, color: DashColors.w(0.70)),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${course.lang.toUpperCase()} → ${course.toLang.toUpperCase()} · updated ${course.updatedHuman}',
            style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
          ),
          if (!course.meta.isEmpty) ...[
            const SizedBox(height: 14),
            _VariantMeta(meta: course.meta),
          ],
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

class _Counter extends StatelessWidget {
  final String label;
  final String value;
  const _Counter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DashColors.w(0.06),
        borderRadius: DashRadii.pill,
        border: Border.all(color: DashColors.w(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: DashColors.w(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible module — header always visible, lessons fetched and revealed
/// on first expand (lazy). Starts collapsed so opening a large course never
/// loads every module's lessons at once.
class _ModuleCard extends ConsumerStatefulWidget {
  final int courseId;
  final EditorModuleSummary module;
  const _ModuleCard({required this.courseId, required this.module});

  @override
  ConsumerState<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends ConsumerState<_ModuleCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
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
                  Icon(
                    _open ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: DashColors.w(0.55),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title.isNotEmpty
                              ? m.title
                              : 'Module ${m.moduleId}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (m.description.isNotEmpty)
                          Text(
                            m.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: DashColors.w(0.55),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${m.lessonCount} lessons',
                    style: TextStyle(
                      fontSize: 11,
                      color: DashColors.w(0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            Divider(color: DashColors.w(0.08), height: 1),
            _LazyLessons(courseId: widget.courseId, moduleId: m.moduleId),
          ],
        ],
      ),
    );
  }
}

/// Loads + renders a module's lessons on demand. Only built once its parent
/// module card is expanded, so the fetch is deferred until needed.
class _LazyLessons extends ConsumerWidget {
  final int courseId;
  final int moduleId;
  const _LazyLessons({required this.courseId, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
        moduleLessonsProvider((courseId: courseId, moduleId: moduleId)));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.fromLTRB(40, 12, 16, 12),
        child: Text(
          'Could not load lessons — $e',
          style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
        ),
      ),
      data: (lessons) {
        if (lessons.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(40, 12, 16, 12),
            child: Text(
              'No lessons in this module.',
              style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final l in lessons) _LessonRow(lesson: l)],
        );
      },
    );
  }
}

class _LessonRow extends StatelessWidget {
  final EditorLessonRemote lesson;
  const _LessonRow({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => LessonEditorDialog(lessonId: lesson.lessonId),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 10, 16, 10),
        child: Row(
          children: [
            Icon(Icons.menu_book_outlined,
                size: 14, color: DashColors.w(0.55)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title.isNotEmpty
                        ? lesson.title
                        : 'Lesson ${lesson.lessonId}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (lesson.words.isNotEmpty)
                    Text(
                      lesson.words.take(6).join(' · '),
                      style: TextStyle(
                        fontSize: 11,
                        color: DashColors.w(0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '${lesson.exerciseCount} ex.',
              style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right,
                size: 14, color: DashColors.w(0.35)),
          ],
        ),
      ),
    );
  }
}
