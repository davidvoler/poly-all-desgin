import 'package:flutter/material.dart';

import '../data/mock.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/data_table.dart';
import '../widgets/shell.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Courses',
      overline: MockData.school.name,
      activeRoute: '/courses',
      topbarTrailing: [
        PrimaryButton(
          label: 'Upload course',
          leading: Icons.file_upload_outlined,
          onTap: () {},
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _Dropzone(),
          SizedBox(height: 18),
          HeadRow(
            label: 'All courses',
            subtitle: '·  14 total · 11 published, 3 draft',
          ),
          _CoursesTable(),
        ],
      ),
    );
  }
}

class _Dropzone extends StatelessWidget {
  const _Dropzone();

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
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CoursesTable extends StatelessWidget {
  const _CoursesTable();

  @override
  Widget build(BuildContext context) {
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
        for (final c in MockData.courses)
          [
            WhoCell(
              initials: c.mark,
              avatarKey: c.avatarKey,
              name: c.title,
              email: c.tagline,
            ),
            Text('${c.langFlag} ${c.langName}'),
            Text('${c.modules} · ${c.lessons}'),
            Text('${c.students}'),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                label: c.access == CourseAccess.public ? 'Public' : 'Members',
                leading: c.access == CourseAccess.public
                    ? Icons.public
                    : Icons.lock_outline,
                kind: c.access == CourseAccess.public
                    ? PillKind.public
                    : PillKind.members,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                label: c.status == CourseStatus.published
                    ? 'Published'
                    : 'Draft',
                kind: c.status == CourseStatus.published
                    ? PillKind.active
                    : PillKind.draft,
                swatch: true,
              ),
            ),
            Text(
              c.updated,
              style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: RowActionButton(),
            ),
          ],
      ],
    );
  }
}
