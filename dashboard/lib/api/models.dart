// Wire-format models that mirror the FastAPI server-side Pydantic
// classes. Each fromJson is defensive on optional fields so a
// partially-populated row still renders.

class SchoolInfo {
  final int schoolId;
  final String slug;
  final String name;
  final String plan;
  final bool isPublic;
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
    required this.isPublic,
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
        isPublic: (j['is_public'] as bool?) ?? false,
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

/// Course editing was simplified server-side to publish/unpublish only
/// (see server/EDITOR.md option 2) — the DB still has a 4-value
/// `status` column, but `models.edit.course.Course` collapses it to a
/// single `published` bool, so the dashboard follows suit.
class EditorCourse {
  final int courseId;
  final String title;
  final String description;
  final String lang;
  final String toLang;
  final bool published;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final CourseMeta meta;

  const EditorCourse({
    required this.courseId,
    required this.title,
    required this.description,
    required this.lang,
    required this.toLang,
    required this.published,
    this.tags = const [],
    this.metadata = const {},
    this.meta = CourseMeta.empty,
  });

  factory EditorCourse.fromJson(Map<String, dynamic> j) {
    final rawMeta =
        (j['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
    return EditorCourse(
      courseId: j['course_id'] as int,
      title: (j['title'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      lang: (j['lang'] as String?) ?? '',
      toLang: (j['to_lang'] as String?) ?? '',
      published: (j['published'] as bool?) ?? false,
      tags: ((j['tags'] as List?) ?? const []).cast<String>(),
      metadata: rawMeta,
      meta: CourseMeta.fromJson(rawMeta),
    );
  }

  /// Round-trips `tags`/`metadata` unchanged — the edit form only
  /// touches title/description/published, but POST /course rewrites
  /// every column, so omitting them here would silently wipe them.
  Map<String, dynamic> toJson() => {
        'course_id': courseId,
        'title': title,
        'description': description,
        'lang': lang,
        'to_lang': toLang,
        'tags': tags,
        'metadata': metadata,
        'published': published,
      };

  EditorCourse copyWith({
    String? title,
    String? description,
    bool? published,
  }) =>
      EditorCourse(
        courseId: courseId,
        title: title ?? this.title,
        description: description ?? this.description,
        lang: lang,
        toLang: toLang,
        published: published ?? this.published,
        tags: tags,
        metadata: metadata,
        meta: meta,
      );
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

/// One course-metadata variant descriptor (a reading or sentence-alt the
/// course declares) — display name plus optional icon/tooltip and, for
/// sentence-alt variants, the slot it labels.
class VariantDescriptor {
  final String name;
  final String? icon;
  final String? tooltip;
  final int? slot;
  const VariantDescriptor({
    required this.name,
    this.icon,
    this.tooltip,
    this.slot,
  });
  factory VariantDescriptor.fromJson(Map<String, dynamic> j) =>
      VariantDescriptor(
        name: (j['name'] as String?) ?? '',
        icon: j['icon'] as String?,
        tooltip: j['tooltip_text'] as String?,
        slot: (j['slot'] as num?)?.toInt(),
      );
}

/// Course-level display metadata: the reading (`ruby_text`) and full-sentence
/// (`sentence_alt`) variants the course offers. Empty when unset.
class CourseMeta {
  final List<VariantDescriptor> rubyText;
  final List<VariantDescriptor> sentenceAlt;
  const CourseMeta({this.rubyText = const [], this.sentenceAlt = const []});

  static const empty = CourseMeta();
  bool get isEmpty => rubyText.isEmpty && sentenceAlt.isEmpty;

  factory CourseMeta.fromJson(Object? raw) {
    if (raw is! Map) return CourseMeta.empty;
    List<VariantDescriptor> parse(Object? v) => v is List
        ? v
            .whereType<Map>()
            .map((m) => VariantDescriptor.fromJson(m.cast<String, dynamic>()))
            .where((d) => d.name.isNotEmpty)
            .toList()
        : const [];
    return CourseMeta(
      rubyText: parse(raw['ruby_text']),
      sentenceAlt: parse(raw['sentence_alt']),
    );
  }
}

/// Role enum in lockstep with `school.school_users.role` on the
/// server. Order matters: admin > super_editor > editor > reviewer >
/// student is the rough "powers" gradient the UI uses for ACL gating.
enum EditorRoleWire { admin, editor, superEditor, reviewer, student }

EditorRoleWire _roleFromWire(String? s) {
  switch (s) {
    case 'admin':
    // Tolerate old persisted sessions that still say "owner" — we
    // migrated server-side but a cached LoginInfo from before the
    // migration might still carry the old label.
    case 'owner':
      return EditorRoleWire.admin;
    case 'super_editor':
      return EditorRoleWire.superEditor;
    case 'reviewer':
    case 'viewer':
      return EditorRoleWire.reviewer;
    case 'student':
      return EditorRoleWire.student;
    default:
      return EditorRoleWire.editor;
  }
}

/// Wire string used when sending the role back to the server. Stays
/// in lockstep with the check constraint in DDL/school.sql.
String roleToWire(EditorRoleWire role) => switch (role) {
      EditorRoleWire.admin => 'admin',
      EditorRoleWire.editor => 'editor',
      EditorRoleWire.superEditor => 'super_editor',
      EditorRoleWire.reviewer => 'reviewer',
      EditorRoleWire.student => 'student',
    };

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

  // --- Course AI POC (mirrors server/src/models/edit/generate_poc.py) ----
}

/// Mirrors the server's `PromptType` enum.
enum PromptType { createLesson, getWords, createCourse, createModules }

String promptTypeToWire(PromptType t) => switch (t) {
      PromptType.createLesson => 'create_lesson',
      PromptType.getWords => 'get_words',
      PromptType.createCourse => 'create_course',
      PromptType.createModules => 'create_modules',
    };

PromptType promptTypeFromWire(String? wire) => switch (wire) {
      'create_lesson' => PromptType.createLesson,
      'get_words' => PromptType.getWords,
      'create_modules' => PromptType.createModules,
      _ => PromptType.createCourse,
    };

/// Mirrors `PromptResponseOption` — one of the "what next" choices offered
/// after a generate_poc call (e.g. "Create Lesson", "Get Words List").
class PromptResponseOption {
  final String title;
  final String text;
  final PromptType promptType;

  const PromptResponseOption({
    required this.title,
    required this.text,
    required this.promptType,
  });

  factory PromptResponseOption.fromJson(Map<String, dynamic> j) =>
      PromptResponseOption(
        title: (j['title'] as String?) ?? '',
        text: (j['text'] as String?) ?? '',
        promptType: promptTypeFromWire(j['prompt_type'] as String?),
      );
}

/// Mirrors `PromptResponse` — the result of any /api/v1/generate_poc/* call.
class PromptResponse {
  final PromptType? promptType;
  final String prompt;
  final String title;
  final String description;
  final List<PromptResponseOption> options;
  final String response;
  final int? courseId;
  final String? lang;
  final String? toLang;

  const PromptResponse({
    this.promptType,
    this.prompt = '',
    this.title = '',
    this.description = '',
    this.options = const [],
    this.response = '',
    this.courseId,
    this.lang,
    this.toLang,
  });

  factory PromptResponse.fromJson(Map<String, dynamic> j) => PromptResponse(
        promptType: j['prompt_type'] != null
            ? promptTypeFromWire(j['prompt_type'] as String?)
            : null,
        prompt: (j['prompt'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        options: ((j['options'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PromptResponseOption.fromJson)
            .toList(),
        response: (j['response'] as String?) ?? '',
        courseId: j['course_id'] as int?,
        lang: j['lang'] as String?,
        toLang: j['to_lang'] as String?,
      );
}
