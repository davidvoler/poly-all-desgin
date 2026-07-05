import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../util/download.dart';
import '../widgets/common.dart';
import '../widgets/data_table.dart';
import '../widgets/search_field.dart';
import '../widgets/shell.dart';

/// The server no longer has a zip-import endpoint (course editing was
/// simplified to publish/unpublish + single-document import/export, see
/// server/EDITOR.md) — upload entry points stay visible but disabled
/// until a zip-import route exists again.
const String kZipUploadDisabledMessage =
    "Zip import isn't available yet — use Create with AI.";

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The course list is shown to everyone. Creating new content still
    // requires accepting the editor Terms & Conditions first: when the
    // server reports permissions['signed_terms'] == true we show a notice
    // pointing to where the terms can be accepted.
    final needsTerms = ref.watch(meProvider).value?.needsTerms ?? false;
    return DashboardShell(
      title: 'Courses',
      activeRoute: '/courses',
      topbarTrailing: [
        GhostButton(
          label: 'Create with AI',
          leading: Icons.auto_awesome_outlined,
          onTap: () => Navigator.pushNamed(context, '/create-course'),
        ),
        Tooltip(
          message: kZipUploadDisabledMessage,
          child: Opacity(
            opacity: 0.5,
            child: PrimaryButton(
              label: 'Upload course',
              leading: Icons.file_upload_outlined,
              onTap: null,
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needsTerms) ...[
            const _TermsNotice(),
            const SizedBox(height: 14),
          ],
          const _Dropzone(),
          const SizedBox(height: 18),
          const _CoursesPanel(),
        ],
      ),
    );
  }
}

/// Inline banner shown above the courses list when the signed-in user hasn't
/// accepted the editor Terms & Conditions. The list stays visible; only
/// uploading is disabled. "Review terms" jumps to Create with AI, which shows
/// the full terms gate + Accept button.
class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: DashColors.orange300.withValues(alpha: 0.10),
        borderRadius: DashRadii.card,
        border: Border.all(color: DashColors.orange300.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: DashColors.orange300),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Accept the editor Terms & Conditions to upload or create '
              'content. Browsing the catalogue stays open to everyone.',
              style: TextStyle(fontSize: 12.5, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GhostButton(
            label: 'Review terms',
            leading: Icons.gavel_outlined,
            onTap: () => Navigator.pushNamed(context, '/create-course'),
          ),
        ],
      ),
    );
  }
}

class _Dropzone extends StatelessWidget {
  /// The zip-import endpoint no longer exists server-side — this stays
  /// as a visible placeholder (see [kZipUploadDisabledMessage]) until a
  /// zip-import route comes back.
  const _Dropzone();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        borderRadius: DashRadii.card,
        border: Border.all(
          color: DashColors.w(0.18),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DashColors.w(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.file_upload_outlined,
                size: 22, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag a course folder or .zip here',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              'Folder layout: course.txt at the top, then module<n>/lesson<n>/exercises.txt. '
              'A working example lives at content/example_course.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: kZipUploadDisabledMessage,
                child: const Opacity(
                  opacity: 0.5,
                  child: PrimaryButton(
                    label: 'Browse files',
                    leading: Icons.file_upload_outlined,
                    onTap: null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GhostButton(
                label: 'Format help',
                leading: Icons.help_outline,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _FormatHelpDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoursesPanel extends ConsumerStatefulWidget {
  const _CoursesPanel();

  @override
  ConsumerState<_CoursesPanel> createState() => _CoursesPanelState();
}

class _CoursesPanelState extends ConsumerState<_CoursesPanel> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(editorCoursesProvider(CoursesFilter(q: _q)));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'Could not load courses\n$e',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
          ),
        ),
      ),
      data: (rows) {
        final published = rows.where((c) => c.published).length;
        final draft = rows.length - published;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeadRow(
              label: 'All courses',
              subtitle:
                  '·  ${rows.length} total · $published published, $draft draft',
              trailing: [
                SearchField(
                  hint: 'Search title or description…',
                  onChanged: (v) => setState(() => _q = v),
                ),
              ],
            ),
            if (rows.isEmpty)
              _empty(context)
            else
              _CoursesTable(rows: rows),
          ],
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        'No courses yet — create one with AI above.',
        style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
      ),
    );
  }
}

class _CoursesTable extends ConsumerWidget {
  final List<EditorCourse> rows;
  const _CoursesTable({required this.rows});

  StatusPill _statusPill(bool published) => published
      ? const StatusPill(label: 'Published', kind: PillKind.active, swatch: true)
      : const StatusPill(label: 'Draft', kind: PillKind.muted, swatch: true);

  Future<void> _togglePublished(
    BuildContext context,
    WidgetRef ref,
    EditorCourse course,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(dashboardApiProvider);
    final next = course.copyWith(published: !course.published);
    try {
      await api.updateCourse(next);
      ref.invalidate(editorCoursesProvider);
      ref.invalidate(activityProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '"${course.title}" ${next.published ? 'published' : 'moved to draft'}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not change status: $e')),
      );
    }
  }

  /// Deterministic 2-char avatar mark per course (first two letters of
  /// the title's first word, uppercase). Falls back to the course id.
  String _mark(EditorCourse c) {
    final title = c.title.trim();
    if (title.isEmpty) return '#${c.courseId}';
    final first = title.split(RegExp(r'\s+')).first;
    return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _avatarKey(int courseId) {
    const keys = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return keys[courseId.abs() % keys.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashTable(
      columns: const [
        DashCol(label: 'Course', flex: 4),
        DashCol(label: 'Language', flex: 2),
        DashCol(label: 'Status', flex: 2),
        DashCol(label: '', width: 48),
      ],
      rows: [
        for (final c in rows)
          [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.pushNamed(
                context,
                '/course',
                arguments: c.courseId,
              ),
              child: WhoCell(
                initials: _mark(c),
                avatarKey: _avatarKey(c.courseId),
                name: c.title,
                email: c.description,
              ),
            ),
            Text('${c.lang.toUpperCase()} → ${c.toLang.toUpperCase()}'),
            Align(
                alignment: Alignment.centerLeft,
                child: _statusPill(c.published)),
            Align(
              alignment: Alignment.centerRight,
              child: _RowMenu(
                published: c.published,
                onTogglePublished: () => _togglePublished(context, ref, c),
                onExport: () => _exportCourse(context, ref, c),
              ),
            ),
          ],
      ],
    );
  }
}

