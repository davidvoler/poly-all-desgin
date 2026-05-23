import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/data_table.dart';
import '../widgets/shell.dart';

class EditorsPage extends ConsumerWidget {
  const EditorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(schoolUsersProvider);
    return DashboardShell(
      title: 'Editors',
      activeRoute: '/editors',
      topbarTrailing: [
        PrimaryButton(
          label: 'Invite editor',
          leading: Icons.mail_outline,
          onTap: () => _showInviteDialog(context, ref),
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
              'Could not load editors\n$e',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
            ),
          ),
        ),
        data: (rows) {
          final activeCount = rows.where((r) => r.status == 'active').length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeadRow(
                label: 'Team',
                subtitle: '·  **$activeCount** active',
              ),
              if (rows.isEmpty)
                _emptyState()
              else
                _EditorsTable(rows: rows),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        'No editors yet — invite the first one above.',
        style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _InviteEditorDialog(schoolId: me.schoolId),
    );
  }
}

class _EditorsTable extends StatelessWidget {
  final List<SchoolUser> rows;
  const _EditorsTable({required this.rows});

  StatusPill _rolePill(EditorRoleWire role) {
    switch (role) {
      case EditorRoleWire.owner:
        return const StatusPill(
          label: 'Owner',
          kind: PillKind.white,
          swatch: true,
        );
      case EditorRoleWire.editor:
        return const StatusPill(
          label: 'Editor',
          kind: PillKind.neutral,
          swatch: true,
        );
      case EditorRoleWire.viewer:
        return const StatusPill(
          label: 'Viewer',
          kind: PillKind.muted,
          swatch: true,
        );
    }
  }

  String _langLabel(SchoolUser u) {
    if (u.assignedLanguages.isEmpty) return 'All';
    return u.assignedLanguages.join(', ').toUpperCase();
  }

  String _avatarKey(int id) {
    const keys = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return keys[id.abs() % keys.length];
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
        for (final e in rows)
          [
            WhoCell(
              initials: e.initials,
              avatarKey:
                  e.role == EditorRoleWire.owner ? 'lh' : _avatarKey(e.schoolUserId),
              name: e.name.isNotEmpty ? e.name : e.email,
              email: e.email,
            ),
            Align(alignment: Alignment.centerLeft, child: _rolePill(e.role)),
            Text(_langLabel(e)),
            Text('${e.coursesOwned}'),
            Text(
              e.lastSeenHuman ?? 'Never',
              style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                label: e.status == 'active' ? 'Active' : 'Off',
                kind: e.status == 'active' ? PillKind.active : PillKind.muted,
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

class _InviteEditorDialog extends ConsumerStatefulWidget {
  final int schoolId;
  const _InviteEditorDialog({required this.schoolId});

  @override
  ConsumerState<_InviteEditorDialog> createState() =>
      _InviteEditorDialogState();
}

class _InviteEditorDialogState extends ConsumerState<_InviteEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'editor';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(dashboardApiProvider).createSchoolUser(
            schoolId: widget.schoolId,
            name: _name.text.trim(),
            email: _email.text.trim(),
            password:
                _password.text.isEmpty ? null : _password.text,
            role: _role,
          );
      ref.invalidate(schoolUsersProvider);
      ref.invalidate(schoolStatsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Could not invite editor: $e';
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
                  'Invite editor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _name,
                  label: 'Name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                _Field(
                  controller: _email,
                  label: 'Email',
                  validator: (v) => (v == null ||
                          !v.contains('@'))
                      ? 'Invalid email'
                      : null,
                ),
                const SizedBox(height: 10),
                _Field(
                  controller: _password,
                  label: 'Password (optional)',
                  obscureText: true,
                  validator: (_) => null,
                ),
                const SizedBox(height: 10),
                Text('ROLE', style: DashText.sectionLabel(size: 10)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final r in const ['owner', 'editor', 'viewer'])
                      ChoiceChip(
                        label: Text(r.toUpperCase(),
                            style: const TextStyle(fontSize: 11)),
                        selected: _role == r,
                        onSelected: (_) => setState(() => _role = r),
                        selectedColor: DashColors.brand,
                        backgroundColor: DashColors.w(0.06),
                        labelStyle: TextStyle(
                          color: _role == r ? Colors.white : DashColors.w(0.70),
                        ),
                        side: BorderSide(color: DashColors.w(0.14)),
                      ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: DashColors.red400,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: DashColors.w(0.70),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: _busy ? 'Saving…' : 'Send invite',
                      leading: Icons.send,
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  const _Field({
    required this.controller,
    required this.label,
    this.obscureText = false,
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
          obscureText: obscureText,
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
