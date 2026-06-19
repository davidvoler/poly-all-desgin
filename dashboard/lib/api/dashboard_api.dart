import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth0_service.dart';
import '../config/app_config.dart';
import 'models.dart';

/// Key under which the signed-in [LoginInfo] is cached in
/// SharedPreferences. Bumped only if the cache shape changes
/// incompatibly.
const String _kAuthCacheKey = 'poly_dashboard_auth_v1';

/// Header the server's `require_school_member` dependency reads. The
/// auth notifier stamps the current school_user_id here whenever a
/// session opens or restores, and clears it on sign-out — so every
/// subsequent Dio request rides the right ID without per-call
/// plumbing.
const String _kAuthHeader = 'X-School-User-Id';

/// Shared Dio instance. Pulled from a Provider so widget tests can
/// `overrideWith` a mock client. Base URL is sourced from
/// [AppConfig.apiBaseUrl] which reads `assets/.env` with a
/// `--dart-define=API_BASE_URL=…` override for CI/CD.
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      // `/api/v1/auth/*` sets an HttpOnly `user_id` cookie and resolves
      // the school from the request hostname. The dashboard and API run
      // on different ports (cross-origin on web), so the browser only
      // stores/sends that cookie when credentials are enabled. Ignored
      // on native, where Dio carries cookies regardless.
      extra: {'withCredentials': true},
    ),
  );
});

/// Signed-in session, built from the `UserPref` returned by
/// POST /api/v1/auth/login_with_password (and /get_or_create_user). The
/// school is resolved server-side from the request hostname, so there's
/// no slug to send or store. `schoolUserId` carries the caller's
/// `user_id` — the identity the new `school.school_users(school_id,
/// user_id)` model keys on.
class LoginInfo {
  final int schoolUserId;
  final int schoolId;
  final String schoolSlug;
  final String schoolName;
  final String name;
  final String email;
  final String role; // primary role, derived from [roles]
  final List<String> roles;

  const LoginInfo({
    required this.schoolUserId,
    required this.schoolId,
    required this.schoolSlug,
    required this.schoolName,
    required this.name,
    required this.email,
    required this.role,
    this.roles = const [],
  });

  /// Roles that unlock admin-only surfaces (Editors + Settings). Spans
  /// both the new (`school_admin`/`super_admin`) and legacy
  /// (`admin`/`owner`) vocabularies so cached sessions keep working.
  static const _adminRoles = {
    'admin',
    'owner',
    'school_admin',
    'super_admin',
  };

