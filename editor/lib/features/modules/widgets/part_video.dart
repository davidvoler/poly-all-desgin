import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// A small YouTube player showing one part of a video: cued at the part's
/// start, and playing no further than its end.
class PartVideo extends StatefulWidget {
  const PartVideo({
    required this.videoUrl,
    required this.start,
    this.end,
    super.key,
  });

  final String videoUrl;

  /// Where the part starts and ends in the video, in seconds.
  final double start;
  final double? end;

  /// The YouTube id in [url], or null when it is not a YouTube link.
  static String? videoId(String url) =>
      YoutubePlayerController.convertUrlToId(url);

  @override
  State<PartVideo> createState() => _PartVideoState();
}

class _PartVideoState extends State<PartVideo> {
  late final String videoId = PartVideo.videoId(widget.videoUrl)!;
  late final controller = YoutubePlayerController.fromVideoId(
    videoId: videoId,
    startSeconds: widget.start,
    endSeconds: widget.end,
    params: const YoutubePlayerParams(
      showFullscreenButton: true,
      strictRelatedVideos: true,
    ),
  );

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  /// Plays the part from its start, stopping at its end.
  void _playPart() => controller.loadVideoById(
    videoId: videoId,
    startSeconds: widget.start,
    endSeconds: widget.end,
  );

  static String _clock(double seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).floor().toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final end = widget.end;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: YoutubePlayer(controller: controller),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: _playPart,
          icon: const Icon(Icons.play_arrow_rounded, size: 19),
          label: Text(
            end == null
                ? 'Play part from ${_clock(widget.start)}'
                : 'Play part ${_clock(widget.start)}-${_clock(end)}',
          ),
        ),
      ],
    );
  }
}
