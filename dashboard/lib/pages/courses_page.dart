import 'dart:convert' show Utf8Decoder;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../util/download.dart';
import '../widgets/common.dart';
import '../widgets/data_table.dart';
import '../widgets/search_field.dart';
import '../widgets/shell.dart';

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The course list is shown to everyone. Uploading new content, though,
    // requires accepting the editor Terms & Conditions first: when the server
    // reports permissions['signed_terms'] == true we disable the upload CTAs
    // and show a notice pointing to where the terms can be accepted.
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
        if (needsTerms)
          Tooltip(
            message: 'Accept the editor terms to upload courses',
            child: Opacity(
              opacity: 0.5,
              child: PrimaryButton(
                label: 'Upload course',
                leading: Icons.file_upload_outlined,
                onTap: null,
              ),
            ),
          )
        else
          PrimaryButton(
            label: 'Upload course',
            leading: Icons.file_upload_outlined,
            onTap: () => _pickAndUploadYaml(context, ref),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needsTerms) ...[
            const _TermsNotice(),
            const SizedBox(height: 14),
          ],
          _Dropzone(
            onBrowse:
                needsTerms ? null : () => _pickAndUploadYaml(context, ref),
          ),
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

/// Reads a picked file's bytes as UTF-8 text and posts it to
/// POST /api/v1/edit/course/import/ as-is — the server now expects a
/// single YAML document (`type: course/module/lesson/exercise` sections
/// separated by `---`, the same shape a course export produces), not a
/// zip archive. Shared by the topbar CTA and the dropzone.
Future<void> _pickAndUploadYaml(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);

  // FileType.custom + allowedExtensions relies on the OS/browser
  // recognizing the extension as a registered file type — macOS in
  // particular often just hides files with unrecognized extensions
  // (like .yaml) from the native picker instead of merely disabling
  // them. Pick from all files instead and validate the extension here.
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Pick a course .yaml or .txt file',
    type: FileType.any,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;
  final picked = result.files.first;
  final ext = picked.extension?.toLowerCase();
  if (ext != 'yaml' && ext != 'yml' && ext != 'txt') {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
            '${picked.name}: expected a .yaml, .yml, or .txt file'),
      ),
    );
    return;
  }
  final bytes = picked.bytes;
  if (bytes == null) return;

  String document;
  try {
    document = const Utf8Decoder().convert(bytes);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('${picked.name} is not valid UTF-8 text: $e')),
    );
    return;
  }

  messenger.showSnackBar(
    SnackBar(
      content: Text('Uploading ${picked.name}…'),
      duration: const Duration(seconds: 60),
    ),
  );
  try {
    final courseId = await ref
        .read(dashboardApiProvider)
        .importCourseText(document: document);
    ref.invalidate(editorCoursesProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(schoolStatsProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(courseId == null
              ? 'Upload succeeded'
              : 'Uploaded — created course #$courseId'),
        ),
      );
  } catch (e, st) {
    // Log the full error + stack to the console (flutter run terminal /
    // browser DevTools) so a transient SnackBar isn't the only record.
    debugPrint('Upload failed: $e\n$st');
    final message = 'Upload failed: $e';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // SelectableText so the error can be highlighted; the Copy
          // action puts the whole message on the clipboard in one tap.
          content: SelectableText(message),
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () => Clipboard.setData(ClipboardData(text: message)),
          ),
        ),
      );
  }
}

class _Dropzone extends StatelessWidget {
  /// Null disables the dropzone's Browse action (e.g. terms not yet accepted).
  final VoidCallback? onBrowse;
  const _Dropzone({required this.onBrowse});

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
            'Drag a course .yaml or .txt file here',
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
              'A single YAML document: type: course/module/lesson/exercise '
              'sections separated by "---" — the same shape Export produces.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: onBrowse == null ? 0.5 : 1,
                child: PrimaryButton(
                  label: 'Browse files',
                  leading: Icons.file_upload_outlined,
                  onTap: onBrowse,
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
                'A single YAML file — the same shape produced by exporting a '
                'course from the Courses row menu.',
                style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _section('Shape'),
                      _hint(
                        'One or more sections separated by "---". Each '
                        'section is plain YAML starting with a "type" key: '
                        'course, module, lesson, or exercise — nested in '
                        'that order.',
                      ),
                      const SizedBox(height: 14),
                      _section('Example'),
                      const _CodeBlock('''type: course
title: Italian for English Speakers
description: Essential grammar + vocabulary.
lang: it
to_lang: en
level: 0
status: draft
---
type: module
title: Introduction to Italian
description: Basics
weight: 1
---
type: lesson
title: Greetings
description: Common greeting phrases
weight: 1
---
type: exercise
exercise_type: multiple_choice
sentence: Buona sera
options:
  - Good evening
    correct: true
  - Good morning
  - Good night
weight: 1'''),
                      const SizedBox(height: 6),
                      _hint(
                        'lang / to_lang are ISO codes. weight controls '
                        'ordering within the parent. A course needs at '
                        'least one module/lesson/exercise chain to import.',
                      ),
                      const SizedBox(height: 14),
                      _section('Round-trip'),
                      _hint(
                        'Export any course from the Courses row menu to get a '
                        'course.yaml with this same content — edit it '
                        'locally, then upload it back here.',
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
