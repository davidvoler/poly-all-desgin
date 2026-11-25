import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../api/courses_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'quiz_page.dart';

/// The steps of a video lesson, in order. A lesson is one part of the
/// module's video: the student learns its words, watches it, then
/// practises its sentences. Playing it again and a mixed quiz are extras.
enum _Step { words, video, sentences, done }

/// A video lesson. Route argument: the lesson id. The lesson (its video
/// link and part times) comes from the current module's lessons.
class VideoLessonPage extends ConsumerStatefulWidget {
  const VideoLessonPage({super.key});

  @override
  ConsumerState<VideoLessonPage> createState() => _VideoLessonPageState();
}

class _VideoLessonPageState extends ConsumerState<VideoLessonPage> {
  _Step _step = _Step.words;

  // Rounds already started from this page, so returning from the words
  // quiz goes on to the video instead of opening the quiz again.
  bool _wordsStarted = false;

  /// Runs one quiz round; true when the student finished it.
  Future<bool> _quiz(int lessonId, VideoQuizKind kind) async {
    final finished = await Navigator.pushNamed<bool>(
      context,
      '/quiz',
      arguments: VideoQuizArgs(lessonId, kind),
    );
    return finished ?? false;
  }

  Future<void> _startWords(int lessonId, bool hasWords) async {
    _wordsStarted = true;
    if (hasWords) await _quiz(lessonId, VideoQuizKind.words);
    // Skipping or closing the words quiz still leads to the video.
    if (mounted) setState(() => _step = _Step.video);
  }

  Future<void> _startSentences(int lessonId, bool hasSentences) async {
    setState(() => _step = _Step.sentences);
    final finished =
        !hasSentences || await _quiz(lessonId, VideoQuizKind.sentences);
    if (!mounted) return;
    if (finished) {
      // The lessons list shows the new score and the next lesson.
      final moduleId = ref.read(preferenceProvider).value?.moduleId;
      if (moduleId != null) ref.invalidate(lessonsProvider(moduleId));
    }
    // Closing the sentences quiz goes back to the video.
    setState(() => _step = finished ? _Step.done : _Step.video);
  }

