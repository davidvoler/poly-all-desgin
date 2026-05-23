import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../util/download.dart';
import '../widgets/common.dart';
import '../widgets/data_table.dart';
import '../widgets/shell.dart';

/// Local mirror of the server-side course-status state graph in
/// server/src/editor/routes/review.py. Keep in sync — the UI only
/// offers transitions the server will accept.
const Map<CourseStatusWire, Set<CourseStatusWire>> kAllowedTransitions = {
  CourseStatusWire.draft: {CourseStatusWire.review, CourseStatusWire.archived},
  CourseStatusWire.review: {
    CourseStatusWire.draft,
    CourseStatusWire.published,
    CourseStatusWire.archived,
  },
  CourseStatusWire.published: {
    CourseStatusWire.review,
    CourseStatusWire.archived,
  },
  CourseStatusWire.archived: {CourseStatusWire.draft},
};

const Map<CourseStatusWire, String> kStatusWire = {
  CourseStatusWire.draft: 'draft',
  CourseStatusWire.review: 'review',
  CourseStatusWire.published: 'published',
  CourseStatusWire.archived: 'archived',
};

const Map<CourseStatusWire, String> kStatusLabel = {
  CourseStatusWire.draft: 'Move to Draft',
  CourseStatusWire.review: 'Submit for Review',
  CourseStatusWire.published: 'Publish',
  CourseStatusWire.archived: 'Archive',
};

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardShell(
      title: 'Courses',
      activeRoute: '/courses',
      topbarTrailing: [
        PrimaryButton(
          label: 'Upload course',
          leading: Icons.file_upload_outlined,
          onTap: () => _pickAndUpload(context, ref),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Dropzone(onBrowse: () => _pickAndUpload(context, ref)),
          const SizedBox(height: 18),
          const _CoursesPanel(),
        ],
      ),
    );
  }
}

/// Picks a .zip, POSTs it to /api/v1/editor/upload/, then invalidates
/// the courses + activity providers so the table and Overview feed
/// pick up the new row. Shared by the topbar CTA and the dropzone.
Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
  final me = ref.read(currentUserProvider);
  if (me == null) return;
  final messenger = ScaffoldMessenger.of(context);

  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Pick a course .zip',
    type: FileType.custom,
    allowedExtensions: ['zip'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;
  final picked = result.files.first;

  messenger.showSnackBar(
    SnackBar(
      content: Text('Uploading ${picked.name}…'),
      duration: const Duration(seconds: 60),
    ),
  );
  try {
    final courseId = await ref.read(dashboardApiProvider).uploadCourse(
          schoolId: me.schoolId,
          actorUserId: me.schoolUserId,
          filename: picked.name,
          fileBytes: picked.bytes,
          filePath: picked.path,
        );
    ref.invalidate(editorCoursesProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(schoolStatsProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(courseId == null
              ? 'Upload succeeded'
              : 'Uploaded — created course #$courseId'),
        ),
      );
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Upload failed: $e')));
  }
}

class _Dropzone extends StatelessWidget {
  final VoidCallback onBrowse;
  const _Dropzone({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        borderRadius: DashRadii.card,
        border: Border.all(
          color: DashColors.w(0.18),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DashColors.w(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.file_upload_outlined,
                size: 22, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag a course folder or .zip here',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Folder layout: course/<module>/<lesson>/exercises.json · audio in matching paths. '
              'Description files (course.md, module.md) optional.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Browse files',
            leading: Icons.file_upload_outlined,
            onTap: onBrowse,
          ),
        ],
      ),
    );
  }
}

class _CoursesPanel extends ConsumerWidget {
  const _CoursesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(editorCoursesProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'Could not load courses\n$e',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
          ),
        ),
      ),
      data: (rows) {
        final published = rows
            .where((c) => c.status == CourseStatusWire.published)
            .length;
        final draft =
            rows.where((c) => c.status == CourseStatusWire.draft).length;
        final review =
            rows.where((c) => c.status == CourseStatusWire.review).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeadRow(
              label: 'All courses',
              subtitle:
                  '·  ${rows.length} total · $published published, $draft draft, $review in review',
            ),
            if (rows.isEmpty)
              _empty(context)
            else
              _CoursesTable(rows: rows),
          ],
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        'No courses yet — upload one above.',
        style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
      ),
    );
  }
}

class _CoursesTable extends ConsumerWidget {
  final List<EditorCourse> rows;
  const _CoursesTable({required this.rows});

