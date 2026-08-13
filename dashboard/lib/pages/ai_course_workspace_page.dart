import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/ai_prompt_controls.dart';
import '../widgets/common.dart';
import 'ai_courses_page.dart' show flagFor, kAiLevels;

/// The Create-with-AI course workspace — a Flutter port of
/// plan/design_experiments/create_with_ai_poc/course.html. Full-bleed, own
/// Scaffold (like login_page.dart / create_school_page.dart) rather than
/// DashboardShell: once inside a course we don't need the sidebar, we need
/// the whole page (see TASKS.md).
///
/// Chat messages are UI-only (not persisted server-side — there's no chat
/// log table) and reset each visit; the actual course state (words,
/// modules, lessons, sentences, exercises) is 100% server-backed via
/// GET .../full and re-fetched after every mutation, which is what
/// "continue where you left off" actually relies on.
class AiCourseWorkspacePage extends ConsumerStatefulWidget {
  final int courseId;
  const AiCourseWorkspacePage({super.key, required this.courseId});

  @override
  ConsumerState<AiCourseWorkspacePage> createState() => _AiCourseWorkspacePageState();
}

enum _Tab { words, lessons, edit, preview }

class _ChatAction {
  final String id;
  final String label;
  final int? lessonId;
  final bool newModule;
  const _ChatAction(this.id, this.label, {this.lessonId, this.newModule = false});
}

class _PickerItem {
  final int id;
  final String label;
  final String sub;
  final bool used;
  bool checked;
  _PickerItem({required this.id, required this.label, this.sub = '', this.used = false, this.checked = false});
}

class _Picker {
  final String kind; // 'words' | 'sentences'
  final int lessonId;
  final List<_PickerItem> items;
  final String confirmLabel;
  bool answered = false;
  _Picker({required this.kind, required this.lessonId, required this.items, required this.confirmLabel});
}

class _ChatMsg {
  final bool isUser;
  final String text;
  final List<_ChatAction>? actions;
  final _Picker? picker;
  final AiUsage? usage;
  _ChatMsg({required this.isUser, required this.text, this.actions, this.picker, this.usage});
}

class _AiCourseWorkspacePageState extends ConsumerState<AiCourseWorkspacePage> {
  bool _loading = true;
  String? _loadError;
  AiCourseFull? _course;
  EditorCourse? _editorCourse;

  _Tab _tab = _Tab.words;
  final List<_ChatMsg> _chat = [];
  bool _thinking = false;
  final _chatScroll = ScrollController();
  final _chatText = TextEditingController();

