import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../util/error_text.dart';
import '../widgets/ai_prompt_controls.dart';
import '../widgets/common.dart';
import 'ai_courses_page.dart' show kAiLevels;

/// The video-course workspace — the video-course counterpart of
/// ai_course_workspace_page.dart. Full-bleed, own Scaffold (once inside a
/// course we don't need the sidebar).
///
/// Content generation from the video (subtitle extraction, sectioning,
/// word ranking, quizzes — see TASKS.md "Video Lessons - Implementations")
/// isn't built yet, so this page only covers what's built so far: viewing
/// the video and editing the course meta / generation options. The Preview
/// tab is a placeholder until that pipeline lands.
class VideoCourseWorkspacePage extends ConsumerStatefulWidget {
  final int courseId;
  const VideoCourseWorkspacePage({super.key, required this.courseId});

  @override
  ConsumerState<VideoCourseWorkspacePage> createState() => _VideoCourseWorkspacePageState();
}

enum _Tab { modules, preview, edit }

class _VideoCourseWorkspacePageState extends ConsumerState<VideoCourseWorkspacePage> {
  bool _loading = true;
  String? _loadError;
  VideoCourse? _course;
  _Tab _tab = _Tab.modules;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final course = await ref.read(dashboardApiProvider).fetchVideoCourse(widget.courseId);
      if (!mounted) return;
      setState(() {
        _course = course;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = apiErrorText(e);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: DashColors.darkBg, body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null || _course == null) {
      return Scaffold(
        backgroundColor: DashColors.darkBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText('Could not load video course — ${_loadError ?? 'not found'}',
                textAlign: TextAlign.center, style: TextStyle(color: DashColors.red400)),
          ),
        ),
      );
    }
    final c = _course!;
    return Scaffold(
      backgroundColor: DashColors.darkBg,
      body: Container(
        decoration: kDashBackground,
        child: Column(
          children: [
            _TopBar(title: c.title),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${languageName(c.lang)} → ${languageName(c.toLang)} · Level ${c.level}',
                      style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  _TabButton(label: 'Video Modules', active: _tab == _Tab.modules, onTap: () => setState(() => _tab = _Tab.modules)),
                  _TabButton(label: 'Preview', active: _tab == _Tab.preview, onTap: () => setState(() => _tab = _Tab.preview)),
                  _TabButton(label: 'Edit', active: _tab == _Tab.edit, onTap: () => setState(() => _tab = _Tab.edit)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: DashColors.w(0.06),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                // Modules gets the full width for its list + side pane
                // layout; Preview/Edit stay in the narrow centered column.
                child: switch (_tab) {
                  _Tab.preview => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: SingleChildScrollView(child: _PreviewTab(course: c)),
                      ),
                    ),
                  _Tab.edit => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: SingleChildScrollView(
                          child: _EditTab(
                              course: c, onSaved: (updated) => setState(() => _course = updated)),
                        ),
                      ),
                    ),
                  _Tab.modules => _ModulesTab(
                      course: c, onSaved: (updated) => setState(() => _course = updated)),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Top bar — mirrors ai_course_workspace_page.dart's _TopBar.
// ===========================================================================
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        border: Border(bottom: BorderSide(color: DashColors.w(0.08))),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.pushReplacementNamed(context, '/ai-courses'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, size: 20, color: DashColors.w(0.70)),
                  const SizedBox(width: 2),
                  Text('My courses',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DashColors.w(0.70))),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_collection, size: 18, color: DashColors.w(0.7)),
              const SizedBox(width: 8),
              Text(title, style: DashText.h2),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? DashColors.w(0.06) : Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : DashColors.w(0.55),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Preview — video thumbnail/link + a placeholder until content generation
// (sections, words, quizzes) is built. See TASKS.md "Video Lessons -
// Implementations".
// ===========================================================================
String? _youtubeId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  if (uri.host.contains('youtube.com')) {
    return uri.queryParameters['v'];
  }
  return null;
}

