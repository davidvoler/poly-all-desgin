import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised runtime config for the learner app. Mirrors the
/// dashboard's [AppConfig] so the two apps speak the same env shape.
///
/// Precedence (highest first):
///   1. `--dart-define=KEY=value` passed to `flutter run` / `flutter build`
///   2. The matching row in `assets/.env`
///   3. The hardcoded default below
class AppConfig {
  AppConfig._();

  /// Must be awaited once before `runApp`. Failure to load is
  /// non-fatal: missing `.env` falls through to dart-defines +
  /// defaults so a fresh checkout still runs.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: 'assets/.env');
    } catch (_) {
      // No .env in the bundle — defaults below are tuned for the
      // local `docker compose up` stack.
    }
  }

  static String _read(
    String key, {
    required String fromEnv,
    required String defaultValue,
  }) {
    if (fromEnv.isNotEmpty) return fromEnv;
    final v = dotenv.maybeGet(key);
    if (v != null && v.isNotEmpty) return v;
    return defaultValue;
  }

  // Use `localhost` (not 127.0.0.1) so the API origin shares a
  // registrable domain with `flutter run -d chrome` (also serves
  // on localhost). Cross-host between the two breaks SameSite=Lax
  // cookies; same-host keeps the auth cookie flowing.
  static String get apiBaseUrl => _read(
        'API_BASE_URL',
        fromEnv: const String.fromEnvironment('API_BASE_URL'),
        defaultValue: 'http://localhost:8004',
      );

  static String get audioBaseUrl => _read(
        'AUDIO_BASE_URL',
        fromEnv: const String.fromEnvironment('AUDIO_BASE_URL'),
        defaultValue: 'http://localhost:3002/audio',
      );

  /// `local` | `auth0`. `local` (default) keeps a guest-friendly dev
  /// flow — the login page shows a "Continue as guest" CTA that
  /// short-circuits to the legacy user_id=1 session.
  static String get authProvider => _read(
        'AUTH_PROVIDER',
        fromEnv: const String.fromEnvironment('AUTH_PROVIDER'),
        defaultValue: 'local',
      ).toLowerCase();

  static bool get isAuth0Enabled => authProvider == 'auth0';

  static String get auth0Domain => _read(
        'AUTH0_DOMAIN',
        fromEnv: const String.fromEnvironment('AUTH0_DOMAIN'),
        defaultValue: '',
      );

  static String get auth0ClientId => _read(
        'AUTH0_CLIENT_ID',
        fromEnv: const String.fromEnvironment('AUTH0_CLIENT_ID'),
        defaultValue: '',
      );

  static String get auth0Audience => _read(
        'AUTH0_AUDIENCE',
        fromEnv: const String.fromEnvironment('AUTH0_AUDIENCE'),
        defaultValue: '',
      );

  static String get auth0RedirectUri => _read(
        'AUTH0_REDIRECT_URI',
        fromEnv: const String.fromEnvironment('AUTH0_REDIRECT_URI'),
        defaultValue: '',
      );

  /// True in non-production builds. Surfaces dev-only affordances —
  /// e.g. the login page keeps an email/password form so we don't
  /// have to round-trip through Google every test session.
  static bool get isDev {
    final v = _read(
      'IS_DEV',
      fromEnv: const String.fromEnvironment('IS_DEV'),
      defaultValue: 'false',
    ).toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }
}