  /// Tolerates two shapes:
  ///   * new `/api/v1/auth` UserPref — `{user_id, school_id, email,
  ///     school_user: {roles: [...]}}`
  ///   * legacy `/school_users/login` LoginResponse / cached sessions —
  ///     flat `{school_user_id, role, school_slug, ...}`
  factory LoginInfo.fromJson(Map<String, dynamic> j) {
    final su = j['school_user'];
    final roles = <String>[
      if (su is Map && su['roles'] is List)
        for (final r in su['roles'] as List) '$r',
      // legacy cache persisted a flat `roles` array
      if (su is! Map && j['roles'] is List)
        for (final r in j['roles'] as List) '$r',
    ];
    // user_id is the new identity; fall back to the legacy PK.
    final uid = (j['user_id'] ?? j['school_user_id'] ?? 0) as int;
    final role = (j['role'] as String?) ??
        (roles.isNotEmpty ? roles.first : 'editor');
    return LoginInfo(
      schoolUserId: uid,
      schoolId: (j['school_id'] as int?) ?? 0,
      schoolSlug: (j['school_slug'] as String?) ?? '',
      schoolName: (j['school_name'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      role: role,
      roles: roles,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': schoolUserId,
        'school_id': schoolId,
        'school_slug': schoolSlug,
        'school_name': schoolName,
        'name': name,
        'email': email,
        'role': role,
        'roles': roles,
      };

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Only admins can manage staff (Editors page) or change the school
  /// itself (Settings page).
  bool get isAdmin =>
      _adminRoles.contains(role) || roles.any(_adminRoles.contains);
}

/// Thin client over the dashboard-side endpoints.
class DashboardApi {
  final Dio _dio;
  DashboardApi(this._dio);

  /// Email + password sign-in against the unified auth router. The
  /// school is resolved server-side from the request hostname, so no
  /// slug is sent. Sets the HttpOnly `user_id` session cookie.
  Future<LoginInfo> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login_with_password',
      data: {
        'email': email,
        'password': password,
      },
    );
    return LoginInfo.fromJson(res.data ?? const {});
  }

  /// Exchange an Auth0 ID token for a [LoginInfo]. The server verifies
  /// the token against the configured Auth0 JWKS, trusts the `email`
  /// claim, resolves the school from the request hostname, and returns
  /// the same `UserPref` shape as the password-login route.
  Future<LoginInfo> loginWithAuth0({
    required String idToken,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/get_or_create_user',
      data: {
        'id_token': idToken,
      },
    );
    return LoginInfo.fromJson(res.data ?? const {});
  }

  Future<void> setCourseStatus({
    required int courseId,
    required int schoolId,
    int? actorUserId,
    required String status,
    String? note,
  }) async {
    await _dio.post<dynamic>(
      '/api/v1/editor/review/$courseId/status',
      queryParameters: {
        'school_id': schoolId,
        'actor_user_id': ?actorUserId,
      },
      data: {
        'status': status,
        if (note?.isNotEmpty ?? false) 'note': note,
      },
    );
  }

  // --- Reads --------------------------------------------------------

  Future<SchoolInfo> fetchSchool(int schoolId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/school/$schoolId',
    );
    return SchoolInfo.fromJson(res.data ?? const {});
  }