class _PreviewTab extends StatelessWidget {
  final VideoCourse course;
  const _PreviewTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(course.title, style: DashText.h2),
        const SizedBox(height: 2),
        Text(
          '${languageName(course.lang)} → ${languageName(course.toLang)} · Level ${course.level} · '
          '${course.videos.length} video${course.videos.length == 1 ? '' : 's'}',
          style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
        ),
        const SizedBox(height: 16),
        if (course.videos.isEmpty)
          Text('No videos yet — add one from the Edit tab.',
              style: TextStyle(fontSize: 12, color: DashColors.w(0.55)))
        else
          for (final v in course.videos) ...[
            _VideoCard(video: v),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DashColors.w(0.04),
            border: Border.all(color: DashColors.w(0.08)),
            borderRadius: DashRadii.cardSm,
          ),
          child: Row(
            children: [
              Icon(Icons.construction, size: 18, color: DashColors.w(0.55)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Content generation (sections, difficult words, quizzes) from this video "
                  "isn't built yet — see TASKS.md \"Video Lessons - Implementations\".",
                  style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoItem video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final ytId = _youtubeId(video.videoUrl);
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: video.videoUrl));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Video URL copied — paste it into a new tab to watch.'),
            duration: Duration(milliseconds: 1800),
          ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: DashColors.w(0.04),
          border: Border.all(color: DashColors.w(0.08)),
          borderRadius: DashRadii.cardSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ytId != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$ytId/hqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: DashColors.w(0.08)),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.content_copy, size: 14, color: DashColors.w(0.6)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      video.title.isEmpty ? video.videoUrl : '${video.title} — ${video.videoUrl}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: DashColors.w(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Edit — course meta + video playlist + generation options.
// ===========================================================================
class _EditTab extends ConsumerStatefulWidget {
  final VideoCourse course;
  final ValueChanged<VideoCourse> onSaved;
  const _EditTab({required this.course, required this.onSaved});

  @override
  ConsumerState<_EditTab> createState() => _EditTabState();
}

class _EditTabState extends ConsumerState<_EditTab> {
  late final _title = TextEditingController(text: widget.course.title);
  late final _lang = TextEditingController(text: languageName(widget.course.lang));
  late final _toLang = TextEditingController(text: languageName(widget.course.toLang));
  late String _level = widget.course.level;
  late List<VideoItem> _videos = List.of(widget.course.videos);
  late VideoCourseOptions _options = widget.course.metadata;

  final _newVideoUrl = TextEditingController();
  final _newVideoTitle = TextEditingController();
  String? _addVideoError;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _lang.dispose();
    _toLang.dispose();
    _newVideoUrl.dispose();
    _newVideoTitle.dispose();
    super.dispose();
  }

  void _addVideo() {
    final url = _newVideoUrl.text.trim();
    if (url.isEmpty || Uri.tryParse(url)?.hasScheme != true) {
      setState(() => _addVideoError = 'Enter a valid video URL (e.g. https://youtube.com/watch?v=...)');
      return;
    }
    setState(() {
      _videos = [..._videos, VideoItem(videoUrl: url, title: _newVideoTitle.text.trim())];
      _newVideoUrl.clear();
      _newVideoTitle.clear();
      _addVideoError = null;
    });
  }

  void _removeVideo(int index) {
    setState(() => _videos = [..._videos]..removeAt(index));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = widget.course.copyWith(
        title: _title.text.trim(),
        lang: languageCode(_lang.text),
        toLang: languageCode(_toLang.text),
        level: _level,
        videos: _videos,
        metadata: _options,
      );
      final saved = await ref.read(dashboardApiProvider).updateVideoCourse(updated);
      if (!mounted) return;
      widget.onSaved(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COURSE SETTINGS', style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 10),
        CourseField(controller: _title, label: 'Course title', onChanged: () {}),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: LanguageField(controller: _lang, label: 'Learning language', onChanged: () {})),
            const SizedBox(width: 10),
            Expanded(child: LanguageField(controller: _toLang, label: 'Student language', onChanged: () {})),
          ],
        ),
        const SizedBox(height: 10),
        Text('LEVEL', style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 6),
        Segment(options: kAiLevels, selected: _level, onSelect: (v) => setState(() => _level = v)),
        const SizedBox(height: 22),
        Text('VIDEOS', style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 10),
        if (_videos.isEmpty)
          Text('No videos yet — add one below.', style: TextStyle(fontSize: 12, color: DashColors.w(0.55)))
        else
          for (var i = 0; i < _videos.length; i++)
            _VideoEditRow(
              key: ValueKey(_videos[i].videoUrl),
              courseId: widget.course.courseId,
              video: _videos[i],
              onChanged: (updated) => setState(() {
                _videos = [..._videos];
                _videos[i] = updated;
              }),
              onRemove: () => _removeVideo(i),
            ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: CourseField(
                controller: _newVideoUrl,
                label: 'Video URL',
                hint: 'https://www.youtube.com/watch?v=...',
                onChanged: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: CourseField(
                controller: _newVideoTitle,
                label: 'Title (optional)',
                onChanged: () {},
              ),
            ),
          ],
        ),
        if (_addVideoError != null) ...[
          const SizedBox(height: 6),
          SelectableText(_addVideoError!, style: TextStyle(fontSize: 12, color: DashColors.red400)),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: GhostButton(label: 'Add video', leading: Icons.add, onTap: _addVideo),
        ),
        const SizedBox(height: 22),
        VideoCourseOptionsEditor(
          options: _options,
          onChanged: (o) => setState(() => _options = o),
          initiallyExpanded: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          SelectableText('Could not save — $_error', style: TextStyle(fontSize: 12, color: DashColors.red400)),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(label: _saving ? 'Saving…' : 'Save changes', onTap: _saving ? null : _save),
        ),
      ],
    );
  }
}

