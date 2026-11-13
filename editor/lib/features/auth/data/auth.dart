import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import 'auth0_service.dart';

/// The signed-in editor, as the server's `/api/v1/auth/me` returns it.
class EditorUser {
  const EditorUser({
    required this.userId,
    required this.schoolId,
    required this.schoolName,
    required this.email,
  });

  factory EditorUser.fromJson(Map<String, dynamic> json) => EditorUser(
    userId: json['user_id'] as int,
    schoolId: json['school_id'] as int,
    schoolName: json['school_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
  );

  final int userId;
  final int schoolId;
  final String schoolName;
  final String email;
}

sealed class AuthState {
  const AuthState();
}

/// Checking for an existing session on startup.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut([this.error]);

  /// Why the last sign-in failed, or why the session ended.
  final String? error;
}

class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final EditorUser user;
}

/// The server's sign-in calls. The session lives in an HttpOnly cookie the
/// app never reads.
class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  static const _path = '/api/v1/auth';

  Future<EditorUser> loginWithPassword(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/login_with_password',
      data: {'email': email, 'password': password},
    );
    return EditorUser.fromJson(response.data!);
  }

  /// Same call as the app's sign-in: the token plus its email, name and sub,
  /// which the server uses only when it is not verifying tokens.
  Future<EditorUser> loginWithAuth0(String idToken) async {
    final claims = _jwtClaims(idToken);
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/get_or_create_user',
      data: {
        'id_token': idToken,
        'email': claims['email'],
        'name': claims['name'],
        'sub': claims['sub'],
      },
    );
    return EditorUser.fromJson(response.data!);
  }

  /// The ID token's claims, without checking its signature.
  static Map<String, dynamic> _jwtClaims(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return const {};
      final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(json);
      return claims is Map<String, dynamic> ? claims : const {};
    } catch (_) {
      return const {};
    }
  }

  /// The signed-in editor, or null when there is no valid session.
  Future<EditorUser?> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_path/me');
      return EditorUser.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() => _dio.post<void>('$_path/logout');
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthRestoring();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Finishes a returning Auth0 sign-in, else resumes the cookie session.
  Future<void> _restore() async {
    try {
      final idToken = await Auth0Service.instance.restoreWebSession();
      if (idToken != null && idToken.isNotEmpty) {
        state = AuthSignedIn(await _repo.loginWithAuth0(idToken));
        return;
      }
      final user = await _repo.me();
      state = user == null ? const AuthSignedOut() : AuthSignedIn(user);
    } catch (e) {
      state = AuthSignedOut(authErrorMessage(e));
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      _signIn(() => _repo.loginWithPassword(email, password));

  /// Continue with Google through Auth0. On the web the page leaves for
  /// Auth0 and comes back signed in through [_restore].
  Future<void> signInWithGoogle() => _signIn(() async {
    final idToken = await Auth0Service.instance.signIn(
      connection: 'google-oauth2',
    );
    if (idToken == null) return null;
    return _repo.loginWithAuth0(idToken);
  });

  Future<void> _signIn(Future<EditorUser?> Function() signIn) async {
    state = const AuthSigningIn();
    try {
      final user = await signIn();
      if (user != null) state = AuthSignedIn(user);
    } catch (e) {
      state = AuthSignedOut(authErrorMessage(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _repo.logout();
    } catch (_) {
      // Signed out here regardless; the cookie expires on its own.
    }
    state = const AuthSignedOut();
    try {
      await Auth0Service.instance.signOut();
    } catch (_) {}
  }

  /// The server ended the session, e.g. it expired or the editor role was
  /// removed. Called by the API client on a 401.
  void sessionEnded(String message) {
    if (state is AuthSignedIn) state = AuthSignedOut(message);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// The server's `detail` message when it sent one.
String authErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'];
    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server.';
    }
    return error.message ?? error.toString();
  }
  if (error is StateError) return error.message;
  return error.toString();
}

/// Whether this build offers each way to sign in.
bool get passwordSignInEnabled => AppConfig.isPasswordEnabled;
bool get googleSignInEnabled => AppConfig.isAuth0Enabled;
