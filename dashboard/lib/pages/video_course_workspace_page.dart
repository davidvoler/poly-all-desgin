import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
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

enum _Tab { preview, edit, modules }

class _VideoCourseWorkspacePageState extends ConsumerState<VideoCourseWorkspacePage> {
  bool _loading = true;
  String? _loadError;
  VideoCourse? _course;
  _Tab _tab = _Tab.preview;

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
        _loadError = _errorText(e);
      });
    }
  }

  String _errorText(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final detail = data is Map ? (data['detail'] ?? data['error'] ?? data['message']) : null;
      final where = e.requestOptions.uri.path;
      final parts = [
        if (code != null) 'HTTP $code',
        if (detail != null) '$detail' else e.type.name,
        where,
      ];
      return parts.join(' · ');
    }
    return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
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
            child: Text('Could not load video course — ${_loadError ?? 'not found'}',
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
                  _TabButton(label: 'Preview', active: _tab == _Tab.preview, onTap: () => setState(() => _tab = _Tab.preview)),
                  _TabButton(label: 'Edit', active: _tab == _Tab.edit, onTap: () => setState(() => _tab = _Tab.edit)),
                  _TabButton(label: 'Video Modules', active: _tab == _Tab.modules, onTap: () => setState(() => _tab = _Tab.modules)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: DashColors.w(0.06),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: SingleChildScrollView(
                      child: switch (_tab) {
                        _Tab.preview => _PreviewTab(course: c),
                        _Tab.edit =>
                          _EditTab(course: c, onSaved: (updated) => setState(() => _course = updated)),
                        _Tab.modules => _ModulesTab(
                            course: c, onSaved: (updated) => setState(() => _course = updated)),
                      },
                    ),
                  ),
                ),
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
      setState(() => _error = '$e');
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
          Text(_addVideoError!, style: TextStyle(fontSize: 12, color: DashColors.red400)),
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
          Text('Could not save — $_error', style: TextStyle(fontSize: 12, color: DashColors.red400)),
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
      setState(() => _error = '$e');
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
            Text(_error!, style: TextStyle(fontSize: 12, color: DashColors.red400)),
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

String _newLocalId() => DateTime.now().microsecondsSinceEpoch.toString();

// ===========================================================================
// Video Modules — a module is a single video. Mirrors server VideoModule,
// persisted the same way as everything else in the Edit tab (stage
// locally, one updateVideoCourse call on Save).
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
  bool _saving = false;
  String? _error;

  void _addModule() {
    setState(() => _modules = [
          ..._modules,
          VideoModule(moduleId: _newLocalId(), title: 'Module ${_modules.length + 1}'),
        ]);
  }

  void _removeModule(int i) {
    setState(() => _modules = [..._modules]..removeAt(i));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = widget.course.copyWith(modules: _modules);
      final saved = await ref.read(dashboardApiProvider).updateVideoCourse(updated);
      if (!mounted) return;
      widget.onSaved(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<VideoCourse> _downloadModuleSubtitles(String moduleId) =>
      ref.read(dashboardApiProvider).downloadModuleSubtitles(widget.course.courseId, moduleId);

  @override
  Widget build(BuildContext context) {
    return Column(
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
            onChanged: (updated) => setState(() {
              _modules = [..._modules];
              _modules[i] = updated;
            }),
            onRemove: () => _removeModule(i),
            onSaveModule: _save,
            onDownloadSubtitles: _downloadModuleSubtitles,
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: GhostButton(label: 'Add module', leading: Icons.add, onTap: _addModule),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text('Could not save — $_error', style: TextStyle(fontSize: 12, color: DashColors.red400)),
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

class _ModuleCard extends StatefulWidget {
  final VideoModule module;
  final ValueChanged<VideoModule> onChanged;
  final VoidCallback onRemove;
  final Future<void> Function() onSaveModule;
  final Future<VideoCourse> Function(String moduleId) onDownloadSubtitles;
  const _ModuleCard({
    super.key,
    required this.module,
    required this.onChanged,
    required this.onRemove,
    required this.onSaveModule,
    required this.onDownloadSubtitles,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  late final _title = TextEditingController(text: widget.module.title);
  late final _videoUrl = TextEditingController(text: widget.module.videoUrl);
  Timer? _videoUrlDebounce;
  bool _savingVideoUrl = false;
  bool _downloadingSubtitles = false;
  String? _subtitlesError;

  @override
  void dispose() {
    _videoUrlDebounce?.cancel();
    _title.dispose();
    _videoUrl.dispose();
    super.dispose();
  }

  void _pushTitle() => widget.onChanged(widget.module.copyWith(title: _title.text.trim()));

  /// Updates the module locally on every keystroke (so the thumbnail
  /// preview reacts live), then saves the module ~1s after the user stops
  /// typing — matches "after adding a video URL, show it and save".
  void _pushVideoUrl() {
    widget.onChanged(widget.module.copyWith(videoUrl: _videoUrl.text.trim()));
    _videoUrlDebounce?.cancel();
    final url = _videoUrl.text.trim();
    if (url.isEmpty) return;
    _videoUrlDebounce = Timer(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      setState(() => _savingVideoUrl = true);
      try {
        await widget.onSaveModule();
      } finally {
        if (mounted) setState(() => _savingVideoUrl = false);
      }
    });
  }

  Future<void> _downloadSubtitles() async {
    setState(() {
      _downloadingSubtitles = true;
      _subtitlesError = null;
    });
    try {
      final updated = await widget.onDownloadSubtitles(widget.module.moduleId);
      final match = updated.modules.firstWhere(
        (m) => m.moduleId == widget.module.moduleId,
        orElse: () => widget.module,
      );
      if (!mounted) return;
      widget.onChanged(match);
    } catch (e) {
      if (!mounted) return;
      setState(() => _subtitlesError = '$e');
    } finally {
      if (mounted) setState(() => _downloadingSubtitles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(child: CourseField(controller: _title, label: 'Module title', onChanged: _pushTitle)),
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
            onChanged: _pushVideoUrl,
          ),
          if (_savingVideoUrl) ...[
            const SizedBox(height: 4),
            Text('Saving…', style: TextStyle(fontSize: 11, color: DashColors.w(0.5))),
          ],
          if (m.videoUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            _VideoCard(video: VideoItem(videoUrl: m.videoUrl)),
            const SizedBox(height: 10),
            _PipelineButton(
              label: 'Download subtitles',
              doneLabel: '${m.subtitles?.length ?? 0} subtitle lines',
              done: m.subtitles != null,
              busy: _downloadingSubtitles,
              onTap: _downloadSubtitles,
            ),
            if (_subtitlesError != null) ...[
              const SizedBox(height: 6),
              Text(_subtitlesError!, style: TextStyle(fontSize: 12, color: DashColors.red400)),
            ],
          ],
        ],
      ),
    );
  }
}
