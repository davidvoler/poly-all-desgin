import 'package:flutter/material.dart';

import '../data/mock.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/data_table.dart';
import '../widgets/shell.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String _activeFilter = 'All languages';
  int _page = 1;

  static const _langChips = [
    'All languages',
    '🇸🇦 Arabic · 112',
    '🇮🇱 Hebrew · 94',
    '🇮🇹 Italian · 42',
  ];
  static const _statusChips = ['Active', 'Inactive 14d+', 'No course yet'];

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Students',
      overline: MockData.school.name,
      activeRoute: '/students',
      topbarTrailing: [
        PrimaryButton(
          label: 'Add students',
          leading: Icons.add,
          onTap: () {},
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeadRow(
            label: 'Roster',
            subtitle:
                '·  **248** students · 142 active in the last 24h',
          ),
          _FilterRow(
            activeFilter: _activeFilter,
            langChips: _langChips,
            statusChips: _statusChips,
            onSelect: (label) => setState(() => _activeFilter = label),
          ),
          const SizedBox(height: 14),
          const _StudentsTable(),
          const SizedBox(height: 18),
          _Pager(
            current: _page,
            onTap: (p) => setState(() => _page = p),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String activeFilter;
  final List<String> langChips;
  final List<String> statusChips;
  final ValueChanged<String> onSelect;
  const _FilterRow({
    required this.activeFilter,
    required this.langChips,
    required this.statusChips,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in langChips)
          _Chip(label: c, on: c == activeFilter, onTap: () => onSelect(c)),
        const SizedBox(width: 8),
        for (final c in statusChips)
          _Chip(label: c, on: c == activeFilter, onTap: () => onSelect(c)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? Colors.white : DashColors.w(0.06),
      borderRadius: DashRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: DashRadii.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: DashRadii.pill,
            border: Border.all(
              color: on ? Colors.white : DashColors.w(0.14),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: on ? DashColors.brand : DashColors.w(0.70),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentsTable extends StatelessWidget {
  const _StudentsTable();

  StatusPill _statusPill(StudentStatus s) {
    switch (s) {
      case StudentStatus.active:
        return const StatusPill(
          label: 'Active',
          kind: PillKind.active,
          swatch: true,
        );
      case StudentStatus.slowing:
        return const StatusPill(
          label: 'Slowing',
          kind: PillKind.draft,
          swatch: true,
        );
      case StudentStatus.inactive:
        return const StatusPill(
          label: 'Inactive',
          kind: PillKind.error,
          swatch: true,
        );
      case StudentStatus.noCourse:
        return const StatusPill(
          label: 'No course',
          kind: PillKind.draft,
          swatch: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashTable(
      columns: const [
        DashCol(label: 'Student', flex: 4),
        DashCol(label: 'Language', flex: 2),
        DashCol(label: 'Course', flex: 3),
        DashCol(label: 'Progress', flex: 2),
        DashCol(label: 'Last seen', flex: 2),
        DashCol(label: 'Status', flex: 2),
        DashCol(label: '', width: 48),
      ],
      rows: [
        for (final s in MockData.students)
          [
            WhoCell(
              initials: s.initials,
              avatarKey: s.avatarKey,
              name: s.name,
              email: s.email,
            ),
            Text('${s.langFlag} ${s.langName}'),
            Text(
              s.course,
              style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
            ),
            TableProgressBar(value: s.progress),
            Text(
              s.lastSeen,
              style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
            ),
            Align(alignment: Alignment.centerLeft, child: _statusPill(s.status)),
            const Align(
              alignment: Alignment.centerRight,
              child: RowActionButton(),
            ),
          ],
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _Pager({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 6,
        children: [
          _PgButton(label: '‹', onTap: () {}),
          _PgButton(label: '1', on: current == 1, onTap: () => onTap(1)),
          _PgButton(label: '2', on: current == 2, onTap: () => onTap(2)),
          _PgButton(label: '3', on: current == 3, onTap: () => onTap(3)),
          _PgButton(label: '…', onTap: () {}),
          _PgButton(label: '31', on: current == 31, onTap: () => onTap(31)),
          _PgButton(label: '›', onTap: () {}),
        ],
      ),
    );
  }
}

class _PgButton extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _PgButton({required this.label, this.on = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? DashColors.w(0.14) : DashColors.w(0.04),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: on ? DashColors.w(0.18) : DashColors.w(0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: on ? Colors.white : DashColors.w(0.70),
            ),
          ),
        ),
      ),
    );
  }
}
