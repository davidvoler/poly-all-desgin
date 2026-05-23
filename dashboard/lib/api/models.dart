// Wire-format models that mirror the FastAPI server-side Pydantic
// classes. Each fromJson is defensive on optional fields so a
// partially-populated row still renders.

class SchoolInfo {
  final int schoolId;
  final String slug;
  final String name;
  final String plan;
  final int streakDays;
  final List<String> languagesTaught;
  final List<String> nativeLanguages;
  final String? logoUrl;
  final String primaryColor;

  const SchoolInfo({
    required this.schoolId,
    required this.slug,
    required this.name,
    required this.plan,
    required this.streakDays,
    required this.languagesTaught,
    required this.nativeLanguages,
    required this.logoUrl,
    required this.primaryColor,
  });

  factory SchoolInfo.fromJson(Map<String, dynamic> j) => SchoolInfo(
        schoolId: j['school_id'] as int,
        slug: (j['slug'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        plan: (j['plan'] as String?) ?? 'free',
        streakDays: (j['streak_days'] as int?) ?? 0,
        languagesTaught:
            ((j['languages_taught'] as List?) ?? const []).cast<String>(),
        nativeLanguages:
            ((j['native_languages'] as List?) ?? const []).cast<String>(),
        logoUrl: j['logo_url'] as String?,
        primaryColor: (j['primary_color'] as String?) ?? '#1E88E5',
      );

  /// Two-letter mark used in the sidebar badge — derived from the
  /// school name (e.g. "Riverside Academy" → "RA"). Empty-string-safe.
  String get mark {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'PG';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class SchoolStats {
  final int activeLanguages;
  final int courses;
  final int editors;
  final int students;
  const SchoolStats({
    this.activeLanguages = 0,
    this.courses = 0,
    this.editors = 0,
    this.students = 0,
  });

  factory SchoolStats.fromJson(Map<String, dynamic> j) => SchoolStats(
        activeLanguages: (j['active_languages'] as int?) ?? 0,
        courses: (j['courses'] as int?) ?? 0,
        editors: (j['editors'] as int?) ?? 0,
        students: (j['students'] as int?) ?? 0,
      );
}

enum ActivityKind { upload, invite, generic }

ActivityKind _activityKindFromWire(String? wire) {
  switch (wire) {
    case 'course_upload':
    case 'course_published':
    case 'course_review_submitted':
    case 'course_archived':
      return ActivityKind.upload;
    case 'editor_invite':
    case 'editor_added':
      return ActivityKind.invite;
    default:
      return ActivityKind.generic;
  }
}

class ActivityRowRemote {
  final int activityId;
  final String actorName;
  final ActivityKind kind;
  final String summary;
  final String whenHuman;

  const ActivityRowRemote({
    required this.activityId,
    required this.actorName,
    required this.kind,
    required this.summary,
    required this.whenHuman,
  });

  factory ActivityRowRemote.fromJson(Map<String, dynamic> j) =>
      ActivityRowRemote(
        activityId: (j['activity_id'] as int?) ?? 0,
        actorName: (j['actor_name'] as String?) ?? 'System',
        kind: _activityKindFromWire(j['kind'] as String?),
        summary: (j['summary'] as String?) ?? '',
        whenHuman: (j['when_human'] as String?) ?? '',
      );
}

class LanguageSummary {
  final String lang;
  final String role; // teach | native
  final String flag;
  final String native;
  final String english;
  final bool rtl;
  final int? courses;
  final int students;
  final String? percentOfSchool;
  final bool active;

  const LanguageSummary({
    required this.lang,
    required this.role,
    required this.flag,
    required this.native,
    required this.english,
    required this.rtl,
    required this.courses,
    required this.students,
    required this.percentOfSchool,
    required this.active,
  });

  factory LanguageSummary.fromJson(Map<String, dynamic> j) => LanguageSummary(
        lang: (j['lang'] as String?) ?? '',
        role: (j['role'] as String?) ?? 'teach',
        flag: (j['flag'] as String?) ?? '',
        native: (j['native'] as String?) ?? '',
        english: (j['english'] as String?) ?? '',
        rtl: (j['rtl'] as bool?) ?? false,
        courses: j['courses'] as int?,
        students: (j['students'] as int?) ?? 0,
        percentOfSchool: j['percent_of_school'] as String?,
        active: (j['active'] as bool?) ?? true,
      );
}

enum CourseStatusWire { draft, review, published, archived, unknown }

CourseStatusWire _statusFromWire(String? s) {
  switch (s) {
    case 'draft':
      return CourseStatusWire.draft;
    case 'review':
      return CourseStatusWire.review;
    case 'published':
      return CourseStatusWire.published;
    case 'archived':
      return CourseStatusWire.archived;
    default:
      return CourseStatusWire.unknown;
  }
}

enum CourseAccessWire { public, members, unknown }

CourseAccessWire _accessFromWire(String? s) {
  switch (s) {
    case 'public':
      return CourseAccessWire.public;
    case 'members':
      return CourseAccessWire.members;
    default:
      return CourseAccessWire.unknown;
  }
}

class EditorCourse {
  final int courseId;
  final String title;
  final String description;
  final String lang;
  final String toLang;
  final CourseStatusWire status;
  final CourseAccessWire access;
  final int lessonCount;
  final int moduleCount;
  final int studentCount;
  final String updatedHuman;

  const EditorCourse({
    required this.courseId,
    required this.title,
    required this.description,
    required this.lang,
    required this.toLang,
    required this.status,
    required this.access,
    required this.lessonCount,
    required this.moduleCount,
    required this.studentCount,
    required this.updatedHuman,
  });

  factory EditorCourse.fromJson(Map<String, dynamic> j) {
    // The server returns an ISO timestamp; we render it client-side
    // since the design uses relative strings.
    final raw = j['updated_at'] as String?;
    return EditorCourse(
      courseId: j['course_id'] as int,
      title: (j['title'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      lang: (j['lang'] as String?) ?? '',
      toLang: (j['to_lang'] as String?) ?? '',
      status: _statusFromWire(j['status'] as String?),
      access: _accessFromWire(j['access'] as String?),
      lessonCount: (j['lesson_count'] as int?) ?? 0,
      moduleCount: (j['module_count'] as int?) ?? 0,
      studentCount: (j['student_count'] as int?) ?? 0,
      updatedHuman: _humanizeIso(raw),
    );
  }
}

/// Mirrors the server's `_humanize` helper for the client side — used
/// for course `updated_at` strings the server returns as raw ISO.
String _humanizeIso(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '—';
  final delta = DateTime.now().difference(dt.toLocal());
  if (delta.inSeconds < 60) return 'Just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes} m ago';
  if (delta.inHours < 24) return '${delta.inHours} h ago';
  if (delta.inDays == 1) return 'Yesterday';
  if (delta.inDays < 28) return '${delta.inDays} days ago';
  if (delta.inDays < 365) return '${delta.inDays ~/ 7} weeks ago';
  return '${delta.inDays ~/ 365} years ago';
}

/// Full lesson + exercise list as returned by
/// GET /api/v1/editor/lesson/{id}. Exercises are kept as a list of
/// loosely-typed maps because the schema includes optional fields
/// the dashboard editor doesn't have to fully understand to render.
class LessonDetailRemote {
  final int lessonId;
  final int courseId;
  final int moduleId;
  final String title;
  final String description;
  final List<String> words;
  final List<Map<String, dynamic>> exercises;

  const LessonDetailRemote({
    required this.lessonId,
    required this.courseId,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.words,
    required this.exercises,
  });

  factory LessonDetailRemote.fromJson(Map<String, dynamic> j) =>
      LessonDetailRemote(
        lessonId: j['lesson_id'] as int,
        courseId: j['course_id'] as int,
        moduleId: j['module_id'] as int,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        words: ((j['words'] as List?) ?? const []).cast<String>(),
        exercises: ((j['exercises'] as List?) ?? const [])
            .cast<Map<String, dynamic>>(),
      );
}

class EditorLessonRemote {
  final int lessonId;
  final String title;
  final String description;
  final List<String> words;
  final int exerciseCount;
  const EditorLessonRemote({
    required this.lessonId,
    required this.title,
    required this.description,
    required this.words,
    required this.exerciseCount,
  });
  factory EditorLessonRemote.fromJson(Map<String, dynamic> j) =>
      EditorLessonRemote(
        lessonId: j['lesson_id'] as int,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        words: ((j['words'] as List?) ?? const []).cast<String>(),
        exerciseCount: (j['exercise_count'] as int?) ?? 0,
      );
}

class EditorModuleRemote {
  final int moduleId;
  final String title;
  final String description;
  final int weight;
  final List<EditorLessonRemote> lessons;
  const EditorModuleRemote({
    required this.moduleId,
    required this.title,
    required this.description,
    required this.weight,
    required this.lessons,
  });
  factory EditorModuleRemote.fromJson(Map<String, dynamic> j) =>
      EditorModuleRemote(
        moduleId: j['module_id'] as int,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        weight: (j['weight'] as int?) ?? 0,
        lessons: ((j['lessons'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(EditorLessonRemote.fromJson)
            .toList(),
      );
}

class EditorCourseDetail {
  final int courseId;
  final String title;
  final String description;
  final String lang;
  final String toLang;
  final CourseStatusWire status;
  final CourseAccessWire access;
  final int lessonCount;
  final int moduleCount;
  final int studentCount;
  final String updatedHuman;
  final List<EditorModuleRemote> modules;

  const EditorCourseDetail({
    required this.courseId,
    required this.title,
    required this.description,
    required this.lang,
    required this.toLang,
    required this.status,
    required this.access,
    required this.lessonCount,
    required this.moduleCount,
    required this.studentCount,
    required this.updatedHuman,
    required this.modules,
  });

  factory EditorCourseDetail.fromJson(Map<String, dynamic> j) =>
      EditorCourseDetail(
        courseId: j['course_id'] as int,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        lang: (j['lang'] as String?) ?? '',
        toLang: (j['to_lang'] as String?) ?? '',
        status: _statusFromWire(j['status'] as String?),
        access: _accessFromWire(j['access'] as String?),
        lessonCount: (j['lesson_count'] as int?) ?? 0,
        moduleCount: (j['module_count'] as int?) ?? 0,
        studentCount: (j['student_count'] as int?) ?? 0,
        updatedHuman: _humanizeIso(j['updated_at'] as String?),
        modules: ((j['modules'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(EditorModuleRemote.fromJson)
            .toList(),
      );
}

enum EditorRoleWire { owner, editor, viewer }

EditorRoleWire _roleFromWire(String? s) {
  switch (s) {
    case 'owner':
      return EditorRoleWire.owner;
    case 'viewer':
      return EditorRoleWire.viewer;
    default:
      return EditorRoleWire.editor;
  }
}

class SchoolUser {
  final int schoolUserId;
  final int schoolId;
  final String name;
  final String email;
  final EditorRoleWire role;
  final List<String> assignedLanguages;
  final int coursesOwned;
  final String? lastSeenHuman;
  final String status; // active | suspended

  const SchoolUser({
    required this.schoolUserId,
    required this.schoolId,
    required this.name,
    required this.email,
    required this.role,
    required this.assignedLanguages,
    required this.coursesOwned,
    required this.lastSeenHuman,
    required this.status,
  });

  factory SchoolUser.fromJson(Map<String, dynamic> j) => SchoolUser(
        schoolUserId: j['school_user_id'] as int,
        schoolId: j['school_id'] as int,
        name: (j['name'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        role: _roleFromWire(j['role'] as String?),
        assignedLanguages:
            ((j['assigned_languages'] as List?) ?? const []).cast<String>(),
        coursesOwned: (j['courses_owned'] as int?) ?? 0,
        lastSeenHuman: _humanizeIso(j['last_seen'] as String?),
        status: (j['status'] as String?) ?? 'active',
      );

  /// First+last initial; falls back to email local-part when name is empty.
  String get initials {
    final source = name.trim().isNotEmpty ? name : email.split('@').first;
    final parts = source.trim().split(RegExp(r'[\s.]+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

enum StudentStatusWire { active, slowing, inactive, noCourse }

StudentStatusWire _studentStatusFromWire(String? s) {
  switch (s) {
    case 'active':
      return StudentStatusWire.active;
    case 'slowing':
      return StudentStatusWire.slowing;
    case 'inactive':
      return StudentStatusWire.inactive;
    case 'no_course':
      return StudentStatusWire.noCourse;
    default:
      return StudentStatusWire.active;
  }
}

class StudentRowRemote {
  final int userId;
  final String name;
  final String email;
  final String lang;
  final String langFlag;
  final String langName;
  final String course;
  final double progress;
  final String lastSeenHuman;
  final StudentStatusWire status;

  const StudentRowRemote({
    required this.userId,
    required this.name,
    required this.email,
    required this.lang,
    required this.langFlag,
    required this.langName,
    required this.course,
    required this.progress,
    required this.lastSeenHuman,
    required this.status,
  });

  factory StudentRowRemote.fromJson(Map<String, dynamic> j) => StudentRowRemote(
        userId: (j['user_id'] as int?) ?? 0,
        name: (j['name'] as String?) ?? '—',
        email: (j['email'] as String?) ?? '',
        lang: (j['lang'] as String?) ?? '',
        langFlag: (j['lang_flag'] as String?) ?? '',
        langName: (j['lang_name'] as String?) ?? '',
        course: (j['course'] as String?) ?? '—',
        progress: ((j['progress'] as num?) ?? 0).toDouble(),
        lastSeenHuman: (j['last_seen_human'] as String?) ?? 'Never',
        status: _studentStatusFromWire(j['status'] as String?),
      );

  /// Letter-avatar gradient key, deterministic per user so colors are
  /// stable across refetches. Cycles through a..h.
  String get avatarKey {
    const keys = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return keys[userId.abs() % keys.length];
  }

  String get initials {
    final source = name.trim().isNotEmpty ? name : email.split('@').first;
    final parts = source.trim().split(RegExp(r'[\s.]+'));
    if (parts.isEmpty || parts.first.isEmpty) return '—';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
