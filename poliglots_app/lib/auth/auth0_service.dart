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
///
/// **Web init order matters.** The auth0_flutter_web package wraps the
/// auth0-spa-js library, which requires `onLoad()` to run **once**
/// before any other method (`loginWithRedirect`, `logout`, …). Calling
/// them in the wrong order throws "AuthClient has not been initialized".
/// We solve this by caching the `onLoad()` future on the service — the
/// first call kicks it off, every subsequent call awaits the same
/// future. That covers cold-boot restore AND the user clicking the
/// login button before restore has finished.
class Auth0Service {
  Auth0Service._();
  static final Auth0Service instance = Auth0Service._();

  Auth0? _native;
  Auth0Web? _web;

  /// The single in-flight `onLoad()` call. Null until [_ensureInit]
  /// runs on web for the first time, then the future is reused for
  /// every subsequent caller.
  Future<Credentials?>? _webOnLoad;

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

  /// Trigger Auth0 universal login. Returns the ID token (null when
  /// the user cancelled). On web the page navigates away — the token
  /// shows up on the next load via [restoreWebSession].
  ///
  /// Pass [connection] to skip Auth0's hosted picker and go straight
  /// to a specific identity provider. Examples:
  ///   • `google-oauth2` — Google sign-in
  ///   • `apple`         — Apple
  ///   • `Username-Password-Authentication` — Auth0 DB connection
  /// Leave null to show Auth0's full universal-login UI.
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
      await _web!.loginWithRedirect(
        redirectUrl: redirect.isEmpty ? null : redirect,
        audience: audience.isEmpty ? null : audience,
        parameters: parameters,
      );
      return null;
    }
    final creds = await _native!.webAuthentication().login(
          audience: audience.isEmpty ? null : audience,
          redirectUrl: redirect.isEmpty ? null : redirect,
          parameters: parameters,
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
