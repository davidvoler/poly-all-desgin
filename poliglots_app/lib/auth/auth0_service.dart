import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Thin wrapper around `auth0_flutter` for the learner app. Mirrors
/// the dashboard's wrapper so both apps speak the same auth shape.
///
/// On `AUTH_PROVIDER=local` (the default) nothing here ever runs — the
/// login page hands the user a "Continue as guest" path that the dev
/// fallback on the server accepts.
class Auth0Service {
  Auth0Service._();
  static final Auth0Service instance = Auth0Service._();

  Auth0? _native;
  Auth0Web? _web;

  Future<void> _ensureInit() async {
    if (!AppConfig.isAuth0Enabled) {
      throw StateError(
          'Auth0 is disabled (AUTH_PROVIDER=${AppConfig.authProvider}).');
    }
    final domain = AppConfig.auth0Domain;
    final clientId = AppConfig.auth0ClientId;
    if (domain.isEmpty || clientId.isEmpty) {
      throw StateError(
          'AUTH0_DOMAIN and AUTH0_CLIENT_ID must be set in assets/.env.');
    }
    if (kIsWeb) {
      _web ??= Auth0Web(domain, clientId);
    } else {
      _native ??= Auth0(domain, clientId);
    }
  }

  /// Trigger Auth0 universal login. Returns the ID token (null when
  /// the user cancelled). On web the page navigates away — the token
  /// shows up on the next load via [restoreWebSession].
  Future<String?> signIn() async {
    await _ensureInit();
    final audience = AppConfig.auth0Audience;
    final redirect = AppConfig.auth0RedirectUri;

    if (kIsWeb) {
      await _web!.loginWithRedirect(
        redirectUrl: redirect.isEmpty ? null : redirect,
        audience: audience.isEmpty ? null : audience,
      );
      return null;
    }
    final creds = await _native!.webAuthentication().login(
          audience: audience.isEmpty ? null : audience,
          redirectUrl: redirect.isEmpty ? null : redirect,
        );
    return creds.idToken;
  }

  /// On Flutter web, finish the OAuth redirect handshake by reading
  /// the `code` + `state` from the URL Auth0 sent us back to. Returns
  /// the ID token if a session was completed. No-op elsewhere.
  Future<String?> restoreWebSession() async {
    if (!kIsWeb || !AppConfig.isAuth0Enabled) return null;
    try {
      await _ensureInit();
      final creds = await _web!.onLoad();
      return creds?.idToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    if (!AppConfig.isAuth0Enabled) return;
    if (kIsWeb) {
      await _web?.logout(returnToUrl: AppConfig.auth0RedirectUri);
    } else {
      await _native?.webAuthentication().logout();
    }
  }
}
