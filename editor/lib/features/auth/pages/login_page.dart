import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth.dart';

/// Sign in with the same accounts as the app and dashboard: Continue with
/// Google (Auth0), and email + password in development builds. Only the
/// school's editors get in.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .signIn(email: email.text.trim(), password: password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final busy = auth is AuthSigningIn;
    final error = auth is AuthSignedOut ? auth.error : null;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4E0D9)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.language, color: Color(0xFF1E88E5)),
                        SizedBox(width: 10),
                        Text(
                          'Polyglots Editor',
                          style: TextStyle(
                            color: Color(0xFF17252D),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sign in',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17252D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Course editor, for your school\'s editors.',
                      style: TextStyle(color: Color(0xFF748087), fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    if (error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEEEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          error,
                          style: const TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (googleSignInEnabled)
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => ref
                                  .read(authProvider.notifier)
                                  .signInWithGoogle(),
                        icon: const Icon(Icons.account_circle_outlined),
                        label: const Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    if (googleSignInEnabled && passwordSignInEnabled)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(color: Color(0xFF8A979A)),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                    if (passwordSignInEnabled) ...[
                      TextFormField(
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter your email'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: password,
                        enabled: !busy,
                        obscureText: !showPassword,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: showPassword
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: () =>
                                setState(() => showPassword = !showPassword),
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter your password'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                    ],
                    if (!googleSignInEnabled && !passwordSignInEnabled)
                      const Text(
                        'No sign-in method is configured for this build. '
                        'Set AUTH_PROVIDER and the Auth0 settings in '
                        'env/<env>.json.',
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
