/// Build-time settings, from `--dart-define-from-file=env/<env>.json`
/// (see scripts/build-web.sh). Without them the app runs against the local
/// server with email + password sign-in.
class AppConfig {
  AppConfig._();

  /// `local` (email + password), `auth0` (Continue with Google) or `both`,
  /// as in the app and dashboard.
  static const authProvider = String.fromEnvironment(
    'AUTH_PROVIDER',
    defaultValue: 'local',
  );

  static const auth0Domain = String.fromEnvironment('AUTH0_DOMAIN');
  static const auth0ClientId = String.fromEnvironment('AUTH0_CLIENT_ID');
  static const auth0Audience = String.fromEnvironment('AUTH0_AUDIENCE');

  /// Shows the email + password form; production signs in with Google only,
  /// as in the dashboard.
  static const isDev =
      String.fromEnvironment('IS_DEV', defaultValue: 'true') == 'true';

  static bool get isAuth0Enabled =>
      (authProvider == 'auth0' || authProvider == 'both') &&
      auth0Domain.isNotEmpty &&
      auth0ClientId.isNotEmpty;

  static bool get isPasswordEnabled =>
      isDev && (authProvider == 'local' || authProvider == 'both');

  /// Auth0 returns to the page the editor was opened on.
  static String get auth0RedirectUri => Uri.base.origin;
}
