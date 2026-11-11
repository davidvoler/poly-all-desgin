import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth.dart';
import '../features/auth/pages/login_page.dart';
import '../features/chat/pages/chat_page.dart';

class CourseEditorApp extends StatelessWidget {
  const CourseEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polyglots Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F1EA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B7771)),
        fontFamily: 'Arial',
      ),
      // Any text, such as an error, can be selected and copied.
      builder: (context, child) => _SelectableText(child: child!),
      home: const _AuthGate(),
    );
  }
}

/// Wraps the app in a [SelectionArea], with the [Overlay] it needs for its
/// selection handles and copy menu.
class _SelectableText extends StatefulWidget {
  const _SelectableText({required this.child});

  final Widget child;

  @override
  State<_SelectableText> createState() => _SelectableTextState();
}

class _SelectableTextState extends State<_SelectableText> {
  late final entry = OverlayEntry(
    builder: (_) => SelectionArea(child: widget.child),
  );

  @override
  void didUpdateWidget(_SelectableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    entry.markNeedsBuild();
  }

  @override
  void dispose() {
    entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [entry]);
}

/// The chat once signed in, else the login page. Shows nothing while the
/// session is being restored, so the login does not flash on reload.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(authProvider)) {
      AuthRestoring() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthSignedIn() => const ChatPage(),
      _ => const LoginPage(),
    };
  }
}
