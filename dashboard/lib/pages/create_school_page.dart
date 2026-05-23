import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// First-run onboarding wizard for a brand-new school. Mirrors the
/// `create-school.html` design prototype: top bar with "Cancel",
/// centered glass card with hero + form. On submit we POST
/// /api/v1/school/ and immediately log in with the same credentials
/// so the user lands inside the new tenant without a second screen.
class CreateSchoolPage extends ConsumerStatefulWidget {
  const CreateSchoolPage({super.key});

  @override
  ConsumerState<CreateSchoolPage> createState() => _CreateSchoolPageState();
}

class _CreateSchoolPageState extends ConsumerState<CreateSchoolPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerPassword = TextEditingController();
  // Default to public school per the new requirement: most onboarding
  // flows in the open-content variant should be one-click.
  bool _isPublic = true;
  // Plan is fixed at 'free' during onboarding — users tune it later
  // from Settings → Subscription plans.
  final String _plan = 'free';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _ownerName.dispose();
    _ownerEmail.dispose();
    _ownerPassword.dispose();
    super.dispose();
  }

  /// Auto-derive a URL slug from the school name so the user doesn't
  /// have to think about it. Lowercase, swap whitespace + non-alnum
  /// for dashes, collapse repeats, trim.
  void _syncSlug(String name) {
    if (_slug.text.isNotEmpty && _slug.text != _previousAutoSlug) return;
    final clean = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    setState(() {
      _slug.text = clean;
      _previousAutoSlug = clean;
    });
  }

  String _previousAutoSlug = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await ref.read(dashboardApiProvider).createSchoolAndSignIn(
            slug: _slug.text.trim(),
            name: _name.text.trim(),
            plan: _plan,
            isPublic: _isPublic,
            ownerName: _ownerName.text.trim(),
            ownerEmail: _ownerEmail.text.trim(),
            ownerPassword: _ownerPassword.text,
          );
      await ref.read(authProvider.notifier).adoptSession(info);
      // Gate flips to OverviewPage automatically on the next rebuild.
    } catch (e) {
      setState(() {
        _busy = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('409') || s.contains('Slug already in use')) {
      return 'That URL slug is taken. Try another.';
    }
    return 'Could not create the school. $s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: kDashBackground,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: GlassCard(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                          child: _form(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        children: [
          Text(
            'POLYGLOTS · SCHOOLS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.98,
              color: DashColors.w(0.70),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed:
                _busy ? null : () => Navigator.of(context).pushReplacementNamed('/'),
            style: TextButton.styleFrom(
              foregroundColor: DashColors.w(0.70),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [DashColors.brand, DashColors.blue900],
                ),
              ),
              child:
                  const Icon(Icons.school, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Set up your school',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A few quick questions to get started — you can change everything later in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: DashColors.w(0.70)),
          ),
          const SizedBox(height: 20),
          _Field(
            controller: _name,
            label: 'School name',
            hint: 'Riverside Academy',
            onChanged: _syncSlug,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: _slug,
            label: 'URL slug',
            hint: 'riverside-academy',
            prefix: 'polyglots.app/',
            hintBelow:
                'Lowercase letters, numbers, and dashes — students join here.',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) {
                return 'Lowercase letters, numbers, and dashes only';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Public vs. private toggle — the only decision that affects
          // schema behaviour right now (public schools skip the
          // language whitelist + are free for students).
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DashColors.w(0.04),
              borderRadius: DashRadii.input,
              border: Border.all(color: DashColors.w(0.14)),
            ),
            child: SwitchListTile(
              value: _isPublic,
              onChanged: _busy ? null : (v) => setState(() => _isPublic = v),
              activeThumbColor: DashColors.brand,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Public school',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                _isPublic
                    ? 'Anyone can join · all content is free · any language goes'
                    : 'Members only · billable plans · limited to the languages you choose',
                style: TextStyle(
                  fontSize: 11,
                  color: DashColors.w(0.55),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('OWNER ACCOUNT', style: DashText.sectionLabel(size: 10)),
          const SizedBox(height: 6),
          _Field(
            controller: _ownerName,
            label: 'Your name',
            hint: 'Lena Hayes',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: _ownerEmail,
            label: 'Email',
            hint: 'you@school.edu',
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Invalid email' : null,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: _ownerPassword,
            label: 'Password',
            hint: '12+ characters',
            obscureText: true,
            validator: (v) {
              if (v == null || v.length < 8) {
                return 'At least 8 characters';
              }
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: DashColors.red400.withValues(alpha: 0.12),
                borderRadius: DashRadii.cardSm,
                border: Border.all(
                    color: DashColors.red400.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 16, color: DashColors.red400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              const Spacer(),
              PrimaryButton(
                label: _busy ? 'Creating…' : 'Create school',
                leading: Icons.arrow_forward,
                onTap: _busy ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inline form field — separate from the login-page version so the
/// onboarding flow can have its own label-above-input layout + hint
/// row without coupling the two pages.
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? prefix;
  final String? hintBelow;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefix,
    this.hintBelow,
    this.obscureText = false,
    this.validator,
    this.onChanged,
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
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle:
                TextStyle(fontSize: 13, color: DashColors.w(0.35)),
            prefixIcon: prefix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                    child: Text(
                      prefix!,
                      style: TextStyle(
                        fontSize: 13,
                        color: DashColors.w(0.55),
                      ),
                    ),
                  ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
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
              borderSide: BorderSide(
                  color: DashColors.brand.withValues(alpha: 0.55)),
            ),
          ),
        ),
        if (hintBelow != null) ...[
          const SizedBox(height: 6),
          Text(
            hintBelow!,
            style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
          ),
        ],
      ],
    );
  }
}
