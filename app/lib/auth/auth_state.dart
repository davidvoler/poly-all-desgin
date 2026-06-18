import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/courses_api.dart';
import '../config/app_config.dart';
import 'auth0_service.dart';

/// SharedPreferences key for the cached `user_id`. The server-side
/// HttpOnly cookie is the source of truth; this cache is just so cold
/// boots can paint the home screen optimistically while the
/// /login_with_cookie round-trip is in flight.
const String _kUserIdCacheKey = 'poly_app_user_id_v1';

/// Four states the app routes off of. Mirrors the dashboard's auth
/// notifier so the two apps follow the same lifecycle.
sealed class AuthState {
  const AuthState();
}

/// Initial state — we haven't asked the server (or SharedPreferences)
/// whether a previous session exists. The router paints a splash for
/// this brief window so we don't flash the login page first.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

class AuthSignedOut extends AuthState {
  /// Last error to show on the login page, if any.
  final String? error;
  const AuthSignedOut({this.error});
}

class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

class AuthSignedIn extends AuthState {
  final int userId;
  final String email;
  final String? name;
  const AuthSignedIn({
    required this.userId,
    required this.email,
    this.name,
  });
}

/// The current user_id, or null when signed out. Read this from any
/// widget that used to pull from `kCurrentUserId`.
final currentUserIdProvider = Provider<int?>((ref) {
  final s = ref.watch(authProvider);
  return s is AuthSignedIn ? s.userId : null;
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthRestoring();
  }

  /// Cold-boot path. Tries, in order:
  ///   1. Auth0 web-redirect handshake (no-op when not on web / not
  ///      using auth0) — completes the redirect from a fresh sign-in.
  ///   2. /login_with_cookie — uses the server-side HttpOnly cookie.
  ///   3. SharedPreferences cache — last-known user_id, painted
  ///      optimistically and verified against /login_with_cookie.
  Future<void> _restore() async {
    try {
      // (1) Auth0 redirect callback — only fires on web after the
      // user just came back from auth0's login page.
      if (AppConfig.isAuth0Enabled) {
        try {
          final idToken = await Auth0Service.instance.restoreWebSession();
          if (idToken != null && idToken.isNotEmpty) {
            await _exchangeIdToken(idToken);
            return;
          }
        } catch (_) {
          // Fall through; cookie or cache might still get us in.
        }
      }

      // (2) Server-side cookie.
      try {
        final res = await ref
            .read(authApiProvider)
            .loginWithCookie();
        await _persist(res.userId);
        setCurrentUserId(res.userId);
        state = AuthSignedIn(
            userId: res.userId, email: res.email, name: res.name);
        return;
      } on DioException {
        // 401 → no cookie. Fall through to the local cache.
      }

      // (3) Local cache. Optimistic: we trust the cached id only
      // until a real call comes back and clarifies things.
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getInt(_kUserIdCacheKey);
      if (cached != null) {
        setCurrentUserId(cached);
        state = AuthSignedIn(userId: cached, email: '', name: null);
        return;
      }

      state = const AuthSignedOut();
    } catch (_) {
      state = const AuthSignedOut();
    }
  }

  Future<void> _exchangeIdToken(String idToken) async {
    // Also forward the claims the server expects on its dev-fallback
    // path. Server-side, the verified path re-reads these from the
    // JWT itself, so this is purely defensive — if AUTH0_DOMAIN isn't
    // set on the server (or token verification is skipped for any
    // reason), the request still carries an email and won't 400.
    final claims = _decodeJwtClaims(idToken);
    final res = await ref.read(authApiProvider).getOrCreateUser(
          idToken: idToken,
          email: claims['email'] as String?,
          name: claims['name'] as String?,
          sub: claims['sub'] as String?,
        );
    await _persist(res.userId);
    setCurrentUserId(res.userId);
    state = AuthSignedIn(
        userId: res.userId, email: res.email, name: res.name);
  }

  /// Decode a JWT's payload (middle segment) without verifying the
  /// signature — verification is the server's job. Returns an empty
  /// map on any parsing error so callers don't need to null-check.
  Map<String, dynamic> _decodeJwtClaims(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return const {};
      var payload = parts[1];
      // base64url padding: the encoder strips '=', so add it back.
      final pad = payload.length % 4;
      if (pad != 0) payload = payload + ('=' * (4 - pad));
      final decoded = utf8.decode(base64Url.decode(payload));
      final obj = jsonDecode(decoded);
      return obj is Map<String, dynamic> ? obj : const {};
    } catch (_) {
      return const {};
    }
  }

  /// Auth0 universal-login flow. Optional [connection] skips Auth0's
  /// hosted picker and goes straight to a specific identity provider
  /// (e.g. `google-oauth2`).
  Future<void> signInWithAuth0({String? connection}) async {
    state = const AuthSigningIn();
    try {
      final idToken = await Auth0Service.instance.signIn(connection: connection);
      if (idToken == null || idToken.isEmpty) {
        // Web path: page is redirecting; the next cold-boot picks up.
        return;
      }
      await _exchangeIdToken(idToken);
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail']
          : null;
      state = AuthSignedOut(
          error: (detail as String?) ?? 'Could not sign in with Auth0.');
    } catch (e) {
      state = AuthSignedOut(error: 'Auth0 sign-in failed: $e');
    }
  }

  /// Shortcut for [signInWithAuth0] that pins the Auth0 `connection` to
  /// Google. The Auth0 dashboard must have the google-oauth2 social
  /// connection enabled for the SPA application.
  Future<void> signInWithGoogle() =>
      signInWithAuth0(connection: 'google-oauth2');

  /// Email + password sign-up-or-sign-in via /login_with_password.
  /// First call for a given email creates the user with that
  /// password; subsequent calls verify it (401 on mismatch surfaces
  /// as a clean error on the login page).
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthSigningIn();
    try {
      final res = await ref.read(authApiProvider).loginWithPassword(
            email: email,
            password: password,
          );
      await _persist(res.userId);
      setCurrentUserId(res.userId);
      state = AuthSignedIn(
          userId: res.userId, email: res.email, name: res.name);
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail']
          : null;
      // 401 → wrong password; 400 → missing fields. Both surface the
      // server's detail string verbatim so the UI shows what happened.
      state = AuthSignedOut(
          error: (detail as String?) ?? 'Could not sign in.');
    } catch (e) {
      state = AuthSignedOut(error: 'Sign-in failed: $e');
    }
  }

  /// Local-dev guest path — hits /get_or_create_user with a fake email.
  /// Server must have AUTH0_DOMAIN unset for this to be accepted.
  Future<void> continueAsGuest({String email = 'guest@local.dev'}) async {
    state = const AuthSigningIn();
    try {
      final res = await ref.read(authApiProvider).getOrCreateUser(
            email: email,
            name: 'Guest',
          );
      await _persist(res.userId);
      setCurrentUserId(res.userId);
      state = AuthSignedIn(
          userId: res.userId, email: res.email, name: res.name);
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail']
          : null;
      state = AuthSignedOut(
          error: (detail as String?) ?? 'Guest sign-in failed.');
    } catch (e) {
      state = AuthSignedOut(error: 'Guest sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await ref.read(authApiProvider).logout();
    } catch (_) {/* server might be unreachable — drop session locally anyway */}
    if (AppConfig.isAuth0Enabled) {
      try {
        await Auth0Service.instance.signOut();
      } catch (_) {/* fine — Auth0 logout is best-effort */}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserIdCacheKey);
    } catch (_) {/* keep going even if storage flakes */}
    setCurrentUserId(1); // back to the legacy dev default
    state = const AuthSignedOut();
  }

  Future<void> _persist(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kUserIdCacheKey, userId);
    } catch (_) {/* non-fatal */}
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// ---------------------------------------------------------------------------
// Thin client over /api/v1/auth — kept here (not in courses_api.dart) so
// the auth surface is co-located with the state machine that drives it.
// ---------------------------------------------------------------------------

