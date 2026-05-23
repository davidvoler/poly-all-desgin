import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/data_table.dart';
import '../widgets/shell.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  // null = "All languages" (no filter); otherwise a 2-letter ISO code.
  String? _lang;
  // null = "All statuses"; otherwise active|slowing|inactive|no_course
  String? _status;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(schoolStatsProvider).value;
    final langs = ref.watch(languagesProvider).value ?? const <LanguageSummary>[];
    final teaching = langs.where((l) => l.role == 'teach').toList();
    final filter = StudentsFilter(lang: _lang, status: _status);
    final async = ref.watch(studentsProvider(filter));

    return DashboardShell(
      title: 'Students',
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
          HeadRow(
            label: 'Roster',
            subtitle:
                '·  **${stats?.students ?? '…'}** students total',
          ),
          _FilterRow(
            lang: _lang,
            status: _status,
            taughtLanguages: teaching,
            onLang: (l) => setState(() => _lang = l),
            onStatus: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Could not load students\n$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
                ),
              ),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      _lang != null || _status != null
                          ? 'No students match this filter.'
                          : 'No students enrolled yet.',
                      style: TextStyle(
                          fontSize: 12, color: DashColors.w(0.55)),
                    ),
                  ),
                );
              }
              return _StudentsTable(rows: rows);
            },
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String? lang;
  final String? status;
  final List<LanguageSummary> taughtLanguages;
  final ValueChanged<String?> onLang;
  final ValueChanged<String?> onStatus;
  const _FilterRow({
    required this.lang,
    required this.status,
    required this.taughtLanguages,
    required this.onLang,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'All languages',
          on: lang == null,
          onTap: () => onLang(null),
        ),
        for (final l in taughtLanguages)
          _Chip(
            label: '${l.flag} ${l.english} · ${l.students}',
            on: lang == l.lang,
            onTap: () => onLang(l.lang),
          ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Any status',
          on: status == null,
          onTap: () => onStatus(null),
        ),
        for (final s in const [
          ('active', 'Active'),
          ('slowing', 'Slowing'),
          ('inactive', 'Inactive'),
          ('no_course', 'No course'),
        ])
          _Chip(
            label: s.$2,
            on: status == s.$1,
            onTap: () => onStatus(s.$1),
          ),
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
  final List<StudentRowRemote> rows;
  const _StudentsTable({required this.rows});

  StatusPill _statusPill(StudentStatusWire s) {
    switch (s) {
      case StudentStatusWire.active:
        return const StatusPill(
            label: 'Active', kind: PillKind.active, swatch: true);
      case StudentStatusWire.slowing:
        return const StatusPill(
            label: 'Slowing', kind: PillKind.draft, swatch: true);
      case StudentStatusWire.inactive:
        return const StatusPill(
            label: 'Inactive', kind: PillKind.error, swatch: true);
      case StudentStatusWire.noCourse:
        return const StatusPill(
            label: 'No course', kind: PillKind.draft, swatch: true);
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
        for (final s in rows)
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
              s.lastSeenHuman,
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
