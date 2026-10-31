import 'dart:math';

import 'package:flutter/material.dart';

import '../data/module.dart';
import 'part_video.dart';

/// Plays a lesson the way a student meets it: the video part (if any),
/// then its exercises one at a time, checked as they are answered, and a
/// score at the end.
class LessonPreview extends StatefulWidget {
  const LessonPreview({required this.lesson, this.videoUrl = '', super.key});

  final Lesson lesson;

  /// The module's video, for a lesson that is a video part.
  final String videoUrl;

  @override
  State<LessonPreview> createState() => _LessonPreviewState();
}

class _LessonPreviewState extends State<LessonPreview> {
  int index = 0;
  int correctCount = 0;

  /// Options picked for the current exercise.
  final selected = <String>{};

  /// Whether the current exercise has been checked.
  bool checked = false;

  List<Exercise> get exercises => widget.lesson.exercises;

  /// Exercises the student answers, as opposed to explanations they read.
  int get answerable => exercises.where((e) => e.type != 'explanation').length;

  static const _green = Color(0xFF2B7771);
  static const _red = Color(0xFFC0503C);

  /// The options to choose from, shuffled the same way each time.
  List<String> _options(Exercise exercise) {
    if (exercise.type == 'true_false') return const ['True', 'False'];
    final options = [...exercise.correctOptions, ...exercise.incorrectOptions];
    return options..shuffle(Random(exercise.id ?? index));
  }

  bool _isCorrect(Exercise exercise, String option) =>
      exercise.type == 'true_false'
      ? option.toLowerCase() == exercise.answer.toLowerCase()
      : exercise.correctOptions.contains(option);

  /// Single-answer types check as soon as an option is tapped.
  void _tap(Exercise exercise, String option) {
    if (checked) return;
    setState(() {
      if (exercise.type == 'multiple_choice') {
        selected.contains(option)
            ? selected.remove(option)
            : selected.add(option);
      } else {
        selected
          ..clear()
          ..add(option);
        _check(exercise);
      }
    });
  }

  void _check(Exercise exercise) {
    final correct = _options(
      exercise,
    ).where((o) => _isCorrect(exercise, o)).toSet();
    checked = true;
    if (selected.length == correct.length && selected.every(correct.contains)) {
      correctCount++;
    }
  }

  void _next() => setState(() {
    index++;
    selected.clear();
    checked = false;
  });

  void _restart() => setState(() {
    index = 0;
    correctCount = 0;
    selected.clear();
    checked = false;
  });

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final start = lesson.videoStart;
    final hasVideo =
        start != null && PartVideo.videoId(widget.videoUrl) != null;
    return ListView(
      children: [
        if (hasVideo) ...[
          PartVideo(
            key: ValueKey(lesson.id),
            videoUrl: widget.videoUrl,
            start: start,
            end: lesson.videoEnd,
          ),
          const SizedBox(height: 16),
        ],
        if (exercises.isEmpty)
          const Text(
            'This lesson has no exercises to preview yet.',
            style: TextStyle(color: Color(0xFF748087), fontSize: 14),
          )
        else if (index >= exercises.length)
          _buildSummary()
        else
          _buildExercise(exercises[index]),
      ],
    );
  }

  Widget _buildSummary() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        const Icon(Icons.flag_rounded, color: _green, size: 32),
        const SizedBox(height: 10),
        Text(
          answerable == 0
              ? 'Lesson complete'
              : '$correctCount of $answerable correct',
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17252D),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _restart,
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: const Text('Start again'),
        ),
      ],
    ),
  );

  Widget _buildExercise(Exercise exercise) {
    final isExplanation = exercise.type == 'explanation';
    final options = isExplanation ? const <String>[] : _options(exercise);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress through the lesson.
        Row(
          children: [
            Text(
              '${index + 1} / ${exercises.length}',
              style: const TextStyle(color: Color(0xFF748087), fontSize: 13),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: index / exercises.length,
                  minHeight: 6,
                  color: _green,
                  backgroundColor: const Color(0xFFE4E0D9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                switch (exercise.type) {
                  'true_false' => 'True or false?',
                  'fill_in_the_blank' => 'Fill in the blank',
                  'multiple_choice' => 'Choose every correct answer',
                  'explanation' => 'Read',
                  _ => 'Choose the correct answer',
                }.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF9AA4A6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isExplanation ? exercise.explanation : exercise.question,
                style: TextStyle(
                  color: const Color(0xFF17252D),
                  fontSize: isExplanation ? 15 : 18,
                  fontWeight: isExplanation ? FontWeight.w400 : FontWeight.w600,
                  height: 1.45,
                ),
              ),
              if (options.isNotEmpty) const SizedBox(height: 16),
              for (final option in options) _buildOption(exercise, option),
              if (exercise.type == 'multiple_choice' && !checked)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => setState(() => _check(exercise)),
                    child: const Text('Check'),
                  ),
                ),
              if (checked && !isExplanation) ..._buildFeedback(exercise),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (checked || isExplanation)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                index == exercises.length - 1 ? 'Finish' : 'Continue',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOption(Exercise exercise, String option) {
    final isSelected = selected.contains(option);
    final isCorrect = _isCorrect(exercise, option);
    // After checking: correct options green, wrong picks red.
    final color = !checked
        ? (isSelected ? _green : const Color(0xFFE4E0D9))
        : isCorrect
        ? _green
        : isSelected
        ? _red
        : const Color(0xFFE4E0D9);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _tap(exercise, option),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: checked && (isCorrect || isSelected)
                ? color.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: const TextStyle(
                    color: Color(0xFF17252D),
                    fontSize: 15,
                  ),
                ),
              ),
              if (checked && isCorrect)
                const Icon(Icons.check_circle_rounded, color: _green, size: 20)
              else if (checked && isSelected)
                const Icon(Icons.cancel_rounded, color: _red, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeedback(Exercise exercise) {
    final right = _options(exercise).where((o) => _isCorrect(exercise, o));
    final gotIt =
        selected.length == right.length && selected.every(right.contains);
    return [
      const SizedBox(height: 6),
      Text(
        gotIt ? 'Correct!' : 'Not quite.',
        style: TextStyle(
          color: gotIt ? _green : _red,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (exercise.translation.isNotEmpty &&
          !exercise.correctOptions.contains(exercise.translation)) ...[
        const SizedBox(height: 6),
        Text(
          exercise.translation,
          style: const TextStyle(color: Color(0xFF748087), fontSize: 14),
        ),
      ],
      if (exercise.explanation.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          exercise.explanation,
          style: const TextStyle(color: Color(0xFF748087), fontSize: 14),
        ),
      ],
    ];
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE4E0D9)),
  );
}