  @override
  Widget build(BuildContext context) {
    final lessonId = ModalRoute.of(context)?.settings.arguments as int?;
    final moduleId = ref.watch(
      preferenceProvider.select((p) => p.value?.moduleId),
    );
    final lessons = moduleId == null
        ? const <Lesson>[]
        : (ref.watch(lessonsProvider(moduleId)).value ?? const <Lesson>[]);
    final i = lessons.indexWhere((l) => l.id == lessonId);
    final lesson = i == -1 ? null : lessons[i];
    final next = (i != -1 && i + 1 < lessons.length) ? lessons[i + 1] : null;
    final exercises = lessonId == null
        ? null
        : ref.watch(videoExercisesProvider(lessonId)).value;

    final Widget body;
    if (lesson == null || exercises == null || lessonId == null) {
      body = const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else {
      final hasWords = exercises.any((e) => e.isWord);
      final hasSentences = exercises.any((e) => !e.isWord);
      // Opening the lesson starts with its words, once.
      if (_step == _Step.words && !_wordsStarted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _startWords(lessonId, hasWords),
        );
      }
      body = _buildStep(lesson, next, hasSentences);
    }

    return Scaffold(
      body: PhoneBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TopBar(
                  leading: RoundIconButton(
                    icon: Icons.close,
                    tooltip: 'Close',
                    onTap: () => Navigator.maybePop(context),
                  ),
                  title: TitleBlock(
                    overline: 'VIDEO LESSON',
                    title: lesson?.title.isNotEmpty == true
                        ? lesson!.title
                        : 'Lesson',
                  ),
                ),
                _StepStrip(step: _step),
                const SizedBox(height: 18),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(Lesson lesson, Lesson? next, bool hasSentences) {
    switch (_step) {
      // The quiz rounds run on top of this page.
      case _Step.words:
      case _Step.sentences:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      case _Step.video:
        return _VideoStep(
          lesson: lesson,
          footer: CtaButton(
            label: hasSentences ? 'Practise the sentences' : 'Finish',
            trailingIcon: Icons.arrow_forward,
            onTap: () => _startSentences(lesson.id, hasSentences),
          ),
        );
      case _Step.done:
        return _VideoStep(
          lesson: lesson,
          heading: 'Part completed',
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CtaButton(
                label: next == null
                    ? 'Back to course'
                    : 'Continue to ${next.title.isNotEmpty ? next.title : 'the next lesson'}',
                trailingIcon: Icons.arrow_forward,
                onTap: () => _continue(next),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ExtraButton(
                      icon: Icons.shuffle,
                      label: VideoQuizKind.mixed.label,
                      onTap: () => _quiz(lesson.id, VideoQuizKind.mixed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  void _continue(Lesson? next) {
    if (next == null) {
      Navigator.maybePop(context);
      return;
    }
    ref
        .read(preferenceProvider.notifier)
        .save(
          lessonId: next.id,
          lessonName: next.title.isNotEmpty ? next.title : null,
        );
    Navigator.pushReplacementNamed(
      context,
      next.isVideo ? '/video_lesson' : '/quiz',
      arguments: next.id,
    );
  }
}

/// Words → Video → Sentences, with the current step highlighted.
class _StepStrip extends StatelessWidget {
  final _Step step;
  const _StepStrip({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Words', 'Video', 'Sentences'];
    return Row(
      children: [
        for (var k = 0; k < labels.length; k++) ...[
          if (k > 0)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          _StepDot(
            label: labels[k],
            done: step.index > k,
            current: step.index == k,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool current;
  const _StepDot({
    required this.label,
    required this.done,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final strong = done || current;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: Colors.white.withValues(alpha: strong ? 1 : 0.45),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white.withValues(alpha: strong ? 1 : 0.55),
          ),
        ),
      ],
    );
  }
}

/// The lesson's part of the video, with a button to play it (again) and
/// the step's own actions below.
class _VideoStep extends StatefulWidget {
  final Lesson lesson;
  final String? heading;
  final Widget footer;
  const _VideoStep({required this.lesson, this.heading, required this.footer});

  @override
  State<_VideoStep> createState() => _VideoStepState();
}

class _VideoStepState extends State<_VideoStep> {
  late final String? _videoId = YoutubePlayerController.convertUrlToId(
    widget.lesson.videoUrl ?? '',
  );
  late final YoutubePlayerController? _controller = _videoId == null
      ? null
      : YoutubePlayerController.fromVideoId(
          videoId: _videoId,
          autoPlay: true,
          startSeconds: widget.lesson.videoStart ?? 0,
          endSeconds: widget.lesson.videoEnd,
          params: const YoutubePlayerParams(
            showFullscreenButton: true,
            strictRelatedVideos: true,
          ),
        );

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  /// Plays the part from its start, stopping at its end.
  void _playAgain() => _controller?.loadVideoById(
    videoId: _videoId!,
    startSeconds: widget.lesson.videoStart ?? 0,
    endSeconds: widget.lesson.videoEnd,
  );

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.heading != null) ...[
          Text(
            widget.heading!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller == null)
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      "This lesson's video can't be played.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: PolyRadii.card,
                    child: YoutubePlayer(controller: controller),
                  ),
                const SizedBox(height: 12),
                if (controller != null)
                  Center(
                    child: _ExtraButton(
                      icon: Icons.replay,
                      label: 'Play again',
                      onTap: _playAgain,
                    ),
                  ),
                if (widget.lesson.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      widget.lesson.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        widget.footer,
      ],
    );
  }
}

/// Secondary glass pill for the extras (play again, mixed quiz).
class _ExtraButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ExtraButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
