import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/data_table.dart';
import '../widgets/search_field.dart';
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
  // Free-text search debounced to 300ms by SearchField.
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(schoolStatsProvider).value;
    final langs = ref.watch(languagesProvider).value ?? const <LanguageSummary>[];
    final teaching = langs.where((l) => l.role == 'teach').toList();
    final filter = StudentsFilter(q: _q, lang: _lang, status: _status);
    final async = ref.watch(studentsProvider(filter));

    return DashboardShell(
      title: 'Students',
      activeRoute: '/students',
      topbarTrailing: [
        _AddStudentsMenu(taughtLanguages: teaching),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeadRow(
            label: 'Roster',
            subtitle:
                '·  **${stats?.students ?? '…'}** students total',
            trailing: [
              SearchField(
                hint: 'Search email…',
                onChanged: (v) => setState(() => _q = v),
              ),
            ],
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

/// Split CTA in the Students topbar — primary tap opens the single-add
/// dialog; the chevron opens a small menu with the bulk CSV option.
/// Sharing one button keeps both flows discoverable without cluttering
/// the topbar.
class _AddStudentsMenu extends ConsumerWidget {
  final List<LanguageSummary> taughtLanguages;
  const _AddStudentsMenu({required this.taughtLanguages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Add students',
      color: DashColors.darkBg.withValues(alpha: 0.96),
      onSelected: (key) {
        if (key == 'single') {
          _showAddStudentDialog(context, ref, taughtLanguages);
        } else if (key == 'csv') {
          _pickAndUploadCsv(context, ref, taughtLanguages);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'single',
          child: Row(
            children: [
              Icon(Icons.person_add_alt,
                  size: 14, color: DashColors.w(0.70)),
              const SizedBox(width: 10),
              const Text(
                'Add one student',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.upload_file,
                  size: 14, color: DashColors.w(0.70)),
              const SizedBox(width: 10),
              const Text(
                'Upload CSV',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: const IgnorePointer(
        child: PrimaryButton(
          label: 'Add students',
          leading: Icons.add,
        ),
      ),
    );
  }
}

Future<void> _showAddStudentDialog(
  BuildContext context,
  WidgetRef ref,
  List<LanguageSummary> taughtLanguages,
) async {
  final me = ref.read(currentUserProvider);
  if (me == null) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _AddStudentDialog(
      schoolId: me.schoolId,
      taughtLanguages: taughtLanguages,
    ),
  );
}

/// CSV upload helper: picks a CSV, asks the user which language to
/// enroll the file under, POSTs as multipart, and surfaces the
/// {added, skipped, errors} summary in a snackbar. The language ask
/// is a quick chip picker rather than a full dialog since the cohort
/// can be embedded in the CSV later.
Future<void> _pickAndUploadCsv(
  BuildContext context,
  WidgetRef ref,
  List<LanguageSummary> taughtLanguages,
) async {
  final me = ref.read(currentUserProvider);
  if (me == null || taughtLanguages.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);

  // Ask which language up front — keeps every `context` reference
  // before any async gap, so we don't have to track `mounted`.
  final lang = await showDialog<String>(
    context: context,
    builder: (ctx) => _CsvLangPicker(taughtLanguages: taughtLanguages),
  );
  if (lang == null) return;

  final picked = await FilePicker.platform.pickFiles(
    dialogTitle: 'Pick a CSV — columns: email, name, course_id',
    type: FileType.custom,
    allowedExtensions: ['csv'],
    withData: true,
  );
  if (picked == null || picked.files.isEmpty) return;
  final file = picked.files.first;

  messenger.showSnackBar(SnackBar(
    content: Text('Uploading ${file.name}…'),
    duration: const Duration(seconds: 60),
  ));
  try {
    final summary = await ref.read(dashboardApiProvider).enrollStudentsCsv(
          schoolId: me.schoolId,
          lang: lang,
          filename: file.name,
          fileBytes: file.bytes,
          // On web, PlatformFile.path throws when accessed (file_picker
          // 8.x); bytes are present via withData:true.
          filePath: kIsWeb ? null : file.path,
        );
    ref.invalidate(studentsProvider);
    ref.invalidate(schoolStatsProvider);
    ref.invalidate(activityProvider);
    final added = summary['added'] ?? 0;
    final skipped = summary['skipped'] ?? 0;
    final errors = (summary['errors'] as List?) ?? const [];
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          'Enrolled $added · skipped $skipped'
          '${errors.isEmpty ? '' : ' · ${errors.length} errors'}',
        ),
        duration: const Duration(seconds: 4),
      ));
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Upload failed: $e')));
  }
}

class _CsvLangPicker extends StatelessWidget {
  final List<LanguageSummary> taughtLanguages;
  const _CsvLangPicker({required this.taughtLanguages});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enroll under which language?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Applies to every row in the CSV. Per-row overrides land in the next pass.',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
              ),
              const SizedBox(height: 14),
              for (final l in taughtLanguages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GhostButton(
                    label: '${l.flag}  ${l.english}',
                    onTap: () => Navigator.of(context).pop(l.lang),
                  ),
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: DashColors.w(0.70),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddStudentDialog extends ConsumerStatefulWidget {
  final int schoolId;
  final List<LanguageSummary> taughtLanguages;
  const _AddStudentDialog({
    required this.schoolId,
    required this.taughtLanguages,
  });

  @override
  ConsumerState<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends ConsumerState<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _cohort = TextEditingController();
  String? _lang;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default to the first taught language so the user can submit
    // without an extra tap.
    if (widget.taughtLanguages.isNotEmpty) {
      _lang = widget.taughtLanguages.first.lang;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _cohort.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _lang == null) {
      if (_lang == null) {
        setState(() => _error = 'Pick a language');
      }
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(dashboardApiProvider).enrollStudent(
            schoolId: widget.schoolId,
            email: _email.text.trim(),
            name: _name.text.trim(),
            lang: _lang!,
            cohort:
                _cohort.text.trim().isEmpty ? null : _cohort.text.trim(),
          );
      // Refresh every roster filter combination — invalidate the
      // family root so all keyed instances refetch.
      ref.invalidate(studentsProvider);
      ref.invalidate(schoolStatsProvider);
      ref.invalidate(activityProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Could not enroll: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add student',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                _DialogField(
                  controller: _name,
                  label: 'Name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                _DialogField(
                  controller: _email,
                  label: 'Email',
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Invalid email' : null,
                ),
                const SizedBox(height: 10),
                Text('LANGUAGE', style: DashText.sectionLabel(size: 10)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final l in widget.taughtLanguages)
                      ChoiceChip(
                        label: Text('${l.flag} ${l.english}',
                            style: const TextStyle(fontSize: 11)),
                        selected: _lang == l.lang,
                        onSelected: (_) => setState(() => _lang = l.lang),
                        selectedColor: DashColors.brand,
                        backgroundColor: DashColors.w(0.06),
                        labelStyle: TextStyle(
                          color: _lang == l.lang
                              ? Colors.white
                              : DashColors.w(0.70),
                        ),
                        side: BorderSide(color: DashColors.w(0.14)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _DialogField(
                  controller: _cohort,
                  label: 'Cohort (optional)',
                  validator: (_) => null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 12, color: DashColors.red400),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: DashColors.w(0.70),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: _busy ? 'Saving…' : 'Add student',
                      leading: Icons.person_add_alt,
                      onTap: _busy ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  const _DialogField({
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
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
}