  int _sessionTokens = 0;
  double _sessionCost = 0;
  final Set<int> _editingSentenceIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _chatScroll.dispose();
    _chatText.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final api = ref.read(dashboardApiProvider);
      final results = await Future.wait([
        api.fetchAiCourseFull(widget.courseId),
        api.fetchCourseById(widget.courseId),
      ]);
      if (!mounted) return;
      setState(() {
        _course = results[0] as AiCourseFull;
        _editorCourse = results[1] as EditorCourse;
        _loading = false;
      });
      if (_chat.isEmpty) _seedChat();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '$e';
      });
    }
  }

  Future<void> _reload() async {
    final api = ref.read(dashboardApiProvider);
    final results = await Future.wait([
      api.fetchAiCourseFull(widget.courseId),
      api.fetchCourseById(widget.courseId),
    ]);
    if (!mounted) return;
    setState(() {
      _course = results[0] as AiCourseFull;
      _editorCourse = results[1] as EditorCourse;
    });
  }

  void _seedChat() {
    final c = _course!;
    if (c.words.isEmpty) {
      _chat.add(_ChatMsg(
        isUser: false,
        text: "Course '${c.title}' — ${c.lang} → ${c.toLang}, level ${c.level}. Let's start with a word list.",
        actions: const [_ChatAction('create_words', 'Create word list')],
      ));
      return;
    }
    final actions = <_ChatAction>[
      _ChatAction('new_lesson', 'Select words for Lesson ${_lessonCount(c) + 1}'),
      const _ChatAction('create_words', 'Add more words'),
    ];
    if (c.modules.isNotEmpty) {
      actions.add(const _ChatAction('new_lesson', 'Start a new module', newModule: true));
    }
    _chat.add(_ChatMsg(
      isUser: false,
      text: "Welcome back to '${c.title}'. Ready to keep building?",
      actions: actions,
    ));
  }

  int _lessonCount(AiCourseFull c) => c.modules.fold(0, (n, m) => n + m.lessons.length);

  AiLesson? get _currentLesson {
    final c = _course;
    if (c == null) return null;
    final all = [for (final m in c.modules) ...m.lessons];
    return all.isEmpty ? null : all.last;
  }

  Set<String> get _usedWords {
    final c = _course;
    if (c == null) return {};
    return {for (final w in c.words) if (w.used) w.word};
  }

  // -------------------------------------------------------------------
  // Chat plumbing
  // -------------------------------------------------------------------
  void _appendUser(String text) {
    setState(() => _chat.add(_ChatMsg(isUser: true, text: text)));
    _scrollChatToEnd();
  }

  void _appendAssistant(String text, {List<_ChatAction>? actions, _Picker? picker, AiUsage? usage}) {
    setState(() => _chat.add(_ChatMsg(isUser: false, text: text, actions: actions, picker: picker, usage: usage)));
    if (usage != null) {
      _sessionTokens += usage.tokens;
      _sessionCost += usage.cost;
    }
    _scrollChatToEnd();
  }

  void _scrollChatToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScroll.hasClients) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _thinkThen(Future<void> Function() cb) async {
    setState(() => _thinking = true);
    try {
      await cb();
    } catch (e) {
      _appendAssistant('Something went wrong — $e');
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  // -------------------------------------------------------------------
  // The chat "state machine" — mirrors assets/app.js in the HTML POC,
  // calling the real backend instead of the mock generators.
  // -------------------------------------------------------------------
  Future<void> _handleAction(_ChatAction action) async {
    switch (action.id) {
      case 'create_words':
        await _doCreateWords();
        break;
      case 'new_lesson':
        await _doNewLesson(action.newModule);
        break;
      case 'create_sentences':
        await _doCreateSentences(action.lessonId!);
        break;
      case 'create_exercises_direct':
        await _doCreateExercisesDirect(action.lessonId!);
        break;
      case 'preview_course':
        setState(() => _tab = _Tab.preview);
        _appendAssistant("Here's what students will see. Switch back anytime using the tabs on the right.");
        break;
    }
  }

  Future<void> _doCreateWords() async {
    final hadWords = _course!.words.isNotEmpty;
    _appendUser(hadWords ? 'Add more words' : 'Create word list');
    await _thinkThen(() async {
      final api = ref.read(dashboardApiProvider);
      final result = await api.generateAiWords(courseId: widget.courseId, count: 12);
      await _reload();
      if (result.words.isEmpty) {
        _appendAssistant(
          "That's every word I've got for this language right now — try selecting words for a lesson instead.",
          actions: [_ChatAction('new_lesson', 'Select words for Lesson ${_lessonCount(_course!) + 1}')],
        );
        return;
      }
      final actions = <_ChatAction>[
        _ChatAction('new_lesson', 'Select words for Lesson ${_lessonCount(_course!) + 1}'),
        const _ChatAction('create_words', 'Add more words'),
      ];
      if (_course!.modules.isNotEmpty) {
        actions.add(const _ChatAction('new_lesson', 'Start a new module', newModule: true));
      }
      _appendAssistant(
        'Generated ${result.words.length} starter words (${_course!.words.length} total). Review them in the Words tab, then build a lesson.',
        actions: actions,
        usage: result.usage,
      );
    });
  }

  Future<void> _doNewLesson(bool newModule) async {
    if (_course!.words.isEmpty) {
      _appendUser(newModule ? 'Start a new module' : 'Select words for a new lesson');
      await _thinkThen(() async {
        _appendAssistant(
          "There's no word bank yet — let's create one first, then I can help you pick words for it.",
          actions: const [_ChatAction('create_words', 'Create word list')],
        );
      });
      return;
    }
    final n = _lessonCount(_course!) + 1;
    _appendUser('Select words for Lesson $n${newModule ? ' (new module)' : ''}');
    await _thinkThen(() async {
      final api = ref.read(dashboardApiProvider);
      int moduleId;
      String moduleTitle;
      if (newModule || _course!.modules.isEmpty) {
        final mod = await api.createAiModule(courseId: widget.courseId, title: 'Module ${_course!.modules.length + 1}');
        moduleId = mod.moduleId;
        moduleTitle = mod.title;
      } else {
        final mod = _course!.modules.last;
        moduleId = mod.moduleId;
        moduleTitle = mod.title;
      }
      final lesson = await api.createAiLesson(courseId: widget.courseId, moduleId: moduleId, title: 'Lesson $n');
      await _reload();

      final used = _usedWords;
      final ordered = _course!.words.toList()..sort((a, b) => (used.contains(a.word) ? 1 : 0).compareTo(used.contains(b.word) ? 1 : 0));
      var uncheckedSoFar = 0;
      // id is unused for word pickers — _confirmWords reads `label` (the
      // word string itself) since words aren't a database entity.
      final items = ordered.map((w) {
        final isUsed = used.contains(w.word);
        final checked = !isUsed && uncheckedSoFar < 6;
        if (checked) uncheckedSoFar++;
        return _PickerItem(id: w.word.hashCode, label: w.word, sub: isUsed ? '${w.gloss} · used' : w.gloss, used: isUsed, checked: checked);
      }).toList();

      _appendAssistant(
        'Pick the words for Lesson $n in $moduleTitle — pre-selected the next unused ones.',
        picker: _Picker(kind: 'words', lessonId: lesson.lessonId, items: items, confirmLabel: 'Confirm selection'),
      );
    });
  }

  Future<void> _confirmWords(_Picker picker) async {
    // `label` holds the word string itself for word-kind pickers (set in
    // _doNewLesson below) — lesson.words is a plain text[] server-side,
    // not a course_word_id join.
    final selected = [for (final it in picker.items) if (it.checked) it.label];
    setState(() => picker.answered = true);
    _appendUser('Confirmed ${selected.length} word${selected.length == 1 ? '' : 's'}');
    await _thinkThen(() async {
      final api = ref.read(dashboardApiProvider);
      await api.setAiLessonWords(lessonId: picker.lessonId, words: selected);
      await _reload();
      _appendAssistant(
        'Locked in ${selected.length} words. Want me to draft example sentences for them, or jump straight to exercises?',
        actions: [
          _ChatAction('create_sentences', 'Create sentences', lessonId: picker.lessonId),
          _ChatAction('create_exercises_direct', 'Create exercises directly', lessonId: picker.lessonId),
        ],
      );
    });
  }

  Future<void> _doCreateSentences(int lessonId) async {
    _appendUser('Create sentences');
    await _thinkThen(() async {
      final api = ref.read(dashboardApiProvider);
      final result = await api.generateAiSentences(lessonId);
      await _reload();
      final items = result.sentences
          .map((s) => _PickerItem(id: s.sentenceId, label: s.text, sub: s.gloss, checked: true))
          .toList();
      _appendAssistant(
        "Here are draft sentences. Uncheck any you don't want, then I'll turn the rest into exercises.",
        picker: _Picker(kind: 'sentences', lessonId: lessonId, items: items, confirmLabel: 'Create exercises'),
        usage: result.usage,
      );
    });
  }

  Future<void> _confirmSentences(_Picker picker) async {
    final selected = [for (final it in picker.items) if (it.checked) it.id];
    setState(() => picker.answered = true);
    _appendUser('Kept ${selected.length} sentence${selected.length == 1 ? '' : 's'}');
    await _thinkThen(() async {
      final api = ref.read(dashboardApiProvider);
      await api.confirmAiSentences(lessonId: picker.lessonId, sentenceIds: selected);
      final result = await api.generateAiExercises(picker.lessonId);
      await _reload();
      _appendAssistant(
        'This lesson is ready 🎉 Review it in the Lessons tab, or switch to Preview to see the student view.',
        actions: _nextStepActions(),
        usage: result.usage,
      );
    });
  }

  Future<void> _doCreateExercisesDirect(int lessonId) async {
    _appendUser('Create exercises directly');
    await _thinkThen(() async {
      final api = ref.read(dashboardApiProvider);
      final result = await api.generateAiLessonDirect(lessonId: lessonId);
      await _reload();
      _appendAssistant(
        'Done — drafted sentences and exercises in one go. Check the Lessons tab to review or edit, or preview it.',
        actions: _nextStepActions(),
        usage: result.usage,
      );
    });
  }

  List<_ChatAction> _nextStepActions() => [
        const _ChatAction('preview_course', 'Preview course'),
        _ChatAction('new_lesson', 'Start Lesson ${_lessonCount(_course!) + 1}'),
        const _ChatAction('new_lesson', 'Start a new module', newModule: true),
      ];

  Future<void> _sendFreeText() async {
    final text = _chatText.text.trim();
    if (text.isEmpty) return;
    _chatText.clear();
    _appendUser(text);
    await _thinkThen(() async {
      _appendAssistant(
        "Got it — noted for the next batch. Free-text steering isn't wired to generation yet; use the buttons above.",
      );
    });
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: DashColors.darkBg, body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null || _course == null) {
      return Scaffold(
        backgroundColor: DashColors.darkBg,
        body: Center(
          child: Text('Could not load course — $_loadError', style: TextStyle(color: DashColors.red400)),
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
            _TopBar(title: '${flagFor(c.lang)} ${c.title}'),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 6, child: _buildChatColumn(c)),
                  Container(width: 1, color: DashColors.w(0.08)),
                  SizedBox(width: 420, child: _buildTabsColumn(c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatColumn(AiCourseFull c) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('${c.lang} → ${c.toLang} · Level ${c.level}',
                    style: TextStyle(fontSize: 11, color: DashColors.w(0.55))),
              ),
              if (_sessionTokens > 0)
                Text('≈$_sessionTokens tokens · \$${_sessionCost.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 11, color: DashColors.w(0.55))),
            ],
          ),
        ),
        Divider(height: 1, color: DashColors.w(0.08)),
        Expanded(
          child: ListView.separated(
            controller: _chatScroll,
            padding: const EdgeInsets.all(20),
            itemCount: _chat.length + (_thinking ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              if (i >= _chat.length) return const _TypingBubble();
              return _MessageBubble(
                msg: _chat[i],
                onAction: _handleAction,
                onConfirmPicker: (p) => p.kind == 'words' ? _confirmWords(p) : _confirmSentences(p),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GhostButton(
              label: 'Start a new module',
              leading: Icons.add,
              onTap: () => _doNewLesson(true),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _chatText,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  onSubmitted: (_) => _sendFreeText(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Tell the AI what you want, or use a button above…',
                    hintStyle: TextStyle(fontSize: 13, color: DashColors.w(0.35)),
                    filled: true,
                    fillColor: DashColors.w(0.04),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: DashRadii.input, borderSide: BorderSide(color: DashColors.w(0.14))),
                    enabledBorder: OutlineInputBorder(borderRadius: DashRadii.input, borderSide: BorderSide(color: DashColors.w(0.14))),
                    focusedBorder: OutlineInputBorder(borderRadius: DashRadii.input, borderSide: BorderSide(color: DashColors.brand.withValues(alpha: 0.55))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DashIconButton(icon: Icons.send_rounded, tooltip: 'Send', onTap: _sendFreeText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabsColumn(AiCourseFull c) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(
            children: [
              for (final t in _Tab.values) _TabButton(tab: t, active: _tab == t, onTap: () => setState(() => _tab = t)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: DashColors.w(0.06),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
            child: SingleChildScrollView(
              child: switch (_tab) {
                _Tab.words => _WordsTab(course: c, onChanged: _reload),
                _Tab.lessons => _LessonsTab(
                    course: c,
                    currentLessonId: _currentLesson?.lessonId,
                    editingSentenceIds: _editingSentenceIds,
                    onToggleEdit: (id, editing) => setState(() {
                      if (editing) {
                        _editingSentenceIds.add(id);
                      } else {
                        _editingSentenceIds.remove(id);
                      }
                    }),
                    onChanged: _reload,
                  ),
                _Tab.edit => _EditCourseTab(
                    course: c,
                    editorCourse: _editorCourse,
                    onSaved: _reload,
                  ),
                _Tab.preview => _PreviewTab(course: c),
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Top bar — "My courses" pinned top-left, title centered on the page.
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
          Text(title, style: DashText.h2),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final _Tab tab;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.tab, required this.active, required this.onTap});

  String get _label => switch (tab) {
        _Tab.words => 'Words',
        _Tab.lessons => 'Lessons',
        _Tab.edit => 'Edit Course',
        _Tab.preview => 'Preview',
      };

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
          _label,
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
// Chat bubbles
// ===========================================================================
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Avatar(isUser: false),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: DashColors.w(0.06),
            border: Border.all(color: DashColors.w(0.14)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: SizedBox(
            width: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (_) => CircleAvatar(radius: 2.5, backgroundColor: DashColors.w(0.4))),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 13,
      backgroundColor: isUser ? DashColors.w(0.14) : DashColors.brand,
      child: Text(isUser ? 'Y' : 'AI', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final _ChatMsg msg;
  final void Function(_ChatAction) onAction;
  final void Function(_Picker) onConfirmPicker;
  const _MessageBubble({required this.msg, required this.onAction, required this.onConfirmPicker});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  @override
  Widget build(BuildContext context) {
    final msg = widget.msg;
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: msg.isUser ? DashColors.brand.withValues(alpha: 0.22) : DashColors.w(0.06),
        border: Border.all(color: msg.isUser ? DashColors.brand.withValues(alpha: 0.4) : DashColors.w(0.14)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(msg.isUser ? 14 : 4),
          topRight: Radius.circular(msg.isUser ? 4 : 14),
          bottomLeft: const Radius.circular(14),
          bottomRight: const Radius.circular(14),
        ),
      ),
      child: Text(msg.text, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
    );

    final body = Column(
      crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        if (msg.usage != null) ...[
          const SizedBox(height: 3),
          Text('≈${msg.usage!.tokens} tokens · \$${msg.usage!.cost.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 10, color: DashColors.w(0.35))),
        ],
        if (msg.actions != null && msg.actions!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final a in msg.actions!) GhostButton(label: a.label, onTap: () => widget.onAction(a))],
          ),
        ],
        if (msg.picker != null) ...[
          const SizedBox(height: 8),
          _PickerWidget(
            picker: msg.picker!,
            onChanged: () => setState(() {}),
            onConfirm: () => widget.onConfirmPicker(msg.picker!),
          ),
        ],
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: msg.isUser
          ? [Flexible(child: body), const SizedBox(width: 10), _Avatar(isUser: true)]
          : [_Avatar(isUser: false), const SizedBox(width: 10), Flexible(child: body)],
    );
  }
}

class _PickerWidget extends StatelessWidget {
  final _Picker picker;
  final VoidCallback onChanged;
  final VoidCallback onConfirm;
  const _PickerWidget({required this.picker, required this.onChanged, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final it in picker.items)
            if (!picker.answered || it.checked)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Opacity(
                  opacity: it.used ? 0.55 : 1,
                  child: InkWell(
                    onTap: picker.answered ? null : () { it.checked = !it.checked; onChanged(); },
                    borderRadius: DashRadii.input,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(color: DashColors.w(0.04), borderRadius: DashRadii.input),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18, height: 18,
                            child: Checkbox(
                              value: it.checked,
                              onChanged: picker.answered ? null : (v) { it.checked = v ?? false; onChanged(); },
                              side: BorderSide(color: DashColors.w(0.4)),
                              activeColor: DashColors.brand,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(it.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
                          if (it.sub.isNotEmpty)
                            Text(it.sub, style: TextStyle(fontSize: 11, color: DashColors.w(0.55))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          if (!picker.answered) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: PrimaryButton(label: picker.confirmLabel, onTap: onConfirm),
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// Words tab
// ===========================================================================
class _WordsTab extends ConsumerStatefulWidget {
  final AiCourseFull course;
  final Future<void> Function() onChanged;
  const _WordsTab({required this.course, required this.onChanged});

  @override
  ConsumerState<_WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends ConsumerState<_WordsTab> {
  final _word = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final raw = _word.text.trim();
    if (raw.isEmpty) return;
    final parts = raw.split('—');
    setState(() => _busy = true);
    await ref.read(dashboardApiProvider).addAiWord(
          courseId: widget.course.courseId,
          word: parts.first.trim(),
          gloss: parts.length > 1 ? parts[1].trim() : null,
        );
    _word.clear();
    await widget.onChanged();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _remove(String word) async {
    await ref.read(dashboardApiProvider).deleteAiWord(courseId: widget.course.courseId, word: word);
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.course.words;
    if (words.isEmpty) {
      return Text('No words yet — ask the AI to create a word list in the chat.',
          style: TextStyle(fontSize: 12, color: DashColors.w(0.55)));
    }
    final usedCount = words.where((w) => w.used).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COURSE WORD BANK (${words.length}) · $usedCount USED',
            style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final w in words) _WordChip(word: w, onRemove: () => _remove(w.word))],
        ),
        const SizedBox(height: 18),
        Text('ADD A WORD MANUALLY', style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _word,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'e.g. 猫 — cat',
                  hintStyle: TextStyle(fontSize: 12, color: DashColors.w(0.35)),
                  filled: true,
                  fillColor: DashColors.w(0.04),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  border: OutlineInputBorder(borderRadius: DashRadii.input, borderSide: BorderSide(color: DashColors.w(0.14))),
                  enabledBorder: OutlineInputBorder(borderRadius: DashRadii.input, borderSide: BorderSide(color: DashColors.w(0.14))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GhostButton(label: _busy ? '…' : 'Add', onTap: _busy ? null : _add),
          ],
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  final AiCourseWord word;
  final VoidCallback onRemove;
  const _WordChip({required this.word, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: word.used ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: DashColors.w(0.04),
          border: Border.all(color: DashColors.w(0.14)),
          borderRadius: DashRadii.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (word.used) ...[
              Icon(Icons.check, size: 12, color: DashColors.green500),
              const SizedBox(width: 4),
            ],
            Text(word.word, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(width: 6),
            Text(word.gloss, style: TextStyle(fontSize: 11, color: DashColors.w(0.55))),
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(radius: 9, backgroundColor: DashColors.w(0.08), child: Icon(Icons.close, size: 11, color: DashColors.w(0.7))),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Lessons tab — grouped by module; only the current module+lesson expand.
// ===========================================================================
class _LessonsTab extends StatelessWidget {
  final AiCourseFull course;
  final int? currentLessonId;
  final Set<int> editingSentenceIds;
  final void Function(int, bool) onToggleEdit;
  final Future<void> Function() onChanged;
  const _LessonsTab({
    required this.course,
    required this.currentLessonId,
    required this.editingSentenceIds,
    required this.onToggleEdit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (course.modules.every((m) => m.lessons.isEmpty)) {
      return Text('No lessons yet — select words for a lesson in the chat to start one.',
          style: TextStyle(fontSize: 12, color: DashColors.w(0.55)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in course.modules)
          if (m.lessons.isNotEmpty)
            _ModuleBlock(
              module: m,
              isCurrent: m.lessons.any((l) => l.lessonId == currentLessonId),
              currentLessonId: currentLessonId,
              course: course,
              editingSentenceIds: editingSentenceIds,
              onToggleEdit: onToggleEdit,
              onChanged: onChanged,
            ),
      ],
    );
  }
}

class _ModuleBlock extends StatefulWidget {
  final AiModuleFull module;
  final bool isCurrent;
  final int? currentLessonId;
  final AiCourseFull course;
  final Set<int> editingSentenceIds;
  final void Function(int, bool) onToggleEdit;
  final Future<void> Function() onChanged;
  const _ModuleBlock({
    required this.module,
    required this.isCurrent,
    required this.currentLessonId,
    required this.course,
    required this.editingSentenceIds,
    required this.onToggleEdit,
    required this.onChanged,
  });

  @override
  State<_ModuleBlock> createState() => _ModuleBlockState();
}

class _ModuleBlockState extends State<_ModuleBlock> {
  late bool _open = widget.isCurrent;

  @override
  Widget build(BuildContext context) {
    final lessons = widget.module.lessons;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: DashColors.w(0.04), border: Border.all(color: DashColors.w(0.14)), borderRadius: DashRadii.cardSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Text(widget.module.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  Text('${lessons.length} lesson${lessons.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 11, color: DashColors.w(0.55))),
                  const SizedBox(width: 8),
                  Icon(_open ? Icons.expand_more : Icons.chevron_right, size: 18, color: DashColors.w(0.4)),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  for (final l in lessons)
                    _LessonBlock(
                      lesson: l,
                      isCurrent: l.lessonId == widget.currentLessonId,
                      course: widget.course,
                      editingSentenceIds: widget.editingSentenceIds,
                      onToggleEdit: widget.onToggleEdit,
                      onChanged: widget.onChanged,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonBlock extends StatefulWidget {
  final AiLesson lesson;
  final bool isCurrent;
  final AiCourseFull course;
  final Set<int> editingSentenceIds;
  final void Function(int, bool) onToggleEdit;
  final Future<void> Function() onChanged;
  const _LessonBlock({
    required this.lesson,
    required this.isCurrent,
    required this.course,
    required this.editingSentenceIds,
    required this.onToggleEdit,
    required this.onChanged,
  });

  @override
  State<_LessonBlock> createState() => _LessonBlockState();
}

class _LessonBlockState extends State<_LessonBlock> {
  late bool _open = widget.isCurrent;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final words = widget.course.words.where((w) => lesson.words.contains(w.word)).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: DashColors.w(0.03), border: Border.all(color: DashColors.w(0.08)), borderRadius: DashRadii.cardSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(lesson.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 10),
                  StatusPill(label: lesson.status, kind: lesson.isReady ? PillKind.active : PillKind.draft, swatch: true),
                  const Spacer(),
                  Icon(_open ? Icons.expand_more : Icons.chevron_right, size: 18, color: DashColors.w(0.4)),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WORDS', style: DashText.sectionLabel(size: 10)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final w in words) _MiniChip(label: w.word)]),
                  const SizedBox(height: 14),
                  Text('SENTENCES', style: DashText.sectionLabel(size: 10)),
                  const SizedBox(height: 8),
                  for (final s in lesson.sentences)
                    _SentenceRow(
                      sentence: s,
                      lessonId: lesson.lessonId,
                      editing: widget.editingSentenceIds.contains(s.sentenceId),
                      onEdit: () => widget.onToggleEdit(s.sentenceId, true),
                      onSaved: () async {
                        widget.onToggleEdit(s.sentenceId, false);
                        await widget.onChanged();
                      },
                      onDelete: () async {
                        await providerScopeApi(context).deleteAiSentence(lessonId: lesson.lessonId, sentenceId: s.sentenceId);
                        widget.onToggleEdit(s.sentenceId, false);
                        await widget.onChanged();
                      },
                    ),
                  const SizedBox(height: 14),
                  Text('EXERCISES', style: DashText.sectionLabel(size: 10)),
                  const SizedBox(height: 8),
                  for (final ex in lesson.exercises)
                    _ExerciseCard(exercise: ex, onChanged: widget.onChanged),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GhostButton(
                      label: '+ Add exercise',
                      onTap: () async {
                        await providerScopeApi(context).createAiExercise(
                          courseId: widget.course.courseId,
                          moduleId: lesson.moduleId,
                          lessonId: lesson.lessonId,
                        );
                        await widget.onChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: DashColors.w(0.04), border: Border.all(color: DashColors.w(0.14)), borderRadius: DashRadii.pill),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _SentenceRow extends StatefulWidget {
  final AiLessonSentence sentence;
  final int lessonId;
  final bool editing;
  final VoidCallback onEdit;
  final Future<void> Function() onSaved;
  final Future<void> Function() onDelete;
  const _SentenceRow({required this.sentence, required this.lessonId, required this.editing, required this.onEdit, required this.onSaved, required this.onDelete});

  @override
  State<_SentenceRow> createState() => _SentenceRowState();
}

class _SentenceRowState extends State<_SentenceRow> {
  late final _controller = TextEditingController(text: widget.sentence.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await providerScopeApi(context).updateAiSentence(lessonId: widget.lessonId, sentenceId: widget.sentence.sentenceId, text: _controller.text);
    await widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: DashColors.w(0.04), border: Border.all(color: DashColors.w(0.08)), borderRadius: DashRadii.input),
        child: Row(
          children: [
            Expanded(
              child: widget.editing
                  ? TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                      onSubmitted: (_) => _save(),
                    )
                  : Text(widget.sentence.text, style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
            if (widget.editing)
              _RoundIconButton(icon: Icons.check, tooltip: 'Done', onTap: _save)
            else
              _RoundIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', onTap: widget.onEdit),
            const SizedBox(width: 4),
            _RoundIconButton(icon: Icons.close, tooltip: 'Delete', onTap: widget.onDelete),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: CircleAvatar(radius: 11, backgroundColor: DashColors.w(0.08), child: Icon(icon, size: 12, color: DashColors.w(0.7))),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final AiExercise exercise;
  final Future<void> Function() onChanged;
  const _ExerciseCard({required this.exercise, required this.onChanged});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late final _prompt = TextEditingController(text: widget.exercise.prompt);
  late final List<TextEditingController> _options =
      widget.exercise.options.map((o) => TextEditingController(text: o)).toList();
  late String? _answer = widget.exercise.answer;

  @override
  void dispose() {
    _prompt.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final options = _options.map((c) => c.text).toList();
    await providerScopeApi(context).updateAiExercise(
      exerciseId: widget.exercise.exerciseId,
      prompt: _prompt.text,
      options: options,
      answer: _answer,
    );
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: DashColors.w(0.04), border: Border.all(color: DashColors.w(0.08)), borderRadius: DashRadii.input),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.exercise.exerciseType.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: DashColors.w(0.55))),
          const SizedBox(height: 6),
          _smallField(_prompt, 'Question / prompt'),
          const SizedBox(height: 6),
          for (var i = 0; i < _options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Radio<String>(
                    value: _options[i].text,
                    groupValue: _answer,
                    onChanged: (v) {
                      setState(() => _answer = v);
                      _save();
                    },
                    activeColor: DashColors.green500,
                  ),
                  Expanded(child: _smallField(_options[i], 'Option ${i + 1}')),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: _RoundIconButton(
              icon: Icons.close,
              tooltip: 'Delete',
              onTap: () async {
                await providerScopeApi(context).deleteAiExercise(widget.exercise.exerciseId);
                await widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      style: const TextStyle(fontSize: 12, color: Colors.white),
      onSubmitted: (_) => _save(),
      onTapOutside: (_) => _save(),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: DashColors.w(0.35)),
        filled: true,
        fillColor: DashColors.w(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: DashColors.w(0.14))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: DashColors.w(0.14))),
      ),
    );
  }
}

// ===========================================================================
// Edit Course tab
// ===========================================================================
class _EditCourseTab extends ConsumerStatefulWidget {
  final AiCourseFull course;
  final EditorCourse? editorCourse;
  final Future<void> Function() onSaved;
  const _EditCourseTab({required this.course, required this.editorCourse, required this.onSaved});

  @override
  ConsumerState<_EditCourseTab> createState() => _EditCourseTabState();
}

class _EditCourseTabState extends ConsumerState<_EditCourseTab> {
  late final _title = TextEditingController(text: widget.course.title);
  late final _lang = TextEditingController(text: widget.course.lang);
  late final _toLang = TextEditingController(text: widget.course.toLang);
  late String _level = widget.course.level;

  @override
  void dispose() {
    _title.dispose();
    _lang.dispose();
    _toLang.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final base = widget.editorCourse;
    if (base == null) return;
    final updated = base.copyWith(
      title: _title.text.trim(),
      lang: _lang.text.trim(),
      toLang: _toLang.text.trim(),
      level: _level,
    );
    await ref.read(dashboardApiProvider).updateCourse(updated);
    await widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final exerciseCount = c.modules.fold(0, (n, m) => n + m.lessons.fold(0, (n2, l) => n2 + l.exercises.length));
    final lessonCount = c.modules.fold(0, (n, m) => n + m.lessons.length);
    final readyCount = c.modules.fold(0, (n, m) => n + m.lessons.where((l) => l.isReady).length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COURSE STATS', style: DashText.sectionLabel(size: 10)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatTile(value: '${c.words.length}', label: 'Words')),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(value: '${c.modules.length}', label: 'Modules')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatTile(value: '$lessonCount', label: 'Lessons · $readyCount ready')),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(value: '$exerciseCount', label: 'Exercises')),
          ],
        ),
        const SizedBox(height: 22),
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
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: PrimaryButton(label: 'Save changes', onTap: _save)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: DashColors.w(0.04), border: Border.all(color: DashColors.w(0.08)), borderRadius: DashRadii.cardSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: DashColors.w(0.55))),
        ],
      ),
    );
  }
}

// ===========================================================================
// Preview tab — read-only student view.
// ===========================================================================
class _PreviewTab extends StatelessWidget {
  final AiCourseFull course;
  const _PreviewTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final lessons = [for (final m in course.modules) ...m.lessons];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${flagFor(course.lang)}${flagFor(course.toLang)}', style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 6),
        Text(course.title, style: DashText.h2),
        const SizedBox(height: 2),
        Text('${course.lang} → ${course.toLang} · Level ${course.level} · ${course.words.length} words',
            style: TextStyle(fontSize: 11, color: DashColors.w(0.55))),
        const SizedBox(height: 16),
        if (lessons.isEmpty)
          Text('No lessons yet — build one from the chat, then preview it here.',
              style: TextStyle(fontSize: 12, color: DashColors.w(0.55)))
        else
          for (final l in lessons)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: DashColors.w(0.04), border: Border.all(color: DashColors.w(0.08)), borderRadius: DashRadii.cardSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  for (final s in l.sentences.where((s) => s.chosen))
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: DashColors.w(0.04), borderRadius: DashRadii.input),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.text, style: const TextStyle(fontSize: 13, color: Colors.white)),
                          Text(s.gloss, style: TextStyle(fontSize: 11, color: DashColors.w(0.55))),
                        ],
                      ),
                    ),
                  for (final ex in l.exercises)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: DashColors.w(0.04), border: Border.all(color: DashColors.w(0.14), style: BorderStyle.solid), borderRadius: DashRadii.input),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.prompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 8),
                          for (final opt in ex.options)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: opt == ex.answer ? DashColors.green500.withValues(alpha: 0.16) : DashColors.w(0.04),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(opt,
                                  style: TextStyle(fontSize: 12, color: opt == ex.answer ? const Color(0xFFC8E6C9) : Colors.white)),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Small helper so leaf widgets (sentence rows, exercise cards) don't each
/// need to be Consumer/ConsumerState just to reach the api client.
DashboardApi providerScopeApi(BuildContext context) =>
    ProviderScope.containerOf(context, listen: false).read(dashboardApiProvider);
