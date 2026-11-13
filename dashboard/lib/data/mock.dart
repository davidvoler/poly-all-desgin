// Mock data backing the dashboard screens. Mirrors the numbers used
// in design_experiments/school_dashboard/*.html so the Flutter port
// renders the same demo. Swap with real API calls once the
// /api/v1/school/... endpoints land.

class School {
  final String mark;
  final String name;
  final String plan;
  final int streakDays;
  const School({
    required this.mark,
    required this.name,
    required this.plan,
    required this.streakDays,
  });
}

class CurrentUser {
  final String initials;
  final String name;
  final String email;
  const CurrentUser({
    required this.initials,
    required this.name,
    required this.email,
  });
}

class StatTile {
  final String value;
  final String label;
  final String detail;
  final TrendDirection trend;
  const StatTile({
    required this.value,
    required this.label,
    required this.detail,
    this.trend = TrendDirection.flat,
  });
}

enum TrendDirection { up, down, flat }

enum ActivityKind { upload, invite, generic }

class ActivityRow {
  final ActivityKind kind;
  final String actor;
  // HTML snippet without tags — first <b>…</b> region gets emphasised
  // in the UI by splitting on a single sentinel.
  final String summary;
  final String when;
  const ActivityRow({
    required this.kind,
    required this.actor,
    required this.summary,
    required this.when,
  });
}

class LanguageCard {
  final String flag;
  final String native;
  final String english;
  final bool rtl;
  final int? courses;
  final int students;
  final String? percentOfSchool; // for native cards
  final bool active;
  const LanguageCard({
    required this.flag,
    required this.native,
    required this.english,
    this.rtl = false,
    this.courses,
    required this.students,
    this.percentOfSchool,
    this.active = true,
  });
}

enum CourseAccess { public, members }

enum CourseStatus { draft, review, published, archived }

class CourseRow {
  final String mark;       // 2-char language glyph (e.g. عر, עב)
  final String avatarKey;  // a/b/c/... — drives the avatar gradient
  final String title;
  final String tagline;
  final String langFlag;
  final String langName;
  final int modules;
  final int lessons;
  final int students;
  final CourseAccess access;
  final CourseStatus status;
  final String updated;
  const CourseRow({
    required this.mark,
    required this.avatarKey,
    required this.title,
    required this.tagline,
    required this.langFlag,
    required this.langName,
    required this.modules,
    required this.lessons,
    required this.students,
    required this.access,
    required this.status,
    required this.updated,
  });
}

enum EditorRole { owner, editor, viewer }

class EditorRow {
  final String initials;
  final String avatarKey;
  final String name;
  final bool isYou;
  final String email;
  final EditorRole role;
  final String? langFlag;
  final String langLabel; // "Arabic" | "All"
  final String coursesLabel; // "14" | "—"
  final String lastSeen;
  final bool active;
  const EditorRow({
    required this.initials,
    required this.avatarKey,
    required this.name,
    this.isYou = false,
    required this.email,
    required this.role,
    this.langFlag,
    required this.langLabel,
    required this.coursesLabel,
    required this.lastSeen,
    this.active = true,
  });
}

enum StudentStatus { active, slowing, inactive, noCourse }

class StudentRow {
  final String initials;
  final String avatarKey;
  final String name;
  final String email;
  final String langFlag;
  final String langName;
  final String course; // may be "—"
  final double progress; // 0..1
  final String lastSeen;
  final StudentStatus status;
  const StudentRow({
    required this.initials,
    required this.avatarKey,
    required this.name,
    required this.email,
    required this.langFlag,
    required this.langName,
    required this.course,
    required this.progress,
    required this.lastSeen,
    required this.status,
  });
}

/// Single global mock store — referenced directly from the pages. In a
/// real app this would be replaced with FutureProviders fetching the
/// server.
class MockData {
  static const School school = School(
    mark: 'RA',
    name: 'Riverside Academy',
    plan: 'Pro Plan',
    streakDays: 14,
  );

  static const CurrentUser me = CurrentUser(
    initials: 'DU',
    name: 'Demo User',
    email: 'demo@local.dev',
  );

  // -------- Overview --------
  static const List<StatTile> overviewStats = [
    StatTile(value: '3', label: 'Active languages', detail: 'of 6 available'),
    StatTile(
        value: '14',
        label: 'Courses',
        detail: '+2 this month',
        trend: TrendDirection.up),
    StatTile(value: '5', label: 'Editors', detail: '2 invites pending'),
    StatTile(
        value: '248',
        label: 'Students',
        detail: '142 active today',
        trend: TrendDirection.up),
  ];

