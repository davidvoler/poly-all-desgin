import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/navigation_rail_panel.dart';
import '../data/course.dart';
import '../data/courses_repository.dart';
import '../widgets/create_course_dialog.dart';
import 'course_authoring_page.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  Future<void> _createCourse() async {
    final course = await showDialog<Course>(
      context: context,
      builder: (_) => const CreateCourseDialog(),
    );
    if (!mounted || course == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CourseAuthoringPage(course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const NavigationRailPanel(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 64,
                      vertical: 48,
                    ),
                    child: CoursesContent(onAddCourse: _createCourse),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CoursesContent extends ConsumerWidget {
  const CoursesContent({required this.onAddCourse, super.key});

  final VoidCallback onAddCourse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, David',
                    style: TextStyle(color: Color(0xFF748087), fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your courses',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: Color(0xFF17252D),
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Shape the next way someone learns a language.',
                    style: TextStyle(color: Color(0xFF65747A), fontSize: 15),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onAddCourse,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add course'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2B7771),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            const Text(
              'All courses',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF17252D),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3EAE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${courses.value?.length ?? '–'}',
                style: TextStyle(
                  color: Color(0xFF2B7771),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF748087)),
            const SizedBox(width: 8),
            const Text(
              'Recently edited',
              style: TextStyle(color: Color(0xFF748087), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 16),
        courses.when(
          data: (courses) => courses.isEmpty
              ? const _CoursesMessage(
                  icon: Icons.menu_book_outlined,
                  message: 'No courses yet. Add one to get started.',
                )
              : CourseGrid(courses: courses),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _CoursesMessage(
            icon: Icons.cloud_off_rounded,
            message: 'Could not load courses from the server.',
            detail: '$error',
            onRetry: () => ref.invalidate(coursesProvider),
          ),
        ),
      ],
    );
  }
}

class CourseGrid extends StatelessWidget {
  const CourseGrid({required this.courses, super.key});

  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1050
            ? 3
            : constraints.maxWidth > 650
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (_, index) => CourseCard(course: courses[index]),
        );
      },
    );
  }
}

class _CoursesMessage extends StatelessWidget {
  const _CoursesMessage({
    required this.icon,
    required this.message,
    this.detail,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF8A979A)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF42535A),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8A979A), fontSize: 12),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: course.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        course.monogram,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17252D),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF97A1A4),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17252D),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CourseMeta(label: 'Learning', value: course.learningLanguage),
                  const SizedBox(width: 20),
                  CourseMeta(label: 'Student', value: course.studentLanguage),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EEE8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.level,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF53636A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: Color(0xFF8A979A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${course.lessons} lessons',
                    style: const TextStyle(
                      color: Color(0xFF8A979A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseMeta extends StatelessWidget {
  const CourseMeta({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: .7,
          color: Color(0xFF9AA4A6),
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF42535A),
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
