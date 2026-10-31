import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/navigation_rail_panel.dart';
import '../../courses/data/course.dart';
import '../../courses/data/courses_repository.dart';
import '../../courses/pages/course_authoring_page.dart';
import '../../courses/widgets/create_course_dialog.dart';
import '../data/prompt_router_responder.dart';
import '../widgets/chat_panel.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  Course? selected;

  /// Asks for the course details, saves the course and switches the chat
  /// to it.
  Future<void> _createCourse() async {
    final draft = await showDialog<Course>(
      context: context,
      builder: (_) => const CreateCourseDialog(),
    );
    if (!mounted || draft == null) return;
    try {
      final created = await ref
          .read(coursesRepositoryProvider)
          .createCourse(draft);
      if (!mounted) return;
      setState(() => selected = created);
      ref.invalidate(coursesProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create the course.\n$error')),
      );
    }
  }

  /// The selected course as it appears in [courses], or the first course.
  /// Matches by id too, since reloading the list builds new instances.
  Course _current(List<Course> courses) {
    final selected = this.selected;
    return courses.firstWhere(
      (course) =>
          course == selected ||
          (selected?.id != null && course.id == selected?.id),
      orElse: () => courses.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    return Scaffold(
      body: Row(
        children: [
          const NavigationRailPanel(selected: NavSection.chat),
          Expanded(
            child: courses.when(
              data: (courses) => courses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No courses yet.'),
                          const SizedBox(height: 16),
                          _buildNewCourseButton(),
                        ],
                      ),
                    )
                  : _buildChat(courses, _current(courses)),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load courses from the server.\n$error'),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(coursesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChat(List<Course> courses, Course course) {
    return Column(
      children: [
        _buildHeader(courses, course),
        Expanded(
          child: Row(
            children: [
              Expanded(
                // A new course starts a new conversation.
                child: ChatPanel(
                  key: ObjectKey(course),
                  responder: ref.watch(responderFactoryProvider)(course),
                ),
              ),
              const VerticalDivider(width: 1, color: Color(0xFFE4E0D9)),
              Expanded(child: CourseDataPane(course: course)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(List<Course> courses, Course course) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 42),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E0D9))),
      ),
      child: Row(
        children: [
          const Text(
            'Chat',
            style: TextStyle(
              color: Color(0xFF17252D),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const Text(
            'Course',
            style: TextStyle(color: Color(0xFF8A979A), fontSize: 13),
          ),
          const SizedBox(width: 12),
          DropdownButton<Course>(
            value: course,
            underline: const SizedBox.shrink(),
            items: courses
                .map(
                  (course) => DropdownMenuItem(
                    value: course,
                    child: Text(course.title),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => selected = value),
          ),
          const SizedBox(width: 16),
          _buildNewCourseButton(),
        ],
      ),
    );
  }

  Widget _buildNewCourseButton() => FilledButton.icon(
    onPressed: _createCourse,
    icon: const Icon(Icons.add_rounded, size: 19),
    label: const Text('New course'),
  );
}