  Future<SchoolStats> fetchSchoolStats(int schoolId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/school/$schoolId/stats',
    );
    return SchoolStats.fromJson(res.data ?? const {});
  }

  Future<List<ActivityRowRemote>> fetchActivity(int schoolId,
      {int limit = 10}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/school/$schoolId/activity',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ActivityRowRemote.fromJson)
        .toList();
  }

  Future<List<LanguageSummary>> fetchLanguages(int schoolId,
      {String? role}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/school/$schoolId/languages',
      queryParameters: {
        'role': ?role,
      },
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(LanguageSummary.fromJson)
        .toList();
  }

  Future<LessonDetailRemote> fetchLessonDetail(int lessonId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/editor/lesson/$lessonId',
    );
    return LessonDetailRemote.fromJson(res.data ?? const {});
  }

  Future<void> saveLessonDetail({
    required int courseId,
    required int moduleId,
    int? lessonId,
    required String title,
    required List<String> words,
    required List<Map<String, dynamic>> exercises,
  }) async {
    await _dio.post<dynamic>(
      '/api/v1/editor/lesson/',
      data: {
        'course_id': courseId,
        'module_id': moduleId,
        'lesson_id': ?lessonId,
        'title': title,
        'words': words,
        'exercises': exercises,
      },
    );
  }

  Future<EditorCourseDetail> fetchCourseDetail({
    required int courseId,
    required int schoolId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/editor/courses/$courseId/detail',
      queryParameters: {'school_id': schoolId},
    );
    return EditorCourseDetail.fromJson(res.data ?? const {});
  }

  /// Course head (no modules) — paired with [fetchCourseModules] so the
  /// detail page can render without loading every lesson up front.
  Future<EditorCourse> fetchCourse({
    required int courseId,
    required int schoolId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/editor/courses/$courseId',
      queryParameters: {'school_id': schoolId},
    );
    return EditorCourse.fromJson(res.data ?? const {});
  }

  /// Lightweight module list (with lesson counts, no nested lessons) for the
  /// paginated course-detail page.
  Future<List<EditorModuleSummary>> fetchCourseModules({
    required int courseId,
    required int schoolId,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/editor/courses/$courseId/modules',
      queryParameters: {'school_id': schoolId},
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(EditorModuleSummary.fromJson)
        .toList();
  }

  /// Lessons (with exercise counts) for a single module — fetched on demand
  /// when the module card is expanded.
  Future<List<EditorLessonRemote>> fetchModuleLessons({
    required int courseId,
    required int moduleId,
    required int schoolId,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/editor/courses/$courseId/modules/$moduleId/lessons',
      queryParameters: {'school_id': schoolId},
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(EditorLessonRemote.fromJson)
        .toList();
  }

  Future<List<EditorCourse>> fetchEditorCourses(int schoolId,
      {String? status, String? lang, String? q}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/editor/courses/',
      queryParameters: {
        'school_id': schoolId,
        'status': ?status,
        'lang': ?lang,
        'q': ?q,
      },
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(EditorCourse.fromJson)
        .toList();
  }

  // school_users API removed — the dashboard no longer calls
  // /api/v1/school_users/*. The read returns an empty list (the Editors
  // page renders its empty state); the writes below throw so any lingering
  // UI surfaces a clear error rather than silently faking success.
  Future<List<SchoolUser>> fetchSchoolUsers(int schoolId,
      {String? role, String? q}) async {
    return const [];
  }

  Future<List<StudentRowRemote>> fetchStudents(int schoolId,
      {String? lang, String? status, String? q, int limit = 200}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/school/$schoolId/students',
      queryParameters: {
        'lang': ?lang,
        'status': ?status,
        'q': ?q,
        'limit': limit,
      },
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(StudentRowRemote.fromJson)
        .toList();
  }

  // --- Writes -------------------------------------------------------

  Future<void> updateSchool({
    required int schoolId,
    required String name,
    required String plan,
    required bool isPublic,
    String? logoUrl,
    required String primaryColor,
    required List<String> languagesTaught,
    required List<String> nativeLanguages,
  }) async {
    await _dio.put<dynamic>(
      '/api/v1/school/$schoolId',
      data: {
        'school_id': schoolId,
        'slug': '',
        'name': name,
        'plan': plan,
        'is_public': isPublic,
        'logo_url': logoUrl,
        'primary_color': primaryColor,
        'languages_taught': languagesTaught,
        'native_languages': nativeLanguages,
      },
    );
  }

  Future<SchoolUser> createSchoolUser({
    required int schoolId,
    required String name,
    required String email,
    String? password,
    String role = 'editor',
    List<String> assignedLanguages = const [],
  }) async {
    throw UnsupportedError('school_users API removed');
  }

  Future<SchoolUser> updateSchoolUser(SchoolUser u) async {
    throw UnsupportedError('school_users API removed');
  }

  Future<void> deleteSchoolUser(int schoolUserId) async {
    throw UnsupportedError('school_users API removed');
  }

  /// Upload a zipped course archive. `fileBytes` is preferred for web
  /// (where file_picker returns bytes only); pass `filePath` from
  /// desktop/mobile to stream from disk.
  Future<int?> uploadCourse({
    required int schoolId,
    int? actorUserId,
    required String filename,
    List<int>? fileBytes,
    String? filePath,
    String? courseTitle,
    String lang = 'ar',
    String toLang = 'en',
  }) async {
    final MultipartFile multipart;
    if (fileBytes != null) {
      multipart = MultipartFile.fromBytes(fileBytes, filename: filename);
    } else if (filePath != null) {
      multipart = await MultipartFile.fromFile(filePath, filename: filename);
    } else {
      throw ArgumentError('Either fileBytes or filePath is required');
    }
    final form = FormData.fromMap({
      'school_id': schoolId,
      'actor_user_id': ?actorUserId,
      if (courseTitle?.isNotEmpty ?? false) 'course_title': courseTitle,
      'lang': lang,
      'to_lang': toLang,
      'file': multipart,
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/editor/upload/',
      data: form,
      // Course upload is long-running server-side (unzip + parse_course +
      // load_course's many DB inserts), well past the Dio defaults
      // (connect 5s / receive 15s). Override per-request so a big course
      // doesn't abort mid-parse; the global defaults stay tight for
      // ordinary calls. sendTimeout covers streaming the zip body up.
      options: Options(
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 10),
      ),
    );
    return (res.data?['course_id'] as int?);
  }

  /// Import a course pasted as one `=== path ===`-delimited document (the
  /// output of the Create-with-AI flow). Returns the new course id.
  Future<int?> importCourseText({required String document}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/editor/upload/text',
      data: {'document': document},
      options: Options(
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 10),
      ),
    );
    return res.data?['course_id'] as int?;
  }

  /// Download a course's zip export. Returns the raw bytes — caller
  /// is responsible for writing them somewhere the user can find
  /// (file_picker's saveFile on desktop, a Blob anchor on web).
  Future<List<int>> exportCourse(int courseId) async {
    final res = await _dio.get<List<int>>(
      '/api/v1/editor/export/$courseId',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  Future<void> enrollStudent({
    required int schoolId,
    required String email,
    required String name,
    required String lang,
    int? courseId,
    String? cohort,
  }) async {
    await _dio.post<dynamic>(
      '/api/v1/school/$schoolId/students',
      data: {
        'email': email,
        'name': name,
        'lang': lang,
        'course_id': ?courseId,
        'cohort': ?cohort,
      },
    );
  }

  /// Bulk-enroll from a CSV upload. Returns the {added, skipped,
  /// errors} summary so the caller can render an inline toast.
  Future<Map<String, dynamic>> enrollStudentsCsv({
    required int schoolId,
    required String lang,
    String? cohort,
    required String filename,
    List<int>? fileBytes,
    String? filePath,
  }) async {
    final MultipartFile multipart;
    if (fileBytes != null) {
      multipart = MultipartFile.fromBytes(fileBytes, filename: filename);
    } else if (filePath != null) {
      multipart = await MultipartFile.fromFile(filePath, filename: filename);
    } else {
      throw ArgumentError('Either fileBytes or filePath is required');
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/school/$schoolId/students/csv',
      queryParameters: {
        'lang': lang,
        'cohort': ?cohort,
      },
      data: FormData.fromMap({'file': multipart}),
    );
    return res.data ?? const {};
  }

  // --- Plans + billing (Settings page) ------------------------------

  Future<List<Map<String, dynamic>>> fetchPlans(int schoolId) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/school/$schoolId/plans',
    );
    return (res.data ?? const []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> upsertPlan({
    required int schoolId,
    int? planId,
    required String tier,
    required int priceCents,
    String cadence = 'monthly',
    String? blurb,
    bool featured = false,
    required List<Map<String, dynamic>> features,
  }) async {
    final body = {
      'tier': tier,
      'price_cents': priceCents,
      'cadence': cadence,
      'blurb': ?blurb,
      'featured': featured,
      'features': features,
    };
    final res = planId == null
        ? await _dio.post<Map<String, dynamic>>(
            '/api/v1/school/$schoolId/plans',
            data: body,
          )
        : await _dio.put<Map<String, dynamic>>(
            '/api/v1/school/$schoolId/plans/$planId',
            data: body,
          );
    return res.data ?? const {};
  }

  Future<void> deletePlan({required int schoolId, required int planId}) async {
    await _dio.delete<dynamic>('/api/v1/school/$schoolId/plans/$planId');
  }

  Future<Map<String, dynamic>?> fetchBilling(int schoolId) async {
    final res = await _dio.get<dynamic>(
      '/api/v1/school/$schoolId/billing',
    );
    final data = res.data;
    if (data is Map) return data.cast<String, dynamic>();
    return null;
  }

  Future<void> upsertBilling({
    required int schoolId,
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
  }) async {
    await _dio.put<dynamic>(
      '/api/v1/school/$schoolId/billing',
      data: {
        'brand': brand,
        'last4': last4,
        'exp_month': expMonth,
        'exp_year': expYear,
      },
    );
  }

  Future<void> deleteSchool(int schoolId) async {
    await _dio.delete<dynamic>('/api/v1/school/$schoolId');
  }

  // --- Password reset ----------------------------------------------

  /// Issue a one-shot reset token. Returns the token string for the
  /// demo flow; in production this would only land in an email and
  /// the dashboard would never see it. `null` means the call
  /// succeeded but no account matched (caller still shows "check
  /// your inbox" to avoid leaking which emails are registered).
  Future<String?> forgotPassword({
    required String email,
    String? schoolSlug,
  }) async {
    throw UnsupportedError('school_users API removed');
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    throw UnsupportedError('school_users API removed');
  }

  /// Create a brand-new school + seed its owner in one shot, then log
  /// in so the dashboard can drop the caller into the new tenant. The
  /// server's POST /api/v1/school/ returns the created [SchoolInfo]
  /// but not a login session — we follow it with a normal login call
  /// using the same credentials.
  Future<LoginInfo> createSchoolAndSignIn({
    required String slug,
    required String name,
    required String plan,
    required bool isPublic,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/school/',
      data: {
        'slug': slug,
        'name': name,
        'plan': plan,
        'is_public': isPublic,
        'owner_name': ownerName,
        'owner_email': ownerEmail,
        'owner_password': ownerPassword,
      },
    );
    return login(email: ownerEmail, password: ownerPassword);
  }
}

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(dioProvider));
});