/// Pulls the course's exported yaml from the server and hands the bytes
/// to download.dart's `saveBytes`, which forks to Blob on web / saveFile
/// on desktop. Shows a snackbar with the filename on success.
Future<void> _exportCourse(
  BuildContext context,
  WidgetRef ref,
  EditorCourse course,
) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(
    content: Text('Exporting ${course.title}…'),
    duration: const Duration(seconds: 30),
  ));
  try {
    final bytes = await ref.read(dashboardApiProvider).exportCourse(course.courseId);
    final filename = 'course_${course.courseId}.yaml';
    final saved = await saveBytes(filename: filename, bytes: bytes);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(saved == null
            ? 'Export cancelled'
            : 'Saved $filename'),
      ));
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

/// Three-dot row menu — toggle publish/draft plus the always-available
/// export action.
class _RowMenu extends StatelessWidget {
  final bool published;
  final VoidCallback onTogglePublished;
  final VoidCallback onExport;
  const _RowMenu({
    required this.published,
    required this.onTogglePublished,
    required this.onExport,
  });

  static const String _kToggle = 'toggle';
  static const String _kExport = 'export';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (key) {
        if (key == _kToggle) {
          onTogglePublished();
        } else if (key == _kExport) {
          onExport();
        }
      },
      color: DashColors.darkBg.withValues(alpha: 0.96),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: _kToggle,
          child: Row(
            children: [
              Icon(
                published ? Icons.unpublished_outlined : Icons.publish_outlined,
                size: 14,
                color: DashColors.w(0.70),
              ),
              const SizedBox(width: 10),
              Text(
                published ? 'Move to draft' : 'Publish',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: _kExport,
          child: Row(
            children: [
              Icon(Icons.download, size: 14, color: DashColors.w(0.70)),
              const SizedBox(width: 10),
              const Text(
                'Export',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: DashColors.w(0.04),
          border: Border.all(color: DashColors.w(0.08)),
        ),
        child: Icon(Icons.more_horiz, size: 14, color: DashColors.w(0.70)),
      ),
    );
  }
}

/// Quick-reference dialog summarising the course import format. The
/// full spec lives in `content/example_course/README.md`; this is the
/// inline cheat-sheet so editors don't have to leave the dashboard.
class _FormatHelpDialog extends StatelessWidget {
  const _FormatHelpDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Course import format',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close,
                        size: 18, color: DashColors.w(0.70)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Full spec: content/example_course/README.md.',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _section('Folder layout'),
                      const _CodeBlock('''my-course/
├── course.txt
├── module1/
│   ├── module.txt
│   ├── lesson1/
│   │   ├── lesson.txt
│   │   └── exercises.txt
│   └── lesson2/
│       └── …
└── module2/
    └── …'''),
                      const SizedBox(height: 14),
                      _section('course.txt'),
                      const _CodeBlock('''name: Italian for English Speakers
description: Essential grammar + vocabulary.
language: Italian
student_languages: English'''),
                      const SizedBox(height: 6),
                      _hint(
                        'language / student_languages accept ISO codes (it, en) '
                        'or English names (Italian, English).',
                      ),
                      const SizedBox(height: 14),
                      _section('module.txt / lesson.txt'),
                      const _CodeBlock('''module: Introduction to Italian
lesson: Greeting sentences'''),
                      const SizedBox(height: 6),
                      _hint(
                        'Numeric suffix in the folder name (module01, '
                        'lesson02) controls order.',
                      ),
                      const SizedBox(height: 14),
                      _section('exercises.txt'),
                      const _CodeBlock('''---
Buona sera
[+] Good evening
[-] Good morning
[-] How are you
--- Explanation
In Italian the vowels often blend together.
---
Buonanotte
[-] Good evening
[+] Good night'''),
                      const SizedBox(height: 6),
                      _hint(
                        '--- separates exercises. First non-blank line = the '
                        'prompt. [+] = correct option, [-] = distractor. '
                        '"--- Explanation" opens a free-text note (ends at '
                        'the next ---).',
                      ),
                      const SizedBox(height: 14),
                      _section('Round-trip'),
                      _hint(
                        'Export any course from the Courses row menu to get a '
                        'course.yaml with this same content — handy for '
                        'reviewing or backing up a course outside the '
                        'dashboard.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title.toUpperCase(),
            style: DashText.sectionLabel(size: 10)),
      );

  Widget _hint(String text) => Text(
        text,
        style: TextStyle(fontSize: 12, color: DashColors.w(0.70)),
      );
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock(this.code);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        borderRadius: DashRadii.cardSm,
        border: Border.all(color: DashColors.w(0.08)),
      ),
      child: SelectableText(
        code,
        style: TextStyle(
          fontSize: 12,
          color: DashColors.w(0.85),
          fontFamily: 'monospace',
          height: 1.45,
        ),
      ),
    );
  }
}
