import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised access to runtime configuration loaded from
/// `assets/.env` at app startup (see [AppConfig.load]) and overridable
/// at build time via `--dart-define`.
///
/// Precedence (highest first):
///   1. `--dart-define=KEY=value` passed to `flutter run` / `flutter build`
///   2. The matching row in `assets/.env`
///   3. The hardcoded default below
///
/// Keep getters narrow — every config value has exactly one canonical
/// reader so a misspelling fails loud at the call site rather than
/// silently returning a default.
class AppConfig {
  AppConfig._();

  /// Must be awaited once before `runApp`. Failure to load is
  /// non-fatal: missing `.env` simply falls through to dart-defines +
  /// defaults so a fresh checkout still runs.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: 'assets/.env');
    } catch (_) {
      // No .env in the bundle yet — that's fine, the defaults below
      // are tuned for a local `docker compose up`.
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

  /// Server base URL the Dio client points at.
  static String get apiBaseUrl => _read(
        'API_BASE_URL',
        fromEnv: const String.fromEnvironment('API_BASE_URL'),
        defaultValue: 'http://127.0.0.1:8004',
      );

  /// Audio CDN — unused by the dashboard today but kept for parity
  /// with poliglots_app so a single shared .env shape works.
  static String get audioBaseUrl => _read(
        'AUDIO_BASE_URL',
        fromEnv: const String.fromEnvironment('AUDIO_BASE_URL'),
        defaultValue: 'http://127.0.0.1:3002/audio',
      );

  /// `local` | `auth0` | `both`. `local` (the default) keeps the
  /// existing email + password form so a fresh dev checkout never
  /// needs Auth0 credentials.
  static String get authProvider => _read(
        'AUTH_PROVIDER',
        fromEnv: const String.fromEnvironment('AUTH_PROVIDER'),
        defaultValue: 'local',
      ).toLowerCase();

  static bool get isAuth0Enabled =>
      authProvider == 'auth0' || authProvider == 'both';

  static bool get isLocalAuthEnabled =>
      authProvider == 'local' || authProvider == 'both';

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
  /// e.g. the login page keeps the email/password form so testing
  /// admin flows doesn't require a Google round-trip each time.
  static bool get isDev {
    final v = _read(
      'IS_DEV',
      fromEnv: const String.fromEnvironment('IS_DEV'),
      defaultValue: 'false',
    ).toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }
}
