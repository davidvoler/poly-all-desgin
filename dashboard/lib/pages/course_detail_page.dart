import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/lesson_editor_dialog.dart';
import '../widgets/shell.dart';

/// Drill-in view for a single course — modules collapse/expand to
/// reveal their lessons, each lesson shows its exercise count. Currently
/// read-only; an editor pass will let the user rename modules/lessons
/// and reorder them inline.
class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final courseId = arg is int ? arg : 0;
    final async = ref.watch(courseDetailProvider(courseId));
    return DashboardShell(
      title: async.value?.title.isNotEmpty == true
          ? async.value!.title
          : 'Course',
      activeRoute: '/courses',
      topbarTrailing: [
        GhostButton(
          label: 'Back to courses',
          leading: Icons.arrow_back,
          onTap: () => Navigator.pushReplacementNamed(context, '/courses'),
        ),
      ],
      child: async.when(
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
        data: (detail) {
          if (detail == null) {
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
              _CourseHeader(detail: detail),
              const SizedBox(height: 22),
              const HeadRow(label: 'Modules'),
              if (detail.modules.isEmpty)
                _empty()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final m in detail.modules) ...[
                      _ModuleCard(module: m),
                      const SizedBox(height: 10),
                    ],
                  ],
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
  final EditorCourseDetail detail;
  const _CourseHeader({required this.detail});

  StatusPill _statusPill() {
    switch (detail.status) {
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
    switch (detail.access) {
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
              _Counter(label: 'Modules', value: '${detail.moduleCount}'),
              _Counter(label: 'Lessons', value: '${detail.lessonCount}'),
              _Counter(label: 'Students', value: '${detail.studentCount}'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            detail.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.22,
            ),
          ),
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail.description,
              style: TextStyle(fontSize: 13, color: DashColors.w(0.70)),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${detail.lang.toUpperCase()} → ${detail.toLang.toUpperCase()} · updated ${detail.updatedHuman}',
            style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
          ),
        ],
      ),
    );
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

/// Collapsible module — header always visible, lessons revealed on tap.
/// `ExpansionTile` would do the job, but a custom widget keeps the
/// glass styling consistent with the rest of the dashboard.
class _ModuleCard extends StatefulWidget {
  final EditorModuleRemote module;
  const _ModuleCard({required this.module});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _open = true;

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
                    '${m.lessons.length} lessons',
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
            for (final l in m.lessons) _LessonRow(lesson: l),
          ],
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final EditorLessonRemote lesson;
  const _LessonRow({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
        ],
      ),
    );
  }
}
