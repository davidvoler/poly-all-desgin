import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Single-page sign-in. Shown by the router when [authProvider] is
/// [AuthSignedOut] / [AuthSigningIn]; the router swaps to the
/// dashboard automatically once login succeeds.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'lena@riverside.edu');
  final _password = TextEditingController();
  final _schoolSlug = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _schoolSlug.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signIn(
          email: _email.text.trim(),
          password: _password.text,
          schoolSlug: _schoolSlug.text.trim().isEmpty
              ? null
              : _schoolSlug.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth is AuthSigningIn;
    final error = auth is AuthSignedOut ? auth.error : null;

    return Scaffold(
      body: Container(
        decoration: kDashBackground,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BrandHeader(),
                    const SizedBox(height: 24),
                    GlassCard(
                      padding:
                          const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'School-admin dashboard',
                              style: TextStyle(
                                fontSize: 13,
                                color: DashColors.w(0.70),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LoginField(
                              controller: _email,
                              label: 'Email',
                              hint: 'you@school.edu',
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              },
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 12),
                            _LoginField(
                              controller: _password,
                              label: 'Password',
                              hint: 'Your password',
                              obscureText: !_showPassword,
                              autofillHints: const [AutofillHints.password],
                              suffix: IconButton(
                                tooltip: _showPassword ? 'Hide' : 'Show',
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 16,
                                  color: DashColors.w(0.55),
                                ),
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 12),
                            _LoginField(
                              controller: _schoolSlug,
                              label: 'School slug (optional)',
                              hint: 'riverside-academy',
                              validator: (_) => null,
                              onSubmitted: (_) => _submit(),
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 14),
                              _ErrorBanner(message: error),
                            ],
                            const SizedBox(height: 18),
                            _PrimaryCta(
                              label: isLoading ? 'Signing in…' : 'Sign in',
                              onTap: isLoading ? null : _submit,
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: DashColors.w(0.70),
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'No school yet?  Create one →',
                        style: TextStyle(
                          fontSize: 12,
                          color: DashColors.w(0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.school, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 14),
        Text(
          'POLYGLOTS · SCHOOLS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.98,
            color: DashColors.w(0.70),
          ),
        ),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  const _LoginField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
    this.suffix,
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
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle:
                TextStyle(fontSize: 13, color: DashColors.w(0.35)),
            filled: true,
            fillColor: DashColors.w(0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            errorBorder: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide: BorderSide(
                  color: DashColors.red400.withValues(alpha: 0.55)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: DashRadii.input,
              borderSide:
                  BorderSide(color: DashColors.red400),
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? Colors.white.withValues(alpha: 0.6) : Colors.white,
      shape: const StadiumBorder(),
      elevation: disabled ? 0 : 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.26,
              color: DashColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}