/// Four states the app routes off of: restoring (cache lookup in flight
/// on app start), signedOut, signingIn, signedIn.
sealed class AuthState {
  const AuthState();
}

/// Initial state — we haven't asked SharedPreferences yet whether a
/// previous session was cached. The router shows a blank gate for this
/// brief window so we don't flash the login page when the user is
/// already signed in.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

class AuthSignedOut extends AuthState {
  /// Last error to show on the login form, if any.
  final String? error;
  const AuthSignedOut({this.error});
}

class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

class AuthSignedIn extends AuthState {
  final LoginInfo info;
  const AuthSignedIn(this.info);
}

/// Auth holder. The login form watches it for error/loading state, the
/// router watches it to decide between the LoginPage and the dashboard.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Kick off the cache restore on first watch. The fire-and-forget
    // is fine — the only consumer is the router, which already gates
    // on AuthRestoring.
    Future.microtask(_restore);
    return const AuthRestoring();
  }

  Future<void> _restore() async {
    try {
      // Web + Auth0: the redirect callback drops the user back here
      // with the auth result in the URL. Finish that handshake first
      // so a returning Auth0 user lands signed in, not on the login
      // page with their cached session.
      if (AppConfig.isAuth0Enabled) {
        try {
          final idToken = await Auth0Service.instance.restoreWebSession();
          if (idToken != null && idToken.isNotEmpty) {
            final info = await ref
                .read(dashboardApiProvider)
                .loginWithAuth0(idToken: idToken);
            await _persist(info);
            _setAuthHeader(info.schoolUserId);
            state = AuthSignedIn(info);
            return;
          }
        } catch (_) {
          // Fall through to the cached-session path — the user can
          // still sign in via the form (or retry Auth0).
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kAuthCacheKey);
      if (raw == null || raw.isEmpty) {
        _clearAuthHeader();
        state = const AuthSignedOut();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _clearAuthHeader();
        state = const AuthSignedOut();
        return;
      }
      final info = LoginInfo.fromJson(decoded);
      _setAuthHeader(info.schoolUserId);
      state = AuthSignedIn(info);
    } catch (_) {
      // Corrupt cache → just go to login. Don't propagate.
      _clearAuthHeader();
      state = const AuthSignedOut();
    }
  }

  void _setAuthHeader(int schoolUserId) {
    ref.read(dioProvider).options.headers[_kAuthHeader] = '$schoolUserId';
  }

  void _clearAuthHeader() {
    ref.read(dioProvider).options.headers.remove(_kAuthHeader);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthSigningIn();
    try {
      final info = await ref.read(dashboardApiProvider).login(
            email: email,
            password: password,
          );
      await _persist(info);
      _setAuthHeader(info.schoolUserId);
      state = AuthSignedIn(info);
    } on DioException catch (e) {
      // 401 is the common path — surface the server's `detail` string
      // when present, otherwise a fallback. Network errors fall through
      // to the generic message.
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail']
          : null;
      state = AuthSignedOut(
          error: (detail as String?) ?? 'Could not sign in. Try again.');
    } catch (_) {
      state = const AuthSignedOut(error: 'Could not sign in. Try again.');
    }
  }

  /// Programmatic sign-in used by the create-school wizard — the
  /// server response includes everything we need to mint a session,
  /// so we can skip the password round-trip.
  Future<void> adoptSession(LoginInfo info) async {
    await _persist(info);
    _setAuthHeader(info.schoolUserId);
    state = AuthSignedIn(info);
  }

  /// Universal-login flow against Auth0. Opens the Auth0 hosted login
  /// page, grabs the ID token, and exchanges it for a [LoginInfo] via
  /// the server's `/login_auth0` route. The local password form stays
  /// available when `AUTH_PROVIDER=both`, so an Auth0 hiccup never
  /// locks an admin out of the dashboard.
  ///
  /// Pass [connection] to skip Auth0's hosted picker and go straight
  /// to a specific identity provider (e.g. `google-oauth2`).
  Future<void> signInWithAuth0({
    String? connection,
  }) async {
    state = const AuthSigningIn();
    try {
      final idToken =
          await Auth0Service.instance.signIn(connection: connection);
      if (idToken == null || idToken.isEmpty) {
        state = const AuthSignedOut(error: 'Auth0 returned no ID token.');
        return;
      }
      final info = await ref.read(dashboardApiProvider).loginWithAuth0(
            idToken: idToken,
          );
      await _persist(info);
      _setAuthHeader(info.schoolUserId);
      state = AuthSignedIn(info);
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

  /// Shortcut for [signInWithAuth0] that pins the connection to Google.
  /// The Auth0 dashboard must have google-oauth2 enabled for the SPA
  /// application.
  Future<void> signInWithGoogle() =>
      signInWithAuth0(connection: 'google-oauth2');

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAuthCacheKey);
    } catch (_) {/* keep going even if storage flakes */}
    // Best-effort Auth0 logout so the Auth0 hosted session doesn't
    // silently sign the user back in on the next visit. No-op when
    // Auth0 isn't configured.
    if (AppConfig.isAuth0Enabled) {
      try {
        await Auth0Service.instance.signOut();
      } catch (_) {/* keep going even if Auth0 endpoint is offline */}
    }
    _clearAuthHeader();
    state = const AuthSignedOut();
  }

  Future<void> _persist(LoginInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAuthCacheKey, jsonEncode(info.toJson()));
    } catch (_) {/* non-fatal — the in-memory state is still valid */}
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience selector — the signed-in [LoginInfo] or null when not
/// signed in. Read this from any widget that needs `schoolId`,
/// `schoolUserId`, role, etc.
final currentUserProvider = Provider<LoginInfo?>((ref) {
  final s = ref.watch(authProvider);
  return s is AuthSignedIn ? s.info : null;
});

