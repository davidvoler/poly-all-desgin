import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Thin wrapper around `auth0_flutter` so the rest of the codebase
/// doesn't import the SDK directly. Only constructed lazily — on
/// `AUTH_PROVIDER=local` (the default) nothing here ever runs, so a
/// fresh dev checkout doesn't need Auth0 credentials to launch.
///
/// Web vs. native: `auth0_flutter` has two entry points. We use
/// [Auth0Web] when running in a browser (Flutter web's `kIsWeb`) and
/// the mobile-style [Auth0] elsewhere. Both ultimately return an ID
/// token that the server validates via JWKS.
///
/// **Web init order matters.** The auth0_flutter_web package wraps the
/// auth0-spa-js library, which requires `onLoad()` to run **once**
/// before any other method. Calling them in the wrong order throws
/// "AuthClient has not been initialized". We cache the `onLoad()`
/// future on the service so the first caller kicks it off and every
/// subsequent caller awaits the same result.
class Auth0Service {
  Auth0Service._();
  static final Auth0Service instance = Auth0Service._();

  Auth0? _native;
  Auth0Web? _web;

  /// The single in-flight `onLoad()` call. Null until [_ensureInit]
  /// runs on web for the first time, then reused for every caller.
  Future<Credentials?>? _webOnLoad;

  /// Idempotent — safe to call from the login button's onTap.
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
      // Kick off the one-shot client init lazily. Subsequent calls
      // hit the cached future so onLoad runs exactly once even if
      // restore + signIn race.
      _webOnLoad ??= _web!.onLoad();
    } else {
      _native ??= Auth0(domain, clientId);
    }
  }

  /// Open the Auth0 universal login UI and return the resulting ID
  /// token (null if the user cancelled). Audience is included when
  /// configured so the access token is API-ready, though the dashboard
  /// only needs the ID token to call `/login_auth0`.
  ///
  /// Pass [connection] to skip Auth0's hosted picker and go straight
  /// to a specific identity provider (e.g. `google-oauth2`).
  Future<String?> signIn({String? connection}) async {
    await _ensureInit();
    final audience = AppConfig.auth0Audience;
    final redirect = AppConfig.auth0RedirectUri;
    final parameters = <String, String>{
      if (connection != null && connection.isNotEmpty) 'connection': connection,
    };

    if (kIsWeb) {
      // Make sure the underlying SPA client is fully initialized
      // before loginWithRedirect — otherwise the SDK throws
      // "AuthClient has not been initialized".
      final existing = await _webOnLoad;
      if (existing != null) {
        // User is already signed in (e.g. came back from a successful
        // redirect that the restore path didn't pick up). Return the
        // existing token rather than triggering another redirect.
        return existing.idToken;
      }
      // On web, `loginWithRedirect` navigates away. The token shows up
      // on the next page load via `onLoad` — see [restoreWebSession].
      await _web!.loginWithRedirect(
        redirectUrl: redirect.isEmpty ? null : redirect,
        audience: audience.isEmpty ? null : audience,
        parameters: parameters,
      );
      return null; // Page is being redirected; never reached.
    }

    final creds = await _native!.webAuthentication().login(
          audience: audience.isEmpty ? null : audience,
          redirectUrl: redirect.isEmpty ? null : redirect,
          parameters: parameters,
        );
    return creds.idToken;
  }

  /// On Flutter web the Auth0 redirect callback drops the user back on
  /// the dashboard with `?code=…&state=…` in the URL. Call this once
  /// from `main.dart` after [AppConfig.load] so the SDK can finish the
  /// handshake and surface the resulting credentials. Returns the ID
  /// token if a session was completed, otherwise null. No-op on
  /// native targets.
  Future<String?> restoreWebSession() async {
    if (!kIsWeb || !AppConfig.isAuth0Enabled) return null;
    try {
      await _ensureInit();
      final creds = await _webOnLoad;
      return creds?.idToken;
    } catch (e, st) {
      // Log instead of swallowing so a misconfiguration shows up in
      // the JS console rather than masquerading as "no session".
      debugPrint('Auth0 restoreWebSession failed: $e\n$st');
      return null;
    }
  }

  Future<void> signOut() async {
    if (!AppConfig.isAuth0Enabled) return;
    if (kIsWeb) {
      // Same init dance as signIn — logout also requires the client
      // to be initialized first.
      try {
        await _ensureInit();
        await _webOnLoad;
      } catch (_) {/* fall through; the JS logout is best-effort */}
      await _web?.logout(returnToUrl: AppConfig.auth0RedirectUri);
    } else {
      await _native?.webAuthentication().logout();
    }
  }
}