  static const List<ActivityRow> activity = [
    ActivityRow(
      kind: ActivityKind.upload,
      actor: 'Maya Cohen',
      summary: 'Uploaded course **Hebrew · A1 Foundations** — 6 modules, 32 lessons',
      when: '2 h ago',
    ),
    ActivityRow(
      kind: ActivityKind.invite,
      actor: 'You',
      summary: 'Invited **omar.dawud@riverside.edu** as Editor — Arabic',
      when: '5 h ago',
    ),
    ActivityRow(
      kind: ActivityKind.generic,
      actor: 'Sarah Levin',
      summary: 'Added **12 students** via CSV upload — cohort *Spring-A*',
      when: 'Yesterday',
    ),
    ActivityRow(
      kind: ActivityKind.upload,
      actor: 'Omar Dawud',
      summary: 'Updated lesson **Module 3 · Greetings** — Arabic',
      when: 'Yesterday',
    ),
    ActivityRow(
      kind: ActivityKind.invite,
      actor: 'You',
      summary: 'Activated **Italian** for the school',
      when: '2 days ago',
    ),
  ];

  // -------- Languages --------
  static const List<LanguageCard> taughtLanguages = [
    LanguageCard(
        flag: '🇸🇦',
        native: 'العربية',
        english: 'Arabic',
        rtl: true,
        courses: 5,
        students: 112),
    LanguageCard(
        flag: '🇮🇱',
        native: 'עברית',
        english: 'Hebrew',
        rtl: true,
        courses: 6,
        students: 94),
    LanguageCard(
        flag: '🇮🇹',
        native: 'Italiano',
        english: 'Italian',
        courses: 3,
        students: 42),
  ];

  static const List<LanguageCard> nativeLanguages = [
    LanguageCard(
        flag: '🇺🇸',
        native: 'English',
        english: 'Spoken natively',
        students: 198,
        percentOfSchool: '80%'),
    LanguageCard(
        flag: '🇮🇱',
        native: 'עברית',
        english: 'Hebrew · spoken natively',
        rtl: true,
        students: 32,
        percentOfSchool: '13%'),
    LanguageCard(
        flag: '🇸🇦',
        native: 'العربية',
        english: 'Arabic · spoken natively',
        rtl: true,
        students: 18,
        percentOfSchool: '7%'),
  ];

  // -------- Courses --------
  static const List<CourseRow> courses = [
    CourseRow(
      mark: 'عر',
      avatarKey: 'a',
      title: 'Arabic · A1 Foundations',
      tagline: 'Greetings, family, daily life',
      langFlag: '🇸🇦',
      langName: 'Arabic',
      modules: 8,
      lessons: 64,
      students: 82,
      access: CourseAccess.public,
      status: CourseStatus.published,
      updated: '2 h ago',
    ),
    CourseRow(
      mark: 'عر',
      avatarKey: 'a',
      title: 'Arabic · A2 Conversations',
      tagline: 'Restaurants, travel, work',
      langFlag: '🇸🇦',
      langName: 'Arabic',
      modules: 6,
      lessons: 48,
      students: 30,
      access: CourseAccess.members,
      status: CourseStatus.published,
      updated: 'Yesterday',
    ),
    CourseRow(
      mark: 'עב',
      avatarKey: 'b',
      title: 'Hebrew · A1 Foundations',
      tagline: 'Alphabet, greetings, family',
      langFlag: '🇮🇱',
      langName: 'Hebrew',
      modules: 6,
      lessons: 32,
      students: 61,
      access: CourseAccess.public,
      status: CourseStatus.published,
      updated: '2 h ago',
    ),
    CourseRow(
      mark: 'עב',
      avatarKey: 'b',
      title: 'Hebrew · Biblical Reader',
      tagline: 'Old-Testament excerpts, annotated',
      langFlag: '🇮🇱',
      langName: 'Hebrew',
      modules: 5,
      lessons: 40,
      students: 18,
      access: CourseAccess.members,
      status: CourseStatus.published,
      updated: '3 days ago',
    ),
    CourseRow(
      mark: 'IT',
      avatarKey: 'c',
      title: 'Italian · A1 Foundations',
      tagline: 'Greetings, family, basic verbs',
      langFlag: '🇮🇹',
      langName: 'Italian',
      modules: 5,
      lessons: 30,
      students: 42,
      access: CourseAccess.public,
      status: CourseStatus.draft,
      updated: 'Today',
    ),
  ];