// --- Data providers ---------------------------------------------------------
// Every page-level read goes through one of these. They watch
// [currentUserProvider] so they automatically refetch when the user
// signs in (and dispose when they sign out). When no one is signed in
// they short-circuit with empty data so widgets render their loading
// state without an extra null branch.

final schoolProvider = FutureProvider<SchoolInfo?>((ref) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return null;
  return ref.read(dashboardApiProvider).fetchSchool(me.schoolId);
});

final schoolStatsProvider = FutureProvider<SchoolStats>((ref) async {
  // Stats disabled — the dashboard no longer calls
  // /api/v1/school/<id>/stats. fetchSchoolStats() is left in place for when
  // stats are reinstated; consumers fall back to the empty SchoolStats.
  return const SchoolStats();
});

final activityProvider = FutureProvider<List<ActivityRowRemote>>((ref) async {
  // Activity feed disabled — the dashboard no longer calls
  // /api/v1/school/<id>/activity. fetchActivity() is left in place for when
  // the feed is reinstated; the Overview panel falls back to its empty state.
  return const [];
});

final languagesProvider = FutureProvider<List<LanguageSummary>>((ref) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchLanguages(me.schoolId);
});

/// Free-text search key reused by every page that lists from the
/// server. Empty string means "no filter". Kept as a value class so
/// the FutureProvider.family memoises by string equality (instead of
/// fetching on every keystroke a TextField would otherwise trigger).
class CoursesFilter {
  final String q;
  final String? status;
  final String? lang;
  const CoursesFilter({this.q = '', this.status, this.lang});

