import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';

/// Auth0 universal login, as in the dashboard (dashboard/lib/auth/
/// auth0_service.dart). Returns the ID token that the editor server
/// verifies against the tenant's keys.
///
/// On the web, auth0-spa-js needs `onLoad()` to run once before any other
/// call, so the first caller starts it and the rest await the same future.
class Auth0Service {
  Auth0Service._();
  static final instance = Auth0Service._();

  Auth0? _native;
  Auth0Web? _web;
  Future<Credentials?>? _webOnLoad;

  void _ensureInit() {
    if (!AppConfig.isAuth0Enabled) {
      throw StateError('Auth0 sign-in is not configured for this build.');
    }
    if (kIsWeb) {
      _web ??= Auth0Web(AppConfig.auth0Domain, AppConfig.auth0ClientId);
      if (_webOnLoad == null) {
        final onLoad = _web!.onLoad();
        _webOnLoad = onLoad;
        // Retry from scratch next time instead of replaying a failure.
        onLoad.catchError((Object e) {
          debugPrint('Auth0Web.onLoad() failed: $e');
          _webOnLoad = null;
          throw e;
        });
      }
    } else {
      _native ??= Auth0(AppConfig.auth0Domain, AppConfig.auth0ClientId);
    }
  }

  String? get _audience =>
      AppConfig.auth0Audience.isEmpty ? null : AppConfig.auth0Audience;

  /// Opens Auth0's login, straight to [connection] (e.g. `google-oauth2`)
  /// when given. On the web the page navigates away and the token arrives
  /// on return through [restoreWebSession], so this returns null.
  Future<String?> signIn({String? connection}) async {
    _ensureInit();
    final parameters = {
      if (connection != null && connection.isNotEmpty) 'connection': connection,
    };
    if (kIsWeb) {
      final existing = await _webOnLoad;
      if (existing != null) return existing.idToken;
      await _web!.loginWithRedirect(
        redirectUrl: AppConfig.auth0RedirectUri,
        audience: _audience,
        parameters: parameters,
      );
      return null;
    }
    final credentials = await _native!.webAuthentication().login(
      audience: _audience,
      parameters: parameters,
    );
    return credentials.idToken;
  }

  /// The ID token when the page loads on the way back from Auth0's login.
  Future<String?> restoreWebSession() async {
    if (!kIsWeb || !AppConfig.isAuth0Enabled) return null;
    try {
      _ensureInit();
      return (await _webOnLoad)?.idToken;
    } catch (e) {
      debugPrint('Auth0 restoreWebSession failed: $e');
      return null;
    }
  }

  /// Ends the Auth0 session too, so it does not sign the user straight back in.
  Future<void> signOut() async {
    if (!AppConfig.isAuth0Enabled) return;
    if (kIsWeb) {
      try {
        _ensureInit();
        await _webOnLoad;
      } catch (_) {}
      await _web?.logout(returnToUrl: AppConfig.auth0RedirectUri);
    } else {
      await _native?.webAuthentication().logout();
    }
  }
}