  // -------- Editors --------
  static const List<EditorRow> editors = [
    EditorRow(
      initials: 'DU',
      avatarKey: 'du',
      name: 'Demo User',
      isYou: true,
      email: 'demo@local.dev',
      role: EditorRole.owner,
      langLabel: 'All',
      coursesLabel: '14',
      lastSeen: 'Now',
    ),
    EditorRow(
      initials: 'MC',
      avatarKey: 'e',
      name: 'Maya Cohen',
      email: 'maya.cohen@riverside.edu',
      role: EditorRole.editor,
      langFlag: '🇮🇱',
      langLabel: 'Hebrew',
      coursesLabel: '6',
      lastSeen: '2 h ago',
    ),
    EditorRow(
      initials: 'OD',
      avatarKey: 'a',
      name: 'Omar Dawud',
      email: 'omar.dawud@riverside.edu',
      role: EditorRole.editor,
      langFlag: '🇸🇦',
      langLabel: 'Arabic',
      coursesLabel: '5',
      lastSeen: '5 h ago',
    ),
    EditorRow(
      initials: 'GR',
      avatarKey: 'c',
      name: 'Giulia Romano',
      email: 'giulia.r@riverside.edu',
      role: EditorRole.editor,
      langFlag: '🇮🇹',
      langLabel: 'Italian',
      coursesLabel: '3',
      lastSeen: 'Yesterday',
    ),
    EditorRow(
      initials: 'SL',
      avatarKey: 'd',
      name: 'Sarah Levin',
      email: 'sarah.l@riverside.edu',
      role: EditorRole.viewer,
      langLabel: 'All',
      coursesLabel: '—',
      lastSeen: '3 days ago',
    ),
  ];

  // -------- Students --------
  static const List<StudentRow> students = [
    StudentRow(
      initials: 'AB',
      avatarKey: 'a',
      name: 'Ahmed Barakat',
      email: 'ahmed.b@riverside.edu',
      langFlag: '🇸🇦',
      langName: 'Arabic',
      course: 'A1 Foundations · Module 4',
      progress: 0.62,
      lastSeen: '3 m ago',
      status: StudentStatus.active,
    ),
    StudentRow(
      initials: 'YK',
      avatarKey: 'b',
      name: 'Yael Katz',
      email: 'yael.k@riverside.edu',
      langFlag: '🇮🇱',
      langName: 'Hebrew',
      course: 'A1 Foundations · Module 2',
      progress: 0.34,
      lastSeen: '14 m ago',
      status: StudentStatus.active,
    ),
    StudentRow(
      initials: 'LV',
      avatarKey: 'c',
      name: 'Luca Verdi',
      email: 'luca.v@riverside.edu',
      langFlag: '🇮🇹',
      langName: 'Italian',
      course: 'A1 Foundations · Module 6',
      progress: 0.88,
      lastSeen: '1 h ago',
      status: StudentStatus.active,
    ),
    StudentRow(
      initials: 'RN',
      avatarKey: 'd',
      name: 'Rana Najjar',
      email: 'rana.n@riverside.edu',
      langFlag: '🇸🇦',
      langName: 'Arabic',
      course: 'A2 Conversations · Module 1',
      progress: 0.18,
      lastSeen: 'Yesterday',
      status: StudentStatus.active,
    ),
    StudentRow(
      initials: 'DT',
      avatarKey: 'e',
      name: 'Daniel Tov',
      email: 'daniel.t@riverside.edu',
      langFlag: '🇮🇱',
      langName: 'Hebrew',
      course: 'Biblical Reader · Module 1',
      progress: 0.09,
      lastSeen: '3 days ago',
      status: StudentStatus.slowing,
    ),
    StudentRow(
      initials: 'SM',
      avatarKey: 'f',
      name: 'Sara Moretti',
      email: 'sara.m@riverside.edu',
      langFlag: '🇮🇹',
      langName: 'Italian',
      course: 'A1 Foundations · Module 3',
      progress: 0.47,
      lastSeen: '2 h ago',
      status: StudentStatus.active,
    ),
    StudentRow(
      initials: 'NC',
      avatarKey: 'g',
      name: 'Noor Chahine',
      email: 'noor.c@riverside.edu',
      langFlag: '🇸🇦',
      langName: 'Arabic',
      course: 'A1 Foundations · Module 1',
      progress: 0.04,
      lastSeen: '3 weeks ago',
      status: StudentStatus.inactive,
    ),
    StudentRow(
      initials: 'EM',
      avatarKey: 'h',
      name: 'Eli Margolis',
      email: 'eli.m@riverside.edu',
      langFlag: '🇮🇱',
      langName: 'Hebrew',
      course: '—',
      progress: 0.0,
      lastSeen: 'Never',
      status: StudentStatus.noCourse,
    ),
  ];
}
