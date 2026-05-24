import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import '../config/app_config.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Sign-in screen for the learner app. Shown by the auth gate in
/// `main.dart` when [authProvider] is signed-out.
///
/// Two CTAs depending on `AUTH_PROVIDER`:
///   * `auth0`  → "Sign in with Auth0" hands off to Auth0 universal
///     login, then exchanges the ID token for a session cookie via
///     /api/v1/auth/get_or_create_user.
///   * `local`  → "Continue as guest" mints a throwaway dev session
///     against the server's unverified-email fallback. Lets a fresh
///     `flutter run` Just Work without an Auth0 tenant.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Pre-fills the guest-email field when AUTH_PROVIDER=local so the
  // user just taps the button.
  final _email = TextEditingController(text: 'guest@local.dev');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _signInAuth0() async {
    await ref.read(authProvider.notifier).signInWithAuth0();
  }

  Future<void> _continueAsGuest() async {
    final email = _email.text.trim();
    await ref
        .read(authProvider.notifier)
        .continueAsGuest(email: email.isEmpty ? 'guest@local.dev' : email);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final loading = auth is AuthSigningIn;
    final error = auth is AuthSignedOut ? auth.error : null;
    final auth0Enabled = AppConfig.isAuth0Enabled;

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
                          ? 'Use your Auth0 account to keep your progress in sync.'
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
                    if (auth0Enabled)
                      _PrimaryCta(
                        label: loading ? 'Opening Auth0…' : 'Sign in with Auth0',
                        icon: Icons.lock_outline,
                        onTap: loading ? null : _signInAuth0,
                      )
                    else ...[
                      _GuestEmailField(controller: _email, onSubmit: _continueAsGuest),
                      const SizedBox(height: 14),
                      _PrimaryCta(
                        label: loading
                            ? 'Signing in…'
                            : 'Continue as guest',
                        icon: Icons.arrow_forward,
                        onTap: loading ? null : _continueAsGuest,
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

class _GuestEmailField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _GuestEmailField({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Email',
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
