import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import '../config/app_config.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Sign-in screen for the learner app. Shown by the auth gate in
/// `main.dart` when [authProvider] is signed-out.
///
/// CTAs depend on `AUTH_PROVIDER` + `IS_DEV`:
///   * `auth0`           → "Sign in with Google" hands off to Auth0's
///     google-oauth2 connection, then exchanges the ID token for a
///     session cookie via /api/v1/auth/get_or_create_user.
///   * `IS_DEV=true`     → also renders an email + password form so
///     the test loop doesn't have to round-trip through Google. Works
///     against /login_with_password.
///   * `AUTH_PROVIDER=local` → "Continue as guest" mints a throwaway
///     dev session against the server's unverified-email fallback.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Pre-fills for the dev password form — one tap to sign up the demo
  // user, subsequent taps verify the same password.
  final _email = TextEditingController(text: 'demo@local.dev');
  final _password = TextEditingController(text: 'changeme');
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signInGoogle() async {
    await ref.read(authProvider.notifier).signInWithGoogle();
  }

  Future<void> _signInPassword() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) return;
    await ref
        .read(authProvider.notifier)
        .signInWithPassword(email: email, password: password);
  }

  Future<void> _continueAsGuest() async {
    await ref
        .read(authProvider.notifier)
        .continueAsGuest(email: 'guest@local.dev');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final loading = auth is AuthSigningIn;
    final error = auth is AuthSignedOut ? auth.error : null;
    final auth0Enabled = AppConfig.isAuth0Enabled;
    final showPasswordForm = AppConfig.isDev;

    return Scaffold(
      body: PhoneBackground(
        showMosaic: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHero(),
                    const SizedBox(height: 32),
                    Text(
                      'Sign in',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      auth0Enabled
                          ? 'Use your Google account to keep your progress in sync.'
                          : 'Local dev mode — Auth0 is off. Continue as a guest '
                              'and the server will mint a throwaway user for you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.4,
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 18),
                      _ErrorBanner(message: error),
                    ],
                    const SizedBox(height: 22),
                    // Production: single Google CTA — clicking it goes
                    // straight to Auth0's google-oauth2 connection,
                    // skipping the universal-login picker entirely.
                    if (auth0Enabled)
                      _PrimaryCta(
                        label: loading
                            ? 'Opening Google…'
                            : 'Sign in with Google',
                        icon: Icons.lock_outline,
                        onTap: loading ? null : _signInGoogle,
                      ),
                    // Dev-only email + password form, gated on IS_DEV.
                    // Lets us skip the Google round-trip in test loops.
                    if (showPasswordForm) ...[
                      if (auth0Enabled) ...[
                        const SizedBox(height: 16),
                        _OrDivider(),
                        const SizedBox(height: 16),
                      ],
                      _CredField(
                        controller: _email,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onSubmit: _signInPassword,
                      ),
                      const SizedBox(height: 10),
                      _CredField(
                        controller: _password,
                        label: 'Password',
                        obscureText: !_showPassword,
                        autofillHints: const [AutofillHints.password],
                        onSubmit: _signInPassword,
                        suffix: IconButton(
                          tooltip: _showPassword ? 'Hide' : 'Show',
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PrimaryCta(
                        label: loading ? 'Signing in…' : 'Sign in',
                        icon: Icons.arrow_forward,
                        onTap: loading ? null : _signInPassword,
                      ),
                    ],
                    // Guest button — only meaningful in local mode
                    // (the server's unverified-email fallback is gated
                    // behind AUTH0_DOMAIN being unset). On production
                    // it would 400, so we hide it.
                    if (!auth0Enabled) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: loading ? null : _continueAsGuest,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.70),
                          ),
                          child: const Text(
                            'Continue as guest',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
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

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PolyColors.brandPrimary, PolyColors.blue800],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.language, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 14),
        Text(
          'POLYGLOTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

/// Thin horizontal divider with an "OR" label, separating the Google
/// CTA from the dev-only password form when both are visible.
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.14),
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
        line,
      ],
    );
  }
}

class _CredField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final VoidCallback onSubmit;
  final Widget? suffix;
  const _CredField({
    required this.controller,
    required this.label,
    required this.onSubmit,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        isDense: true,
        hintText: label,
        hintStyle: TextStyle(
            fontSize: 13, color: Colors.white.withValues(alpha: 0.45)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: PolyColors.brandPrimary.withValues(alpha: 0.55)),
        ),
        suffixIcon: suffix,
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const _PrimaryCta({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled
          ? Colors.white.withValues(alpha: 0.55)
          : Colors.white,
      shape: const StadiumBorder(),
      elevation: disabled ? 0 : 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: PolyColors.brandPrimary),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.28,
                  color: PolyColors.brandPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