// ===========================================================================
// Per-video editor row — URL/title fields + the content pipeline buttons
// (Download Subtitles → Extract Words / Extract Phrases / Create Sections).
// A video must already be saved onto the course (Save changes) before the
// pipeline buttons can find it server-side, matched by its exact URL.
// ===========================================================================
class _VideoEditRow extends ConsumerStatefulWidget {
  final int courseId;
  final VideoItem video;
  final ValueChanged<VideoItem> onChanged;
  final VoidCallback onRemove;
  const _VideoEditRow({
    super.key,
    required this.courseId,
    required this.video,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  ConsumerState<_VideoEditRow> createState() => _VideoEditRowState();
}

class _VideoEditRowState extends ConsumerState<_VideoEditRow> {
  late final _url = TextEditingController(text: widget.video.videoUrl);
  late final _title = TextEditingController(text: widget.video.title);
  String? _busyAction;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    super.dispose();
  }

  void _pushUrlTitle() {
    widget.onChanged(widget.video.copyWith(videoUrl: _url.text.trim(), title: _title.text.trim()));
  }

  Future<void> _run(String action, Future<VideoCourse> Function(DashboardApi api) call) async {
    setState(() {
      _busyAction = action;
      _error = null;
    });
    try {
      final updated = await call(ref.read(dashboardApiProvider));
      final match = updated.videos.firstWhere(
        (v) => v.videoUrl == widget.video.videoUrl,
        orElse: () => widget.video,
      );
      if (!mounted) return;
      widget.onChanged(match);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorText(e));
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    final hasSubtitles = v.subtitles != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        border: Border.all(color: DashColors.w(0.08)),
        borderRadius: DashRadii.cardSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: CourseField(
                  controller: _url,
                  label: 'Video URL',
                  hint: 'https://www.youtube.com/watch?v=...',
                  onChanged: _pushUrlTitle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CourseField(controller: _title, label: 'Title (optional)', onChanged: _pushUrlTitle),
              ),
              IconButton(
                tooltip: 'Remove video',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, color: DashColors.w(0.5)),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PipelineButton(
                label: 'Download subtitles',
                doneLabel: '${v.subtitles?.length ?? 0} subtitle lines',
                done: hasSubtitles,
                busy: _busyAction == 'subtitles',
                onTap: () => _run('subtitles',
                    (api) => api.downloadVideoSubtitles(widget.courseId, v.videoUrl)),
              ),
              _PipelineButton(
                label: 'Extract words',
                doneLabel: '${v.words?.length ?? 0} words',
                done: v.words != null,
                busy: _busyAction == 'words',
                enabled: hasSubtitles,
                onTap: () =>
                    _run('words', (api) => api.extractVideoWords(widget.courseId, v.videoUrl)),
              ),
              _PipelineButton(
                label: 'Extract phrases',
                doneLabel: '${v.phrases?.length ?? 0} phrases',
                done: v.phrases != null,
                busy: _busyAction == 'phrases',
                enabled: hasSubtitles,
                onTap: () =>
                    _run('phrases', (api) => api.extractVideoPhrases(widget.courseId, v.videoUrl)),
              ),
              _PipelineButton(
                label: 'Create sections',
                doneLabel: '${v.sections?.length ?? 0} sections',
                done: v.sections != null,
                busy: _busyAction == 'sections',
                enabled: hasSubtitles,
                onTap: () =>
                    _run('sections', (api) => api.createVideoSections(widget.courseId, v.videoUrl)),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            SelectableText(_error!, style: TextStyle(fontSize: 12, color: DashColors.red400)),
          ],
        ],
      ),
    );
  }
}