  @override
  bool operator ==(Object other) =>
      other is CoursesFilter &&
      other.q == q &&
      other.status == status &&
      other.lang == lang;

  @override
  int get hashCode => Object.hash(q, status, lang);
}

final editorCoursesProvider = FutureProvider.family<List<EditorCourse>,
    CoursesFilter>((ref, filter) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchEditorCourses(
        me.schoolId,
        status: filter.status,
        lang: filter.lang,
        q: filter.q.isEmpty ? null : filter.q,
      );
});

class EditorsFilter {
  final String q;
  final String? role;
  const EditorsFilter({this.q = '', this.role});

  @override
  bool operator ==(Object other) =>
      other is EditorsFilter && other.q == q && other.role == role;

  @override
  int get hashCode => Object.hash(q, role);
}

final schoolUsersProvider = FutureProvider.family<List<SchoolUser>,
    EditorsFilter>((ref, filter) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchSchoolUsers(
        me.schoolId,
        role: filter.role,
        q: filter.q.isEmpty ? null : filter.q,
      );
});

/// Filter key for [studentsProvider] — kept tiny so it equals cleanly.
class StudentsFilter {
  final String q;
  final String? lang;
  final String? status;
  const StudentsFilter({this.q = '', this.lang, this.status});

  @override
  bool operator ==(Object other) =>
      other is StudentsFilter &&
      other.q == q &&
      other.lang == lang &&
      other.status == status;

