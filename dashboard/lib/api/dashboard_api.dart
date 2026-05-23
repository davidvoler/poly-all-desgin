import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

/// Base URL for the Polyglots backend. Override at compile-time with
///
///     flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8004
///
/// Defaults to localhost so a fresh `flutter run` against the dev
/// `docker compose up` Just Works.
const String _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8004',
);

/// Shared Dio instance. Pulled from a Provider so widget tests can
/// `overrideWith` a mock client.
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );
});

/// Response body of POST /api/v1/school_users/login — what we hand
/// back to the UI to gate routes.
class LoginInfo {
  final int schoolUserId;
  final int schoolId;
  final String schoolSlug;
  final String schoolName;
  final String name;
  final String email;
  final String role; // owner | editor | viewer

  const LoginInfo({
    required this.schoolUserId,
    required this.schoolId,
    required this.schoolSlug,
    required this.schoolName,
    required this.name,
    required this.email,
    required this.role,
  });

  factory LoginInfo.fromJson(Map<String, dynamic> j) => LoginInfo(
        schoolUserId: j['school_user_id'] as int,
        schoolId: j['school_id'] as int,
        schoolSlug: (j['school_slug'] as String?) ?? '',
        schoolName: (j['school_name'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        role: (j['role'] as String?) ?? 'editor',
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// Thin client over the dashboard-side endpoints.
class DashboardApi {
  final Dio _dio;
  DashboardApi(this._dio);

  Future<LoginInfo> login({
    required String email,
    required String password,
    String? schoolSlug,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/school_users/login',
      data: {
        'email': email,
        'password': password,
        if (schoolSlug?.isNotEmpty ?? false) 'school_slug': schoolSlug,
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

  Future<List<EditorCourse>> fetchEditorCourses(int schoolId,
      {String? status, String? lang}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/editor/courses/',
      queryParameters: {
        'school_id': schoolId,
        'status': ?status,
        'lang': ?lang,
      },
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(EditorCourse.fromJson)
        .toList();
  }

  Future<List<SchoolUser>> fetchSchoolUsers(int schoolId,
      {String? role}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/school_users/',
      queryParameters: {
        'school_id': schoolId,
        'role': ?role,
      },
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(SchoolUser.fromJson)
        .toList();
  }

  Future<List<StudentRowRemote>> fetchStudents(int schoolId,
      {String? lang, String? status, int limit = 200}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/school/$schoolId/students',
      queryParameters: {
        'lang': ?lang,
        'status': ?status,
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
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/school_users/',
      data: {
        'school_id': schoolId,
        'name': name,
        'email': email,
        'password': ?password,
        'role': role,
        'assigned_languages': assignedLanguages,
      },
    );
    return SchoolUser.fromJson(res.data ?? const {});
  }
}

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(dioProvider));
});

/// Three states the app routes off of: signedOut, signingIn, signedIn.
sealed class AuthState {
  const AuthState();
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
  AuthState build() => const AuthSignedOut();

  Future<void> signIn({
    required String email,
    required String password,
    String? schoolSlug,
  }) async {
    state = const AuthSigningIn();
    try {
      final info = await ref.read(dashboardApiProvider).login(
            email: email,
            password: password,
            schoolSlug: schoolSlug,
          );
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

  void signOut() {
    state = const AuthSignedOut();
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
  final me = ref.watch(currentUserProvider);
  if (me == null) return const SchoolStats();
  return ref.read(dashboardApiProvider).fetchSchoolStats(me.schoolId);
});

final activityProvider = FutureProvider<List<ActivityRowRemote>>((ref) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchActivity(me.schoolId);
});

final languagesProvider = FutureProvider<List<LanguageSummary>>((ref) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchLanguages(me.schoolId);
});

final editorCoursesProvider = FutureProvider<List<EditorCourse>>((ref) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchEditorCourses(me.schoolId);
});

final schoolUsersProvider = FutureProvider<List<SchoolUser>>((ref) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchSchoolUsers(me.schoolId);
});

/// Filter key for [studentsProvider] — kept tiny so it equals cleanly.
class StudentsFilter {
  final String? lang;
  final String? status;
  const StudentsFilter({this.lang, this.status});

  @override
  bool operator ==(Object other) =>
      other is StudentsFilter && other.lang == lang && other.status == status;

  @override
  int get hashCode => Object.hash(lang, status);
}

final studentsProvider = FutureProvider.family<List<StudentRowRemote>,
    StudentsFilter>((ref, filter) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.read(dashboardApiProvider).fetchStudents(
        me.schoolId,
        lang: filter.lang,
        status: filter.status,
      );
});