class AuthApiResponse {
  final int userId;
  final String email;
  final String? name;
  final Map<String, dynamic>? preference;
  const AuthApiResponse({
    required this.userId,
    required this.email,
    this.name,
    this.preference,
  });
  factory AuthApiResponse.fromJson(Map<String, dynamic> j) => AuthApiResponse(
        userId: j['user_id'] as int,
        email: (j['email'] as String?) ?? '',
        name: j['name'] as String?,
        preference: (j['preference'] as Map?)?.cast<String, dynamic>(),
      );
}

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  /// Verified path passes [idToken]; dev path passes [email] (+ optional
  /// [name]/[sub]). Server picks one based on its own config.
  Future<AuthApiResponse> getOrCreateUser({
    String? idToken,
    String? email,
    String? name,
    String? sub,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/get_or_create_user',
      data: {
        if (idToken != null) 'id_token': idToken,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (sub != null) 'sub': sub,
      },
      options: Options(
        // Make sure web sends/receives the HttpOnly cookie.
        extra: {'withCredentials': true},
      ),
    );
    return AuthApiResponse.fromJson(res.data ?? const {});
  }

  /// Email + password sign-up-or-sign-in. Returns the same shape as
  /// the Auth0 path so the AuthNotifier doesn't need a separate
  /// success branch.
  Future<AuthApiResponse> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login_with_password',
      data: {'email': email, 'password': password},
      options: Options(extra: {'withCredentials': true}),
    );
    return AuthApiResponse.fromJson(res.data ?? const {});
  }

  Future<AuthApiResponse> loginWithCookie() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login_with_cookie',
      options: Options(extra: {'withCredentials': true}),
    );
    return AuthApiResponse.fromJson(res.data ?? const {});
  }

  Future<void> logout() async {
    await _dio.post<dynamic>(
      '/api/v1/auth/logout',
      options: Options(extra: {'withCredentials': true}),
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

/// Tiny JSON helper for tests — not used at runtime, but useful when
/// you need to dump the cache shape from a unit test. Kept here so the
/// cache key + serialisation logic lives in one place.
String encodeUserIdForCache(int id) => jsonEncode({'user_id': id});