  @override
  int get hashCode => Object.hash(q, lang, status);
}

final studentsProvider = FutureProvider.family<List<StudentRowRemote>,
    StudentsFilter>((ref, filter) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchStudents(
        me.schoolId,
        lang: filter.lang,
        status: filter.status,
        q: filter.q.isEmpty ? null : filter.q,
      );
});

/// All subscription plans for the current school — backs the
/// Settings → Subscription plans grid.
final plansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchPlans(me.schoolId);
});

/// The primary billing method (or null when none exists). Settings →
/// Billing renders an empty-state CTA when this resolves to null.
final billingProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return null;
  return ref.read(dashboardApiProvider).fetchBilling(me.schoolId);
});

/// Full nested detail for a single course — modules + lessons +
/// per-lesson exercise counts. Keyed by course id; reuses the
/// current user's schoolId scope.
final courseDetailProvider =
    FutureProvider.family<EditorCourseDetail?, int>((ref, courseId) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return null;
  return ref.read(dashboardApiProvider).fetchCourseDetail(
        courseId: courseId,
        schoolId: me.schoolId,
      );
});

/// Course head (no modules) for the paginated detail page. Keyed by course
/// id; reuses the current user's schoolId scope.
final courseHeadProvider =
    FutureProvider.family<EditorCourse?, int>((ref, courseId) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return null;
  return ref.read(dashboardApiProvider).fetchCourse(
        courseId: courseId,
        schoolId: me.schoolId,
      );
});

/// Lightweight module list (with lesson counts) for a course — the first
/// payload the detail page loads. Keyed by course id.
final courseModulesProvider =
    FutureProvider.family<List<EditorModuleSummary>, int>((ref, courseId) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchCourseModules(
        courseId: courseId,
        schoolId: me.schoolId,
      );
});

/// Lessons for a single module, fetched on demand when its card expands.
/// Keyed by (courseId, moduleId).
final moduleLessonsProvider = FutureProvider.family<List<EditorLessonRemote>,
    ({int courseId, int moduleId})>((ref, key) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchModuleLessons(
        courseId: key.courseId,
        moduleId: key.moduleId,
        schoolId: me.schoolId,
      );
});

/// Lesson + exercises for the per-lesson editor dialog. Keyed by
/// lesson id; reuses the standard FutureProvider error handling.
final lessonDetailProvider =
    FutureProvider.family<LessonDetailRemote, int>((ref, lessonId) async {
  return ref.read(dashboardApiProvider).fetchLessonDetail(lessonId);
});