class _PipelineButton extends StatelessWidget {
  final String label;
  final String doneLabel;
  final bool done;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;
  const _PipelineButton({
    required this.label,
    required this.doneLabel,
    required this.done,
    required this.busy,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = busy || !enabled;
    return InkWell(
      borderRadius: DashRadii.pill,
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: done ? DashColors.brand.withValues(alpha: 0.18) : DashColors.w(0.06),
          borderRadius: DashRadii.pill,
          border: Border.all(color: done ? DashColors.brand : DashColors.w(0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                  width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(
                done ? Icons.check_circle : Icons.play_circle_outline,
                size: 14,
                color: done ? DashColors.brand : DashColors.w(enabled ? 0.7 : 0.3),
              ),
            const SizedBox(width: 6),
            Text(
              done ? doneLabel : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: enabled ? (done ? 1 : 0.85) : 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Video Modules — a module is a single video. Mirrors server VideoModule, a
// real row in course_simple.module (module_type='video'). Unlike the rest
// of the Edit tab, each module is created/edited/deleted through its own
// endpoint immediately — there's no local staging or bulk Save button.
// ===========================================================================
class _ModulesTab extends ConsumerStatefulWidget {
  final VideoCourse course;
  final ValueChanged<VideoCourse> onSaved;
  const _ModulesTab({required this.course, required this.onSaved});

  @override
  ConsumerState<_ModulesTab> createState() => _ModulesTabState();
}

class _ModulesTabState extends ConsumerState<_ModulesTab> {
  late List<VideoModule> _modules = List.of(widget.course.modules);
  int? _selectedModuleId;
  bool _addingModule = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_modules.isNotEmpty) _selectedModuleId = _modules.first.moduleId;
  }

  VideoModule? get _selectedModule {
    if (_selectedModuleId == null) return null;
    for (final m in _modules) {
      if (m.moduleId == _selectedModuleId) return m;
    }
    return null;
  }

  Future<void> _addModule() async {
    setState(() {
      _addingModule = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(dashboardApiProvider)
          .createVideoModule(widget.course.courseId, title: 'Module ${_modules.length + 1}');
      if (!mounted) return;
      setState(() {
        _modules = [..._modules, created];
        _selectedModuleId ??= created.moduleId;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorText(e));
    } finally {
      if (mounted) setState(() => _addingModule = false);
    }
  }

  Future<void> _removeModule(int i) async {
    final module = _modules[i];
    setState(() {
      _modules = [..._modules]..removeAt(i);
      if (_selectedModuleId == module.moduleId) {
        _selectedModuleId = _modules.isNotEmpty ? _modules.first.moduleId : null;
      }
    });
    if (module.moduleId == null) return;
    try {
      await ref.read(dashboardApiProvider).deleteVideoModule(widget.course.courseId, module.moduleId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modules = [..._modules]..insert(i, module);
        _error = apiErrorText(e);
      });
    }
  }

  Future<VideoModule> _updateModule(VideoModule module) =>
      ref.read(dashboardApiProvider).updateVideoModule(module);

  Future<VideoModule> _downloadModuleSubtitles(int moduleId) =>
      ref.read(dashboardApiProvider).downloadModuleSubtitles(widget.course.courseId, moduleId);

  Future<VideoModule> _extractModuleContent(int moduleId) =>
      ref.read(dashboardApiProvider).extractModuleContent(widget.course.courseId, moduleId);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VIDEO MODULES', style: DashText.sectionLabel(size: 10)),
                    const SizedBox(height: 4),
                    Text(
                      'A module is one video.',
                      style: TextStyle(fontSize: 12, color: DashColors.w(0.55)),
                    ),
                    const SizedBox(height: 14),
                    if (_modules.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('No modules yet — add one below.',
                            style: TextStyle(fontSize: 12, color: DashColors.w(0.55))),
                      ),
                    for (var i = 0; i < _modules.length; i++)
                      _ModuleCard(
                        key: ValueKey(_modules[i].moduleId),
                        module: _modules[i],
                        selected: _modules[i].moduleId != null &&
                            _modules[i].moduleId == _selectedModuleId,
                        onSelect: () => setState(() => _selectedModuleId = _modules[i].moduleId),
                        onChanged: (updated) => setState(() {
                          _modules = [..._modules];
                          _modules[i] = updated;
                        }),
                        onRemove: () => _removeModule(i),
                        onSaveModule: _updateModule,
                        onDownloadSubtitles: _downloadModuleSubtitles,
                        onExtractContent: _extractModuleContent,
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GhostButton(
                        label: _addingModule ? 'Adding…' : 'Add module',
                        leading: Icons.add,
                        onTap: _addingModule ? null : _addModule,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      SelectableText(_error!, style: TextStyle(fontSize: 12, color: DashColors.red400)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(width: 300, child: _ModuleContentPane(module: _selectedModule)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Side pane — Words / Sentences / Phrases tabs showing the selected
// module's extracted content (from the "Extract content" button).
// ===========================================================================
enum _ContentTab { words, sentences, phrases }

class _ModuleContentPane extends StatefulWidget {
  final VideoModule? module;
  const _ModuleContentPane({required this.module});

  @override
  State<_ModuleContentPane> createState() => _ModuleContentPaneState();
}

class _ModuleContentPaneState extends State<_ModuleContentPane> {
  _ContentTab _tab = _ContentTab.words;

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashColors.w(0.04),
        border: Border.all(color: DashColors.w(0.08)),
        borderRadius: DashRadii.cardSm,
      ),
      child: m == null
          ? Text(
              'Select a module to see its extracted words, sentences and phrases.',
              style: TextStyle(fontSize: 12, color: DashColors.w(0.5)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  m.title.isEmpty ? 'Module' : m.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PaneTabButton(
                      label: 'Words (${m.words?.length ?? 0})',
                      active: _tab == _ContentTab.words,
                      onTap: () => setState(() => _tab = _ContentTab.words),
                    ),
                    _PaneTabButton(
                      label: 'Sentences (${m.sentences?.length ?? 0})',
                      active: _tab == _ContentTab.sentences,
                      onTap: () => setState(() => _tab = _ContentTab.sentences),
                    ),
                    _PaneTabButton(
                      label: 'Phrases (${m.phrases?.length ?? 0})',
                      active: _tab == _ContentTab.phrases,
                      onTap: () => setState(() => _tab = _ContentTab.phrases),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(child: SingleChildScrollView(child: _paneContent(m))),
              ],
            ),
    );
  }

  Widget _paneContent(VideoModule m) {
    switch (_tab) {
      case _ContentTab.words:
        return _wordChips(m.words, 'words');
      case _ContentTab.sentences:
        return _textList(m.sentences, 'sentences');
      case _ContentTab.phrases:
        return _textList(m.phrases, 'phrases');
    }
  }

  Widget _wordChips(List<String>? items, String noun) {
    if (items == null) {
      return Text('Not extracted yet.', style: TextStyle(fontSize: 12, color: DashColors.w(0.5)));
    }
    if (items.isEmpty) {
      return Text('No $noun found.', style: TextStyle(fontSize: 12, color: DashColors.w(0.5)));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final w in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DashColors.w(0.06),
              borderRadius: DashRadii.pill,
              border: Border.all(color: DashColors.w(0.14)),
            ),
            child: Text(w, style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
      ],
    );
  }

  Widget _textList(List<String>? items, String noun) {
    if (items == null) {
      return Text('Not extracted yet.', style: TextStyle(fontSize: 12, color: DashColors.w(0.5)));
    }
    if (items.isEmpty) {
      return Text('No $noun found.', style: TextStyle(fontSize: 12, color: DashColors.w(0.5)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectableText(s, style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
      ],
    );
  }
}

class _PaneTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PaneTabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: DashRadii.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? DashColors.brand.withValues(alpha: 0.18) : DashColors.w(0.06),
          borderRadius: DashRadii.pill,
          border: Border.all(color: active ? DashColors.brand : DashColors.w(0.14)),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : DashColors.w(0.7),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final VideoModule module;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<VideoModule> onChanged;
  final VoidCallback onRemove;
  final Future<VideoModule> Function(VideoModule module) onSaveModule;
  final Future<VideoModule> Function(int moduleId) onDownloadSubtitles;
  final Future<VideoModule> Function(int moduleId) onExtractContent;
  const _ModuleCard({
    super.key,
    required this.module,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
    required this.onRemove,
    required this.onSaveModule,
    required this.onDownloadSubtitles,
    required this.onExtractContent,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  late final _title = TextEditingController(text: widget.module.title);
  late final _videoUrl = TextEditingController(text: widget.module.videoUrl);
  Timer? _saveDebounce;
  bool _saving = false;
  bool _downloadingSubtitles = false;
  String? _subtitlesError;
  bool _extractingContent = false;
  String? _extractError;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _title.dispose();
    _videoUrl.dispose();
    super.dispose();
  }

  /// Updates the module locally on every keystroke (so the thumbnail
  /// preview reacts live), then saves ~1s after the user stops typing —
  /// matches "after adding a video URL, show it and save".
  void _pushEdits() {
    final updated = widget.module.copyWith(
      title: _title.text.trim(),
      videoUrl: _videoUrl.text.trim(),
    );
    widget.onChanged(updated);
    _saveDebounce?.cancel();
    if (updated.moduleId == null) return;
    _saveDebounce = Timer(const Duration(milliseconds: 900), () => _save(updated));
  }

  Future<void> _save(VideoModule module) async {
    setState(() => _saving = true);
    try {
      final saved = await widget.onSaveModule(module);
      if (!mounted) return;
      widget.onChanged(saved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// The title/video-URL save is debounced (900ms after the last
  /// keystroke), so a pipeline button clicked right after typing could
  /// otherwise race ahead of that save and run against the server's
  /// stale (often still-empty) video_url. Flush it first.
  Future<void> _flushPendingSave() async {
    if (_saveDebounce == null || !_saveDebounce!.isActive) return;
    _saveDebounce!.cancel();
    await _save(widget.module);
  }

  Future<void> _downloadSubtitles() async {
    final moduleId = widget.module.moduleId;
    if (moduleId == null) return;
    setState(() {
      _downloadingSubtitles = true;
      _subtitlesError = null;
    });
    try {
      await _flushPendingSave();
      final updated = await widget.onDownloadSubtitles(moduleId);
      if (!mounted) return;
      widget.onChanged(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _subtitlesError = apiErrorText(e));
    } finally {
      if (mounted) setState(() => _downloadingSubtitles = false);
    }
  }

  Future<void> _extractContent() async {
    final moduleId = widget.module.moduleId;
    if (moduleId == null) return;
    setState(() {
      _extractingContent = true;
      _extractError = null;
    });
    try {
      await _flushPendingSave();
      final updated = await widget.onExtractContent(moduleId);
      if (!mounted) return;
      widget.onChanged(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _extractError = apiErrorText(e));
    } finally {
      if (mounted) setState(() => _extractingContent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.selected ? DashColors.brand.withValues(alpha: 0.06) : DashColors.w(0.04),
        border: Border.all(color: widget.selected ? DashColors.brand : DashColors.w(0.08)),
        borderRadius: DashRadii.cardSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: CourseField(controller: _title, label: 'Module title', onChanged: _pushEdits)),
              IconButton(
                tooltip: widget.selected ? 'Showing in side pane' : 'Show words & sentences',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  widget.selected ? Icons.visibility : Icons.visibility_outlined,
                  color: widget.selected ? DashColors.brand : DashColors.w(0.5),
                ),
                onPressed: widget.onSelect,
              ),
              IconButton(
                tooltip: 'Remove module',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, color: DashColors.w(0.5)),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 10),
          CourseField(
            controller: _videoUrl,
            label: 'Video URL',
            hint: 'https://www.youtube.com/watch?v=...',
            onChanged: _pushEdits,
          ),
          if (_saving) ...[
            const SizedBox(height: 4),
            Text('Saving…', style: TextStyle(fontSize: 11, color: DashColors.w(0.5))),
          ],
          if (m.videoUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            _VideoCard(video: VideoItem(videoUrl: m.videoUrl)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PipelineButton(
                  label: 'Download subtitles',
                  doneLabel: '${m.subtitles?.length ?? 0} subtitle lines',
                  done: m.subtitles != null,
                  busy: _downloadingSubtitles,
                  enabled: m.moduleId != null,
                  onTap: _downloadSubtitles,
                ),
                _PipelineButton(
                  label: 'Extract content',
                  doneLabel:
                      '${m.words?.length ?? 0} words · ${m.sentences?.length ?? 0} sentences · ${m.phrases?.length ?? 0} phrases',
                  done: m.words != null,
                  busy: _extractingContent,
                  enabled: m.subtitles != null,
                  onTap: _extractContent,
                ),
              ],
            ),
            if (_subtitlesError != null) ...[
              const SizedBox(height: 6),
              SelectableText(_subtitlesError!, style: TextStyle(fontSize: 12, color: DashColors.red400)),
            ],
            if (_extractError != null) ...[
              const SizedBox(height: 6),
              SelectableText(_extractError!, style: TextStyle(fontSize: 12, color: DashColors.red400)),
            ],
          ],
        ],
      ),
    );
  }
}
