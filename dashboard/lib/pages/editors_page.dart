import 'package:flutter/material.dart';

import '../data/mock.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/data_table.dart';
import '../widgets/shell.dart';

class EditorsPage extends StatelessWidget {
  const EditorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Editors',
      overline: MockData.school.name,
      activeRoute: '/editors',
      topbarTrailing: [
        PrimaryButton(
          label: 'Invite editor',
          leading: Icons.mail_outline,
          onTap: () {},
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          HeadRow(
            label: 'Team',
            subtitle:
                '·  **5** active · 2 invites pending',
          ),
          _EditorsTable(),
        ],
      ),
    );
  }
}

class _EditorsTable extends StatelessWidget {
  const _EditorsTable();

  StatusPill _rolePill(EditorRole role) {
    switch (role) {
      case EditorRole.owner:
        return const StatusPill(
          label: 'Owner',
          kind: PillKind.white,
          swatch: true,
        );
      case EditorRole.editor:
        return const StatusPill(
          label: 'Editor',
          kind: PillKind.neutral,
          swatch: true,
        );
      case EditorRole.viewer:
        return const StatusPill(
          label: 'Viewer',
          kind: PillKind.muted,
          swatch: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashTable(
      columns: const [
        DashCol(label: 'Editor', flex: 4),
        DashCol(label: 'Role', flex: 2),
        DashCol(label: 'Languages', flex: 2),
        DashCol(label: 'Courses', flex: 1),
        DashCol(label: 'Last seen', flex: 2),
        DashCol(label: 'Status', flex: 2),
        DashCol(label: '', width: 48),
      ],
      rows: [
        for (final e in MockData.editors)
          [
            WhoCell(
              initials: e.initials,
              avatarKey: e.avatarKey,
              name: e.name,
              email: e.email,
              youTag: e.isYou,
            ),
            Align(alignment: Alignment.centerLeft, child: _rolePill(e.role)),
            Text(
              e.langFlag == null
                  ? e.langLabel
                  : '${e.langFlag} ${e.langLabel}',
            ),
            Text(e.coursesLabel),
            Text(
              e.lastSeen,
              style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                label: e.active ? 'Active' : 'Off',
                kind: e.active ? PillKind.active : PillKind.muted,
                swatch: true,
              ),
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
