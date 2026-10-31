import 'package:flutter/material.dart';

import '../features/chat/pages/chat_page.dart';

class CourseEditorApp extends StatelessWidget {
  const CourseEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumen Course Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F1EA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B7771)),
        fontFamily: 'Arial',
      ),
      home: const ChatPage(),
    );
  }
}