  StatusPill _statusPill(CourseStatusWire s) {
    switch (s) {
      case CourseStatusWire.draft:
        return const StatusPill(
          label: 'Draft',
          kind: PillKind.muted,
          swatch: true,
        );
      case CourseStatusWire.review:
        return const StatusPill(
          label: 'In review',
          kind: PillKind.draft,
          swatch: true,
        );
      case CourseStatusWire.published:
        return const StatusPill(
          label: 'Published',
          kind: PillKind.active,
          swatch: true,
        );
      case CourseStatusWire.archived:
        return const StatusPill(
          label: 'Archived',
          kind: PillKind.error,
          swatch: true,
        );
      case CourseStatusWire.unknown:
        return const StatusPill(
          label: 'Unknown',
          kind: PillKind.muted,
          swatch: true,
        );
    }
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    EditorCourse course,
    CourseStatusWire next,
  ) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(dashboardApiProvider);
    try {
      await api.setCourseStatus(
        courseId: course.courseId,
        schoolId: me.schoolId,
        actorUserId: me.schoolUserId,
        status: kStatusWire[next]!,
      );
      // Refetch list + activity so the UI reflects the change.
      ref.invalidate(editorCoursesProvider);
      ref.invalidate(activityProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Moved "${course.title}" to ${kStatusLabel[next]}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not change status: $e')),
      );
    }
  }

  String _accessLabel(CourseAccessWire a) {
    switch (a) {
      case CourseAccessWire.public:
        return 'Public';
      case CourseAccessWire.members:
        return 'Members';
      case CourseAccessWire.unknown:
        return '—';
    }
  }

  IconData _accessIcon(CourseAccessWire a) =>
      a == CourseAccessWire.public ? Icons.public : Icons.lock_outline;

  PillKind _accessKind(CourseAccessWire a) {
    switch (a) {
      case CourseAccessWire.public:
        return PillKind.public;
      case CourseAccessWire.members:
        return PillKind.members;
      case CourseAccessWire.unknown:
        return PillKind.muted;
    }
  }

  /// Deterministic 2-char avatar mark per course (first two letters of
  /// the title's first word, uppercase). Falls back to the course id.
  String _mark(EditorCourse c) {
    final title = c.title.trim();
    if (title.isEmpty) return '#${c.courseId}';
    final first = title.split(RegExp(r'\s+')).first;
    return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _avatarKey(int courseId) {
    const keys = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return keys[courseId.abs() % keys.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashTable(
      columns: const [
        DashCol(label: 'Course', flex: 4),
        DashCol(label: 'Language', flex: 2),
        DashCol(label: 'Modules · Lessons', flex: 2),
        DashCol(label: 'Students', flex: 1),
        DashCol(label: 'Access', flex: 2),
        DashCol(label: 'Status', flex: 2),
        DashCol(label: 'Updated', flex: 2),
        DashCol(label: '', width: 48),
      ],
      rows: [
        for (final c in rows)
          [
            WhoCell(
              initials: _mark(c),
              avatarKey: _avatarKey(c.courseId),
              name: c.title,
              email: c.description,
            ),
            Text(c.lang.toUpperCase()),
            Text('${c.moduleCount} · ${c.lessonCount}'),
            Text('${c.studentCount}'),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                label: _accessLabel(c.access),
                leading: _accessIcon(c.access),
                kind: _accessKind(c.access),
              ),
            ),
            Align(
                alignment: Alignment.centerLeft,
                child: _statusPill(c.status)),
            Text(
              c.updatedHuman,
              style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _RowMenu(
                current: c.status,
                onStatus: (next) => _setStatus(context, ref, c, next),
                onExport: () => _exportCourse(context, ref, c),
              ),
            ),
          ],
      ],
    );
  }
}

/// Pulls the course's zip from the server and hands the bytes to
/// download.dart's `saveBytes`, which forks to Blob on web / saveFile
/// on desktop. Shows a snackbar with the filename on success.
Future<void> _exportCourse(
  BuildContext context,
  WidgetRef ref,
  EditorCourse course,
) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(
    content: Text('Exporting ${course.title}…'),
    duration: const Duration(seconds: 30),
  ));
  try {
    final bytes = await ref.read(dashboardApiProvider).exportCourse(course.courseId);
    final filename = 'course_${course.courseId}.zip';
    final saved = await saveBytes(filename: filename, bytes: bytes);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(saved == null
            ? 'Export cancelled'
            : 'Saved $filename'),
      ));
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

/// Three-dot row menu — server-legal status transitions plus the
/// always-available "Export as .zip" action. Sentinel "export" key
/// distinguishes the export entry from status enum values inside the
/// single `PopupMenuButton<String>`.
class _RowMenu extends StatelessWidget {
  final CourseStatusWire current;
  final ValueChanged<CourseStatusWire> onStatus;
  final VoidCallback onExport;
  const _RowMenu({
    required this.current,
    required this.onStatus,
    required this.onExport,
  });

  static const String _kExport = 'export';

  @override
  Widget build(BuildContext context) {
    final allowed = kAllowedTransitions[current] ?? const <CourseStatusWire>{};
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (key) {
        if (key == _kExport) {
          onExport();
          return;
        }
        for (final s in CourseStatusWire.values) {
          if (s.name == key) {
            onStatus(s);
            return;
          }
        }
      },
      color: DashColors.darkBg.withValues(alpha: 0.96),
      itemBuilder: (context) => [
        for (final s in allowed)
          PopupMenuItem<String>(
            value: s.name,
            child: Row(
              children: [
                _statusDot(s),
                const SizedBox(width: 10),
                Text(
                  kStatusLabel[s]!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        if (allowed.isNotEmpty) const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: _kExport,
          child: Row(
            children: [
              Icon(Icons.download, size: 14, color: DashColors.w(0.70)),
              const SizedBox(width: 10),
              const Text(
                'Export as .zip',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: DashColors.w(0.04),
          border: Border.all(color: DashColors.w(0.08)),
        ),
        child: Icon(Icons.more_horiz, size: 14, color: DashColors.w(0.70)),
      ),
    );
  }

  Widget _statusDot(CourseStatusWire s) {
    final color = switch (s) {
      CourseStatusWire.draft => DashColors.w(0.55),
      CourseStatusWire.review => DashColors.orange300,
      CourseStatusWire.published => DashColors.green500,
      CourseStatusWire.archived => DashColors.red400,
      CourseStatusWire.unknown => DashColors.w(0.55),
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
