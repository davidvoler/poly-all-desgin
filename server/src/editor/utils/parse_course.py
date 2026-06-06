import os
import re

# Exercise-level `key: value` fields recognised inside an exercise block.
# The prompt sentence itself is a bare line (no key) and maps to `text`.
EXERCISE_FIELDS = ['type', 'text', 'text_alt1', 'text_alt2', 'text_alt3',
                   'voice', 'word1', 'word2', 'word3', 'sentence_id',
                   'to_sentence_id', 'weight', 'ruby_text', 'annotations',
                   'explanation']

# Course-import language names → ISO 639-1 codes (mirrors the README table).
# Anything unknown falls back to its first two lowercased chars (so a bare
# 2-letter code like "pt" passes through).
_LANG_CODES = {
    'english': 'en', 'en': 'en',
    'italian': 'it', 'italiano': 'it', 'it': 'it',
    'arabic': 'ar', 'العربية': 'ar', 'ar': 'ar',
    'hebrew': 'he', 'עברית': 'he', 'he': 'he',
    'spanish': 'es', 'español': 'es', 'es': 'es',
    'french': 'fr', 'français': 'fr', 'fr': 'fr',
    'japanese': 'ja', '日本語': 'ja', 'ja': 'ja',
    'greek': 'el', 'ελληνικά': 'el', 'el': 'el',
}


def lang_to_code(s: str) -> str:
    s = (s or '').strip()
    if not s:
        return ''
    return _LANG_CODES.get(s.lower(), s.lower()[:2])


def _folder_number(name: str) -> int:
    """Trailing/embedded number in a folder name (`module1`, `lesson02`) →
    its int, used as the weight so the dashboard orders correctly. 0 when
    there's no digit."""
    m = re.search(r'(\d+)', os.path.basename(name))
    return int(m.group(1)) if m else 0


def get_field_value(s: str):
    for field in EXERCISE_FIELDS:
        if s.startswith(f"{field}:"):
            return {field: s[len(field) + 1:].strip()}
    return {}


def parse_exercises_text(text: str):
    """Parse an `exercises.txt` body into a list of exercise dicts.

    Blocks are separated by a line that is exactly `---`. Inside a block:
      - the first bare (non-key, non-option) line is the prompt → `text`;
      - `[+]` / `[-]` lines are options (correct / distractor);
      - `key: value` lines set recognised exercise fields;
      - a line starting with `--- Explanation` (or `---Explanation`) opens a
        free-text note that runs to the next `---`.
    """
    exercises: list[dict] = []
    cur: dict | None = None
    in_explanation = False

    def flush():
        nonlocal cur
        if cur is None:
            return
        notes = cur.pop('_explanation', None)
        if notes:
            cur['explanation'] = '\n'.join(notes).strip()
        if not cur.get('options'):
            cur.pop('options', None)
        # Keep only blocks that carry actual content.
        if cur.get('text') or cur.get('options') or cur.get('explanation'):
            exercises.append(cur)
        cur = None

    def ensure():
        nonlocal cur
        if cur is None:
            cur = {'options': []}

    for raw in text.split('\n'):
        stripped = raw.strip()

        # Explanation marker — must be checked before the bare `---` case.
        if stripped.startswith('---') and \
                stripped[3:].strip().lower().startswith('explanation'):
            ensure()
            in_explanation = True
            cur.setdefault('_explanation', [])
            continue

        # Block separator.
        if stripped == '---':
            flush()
            cur = {'options': []}
            in_explanation = False
            continue

        if in_explanation:
            ensure()
            cur['_explanation'].append(raw)
            continue

        if stripped == '':
            continue

        ensure()
        if stripped.startswith('[+]'):
            cur['options'].append({'text': stripped[3:].strip(), 'correct': True})
            continue
        if stripped.startswith('[-]'):
            cur['options'].append({'text': stripped[3:].strip()})
            continue
        field = get_field_value(stripped)
        if field:
            cur.update(field)
            continue
        # A bare line — the prompt sentence (join extra lines with a space).
        cur['text'] = f"{cur['text']} {stripped}".strip() if cur.get('text') \
            else stripped

    flush()
    return exercises


def parse_lesson_fields(s: str):
    data = {}
    for e in s.split('\n'):
        if e.startswith('lesson:'):
            data['title'] = e[len('lesson:'):].strip()
        elif e.startswith('title:'):
            data['title'] = e[len('title:'):].strip()
        elif e.startswith('weight:'):
            try:
                data['weight'] = int(e[len('weight:'):].strip())
            except ValueError:
                data['weight'] = 0
    if not data.get('title'):
        data['title'] = 'Lesson'
    return data


def parse_lesson_folder(path: str, default_title: str = ''):
    """A lesson is a folder containing `lesson.txt` (title) and
    `exercises.txt` (the questions). Audio and other files are ignored."""
    data = {'title': default_title or 'Lesson', 'weight': _folder_number(path)}
    exercises: list[dict] = []
    for f in sorted(os.listdir(path)):
        fp = os.path.join(path, f)
        if not os.path.isfile(fp):
            continue
        low = f.lower()
        if low in ('lesson.txt', 'lesson.yaml', 'lesson.yml'):
            with open(fp, 'r') as file:
                data.update(parse_lesson_fields(file.read()))
        elif low in ('exercises.txt', 'exercise.txt'):
            with open(fp, 'r') as file:
                exercises = parse_exercises_text(file.read())
    data['exercises'] = exercises
    return data


def parse_lesson(file_path: str):
    """Legacy flat form: a single lesson file with the title fields at the
    top, then `---`-separated exercises."""
    with open(file_path, 'r') as file:
        content = file.read()
    lines = content.split('\n')
    i = 0
    while i < len(lines) and lines[i].strip() != '---':
        i += 1
    data = parse_lesson_fields('\n'.join(lines[:i]))
    data['weight'] = _folder_number(file_path)
    data['exercises'] = parse_exercises_text('\n'.join(lines[i:]))
    return data


def parse_module_fields(s: str):
    data = {}
    for e in s.split('\n'):
        if e.startswith('module:'):
            data['title'] = e[len('module:'):].strip()
        elif e.startswith('title:'):
            data['title'] = e[len('title:'):].strip()
        elif e.startswith('weight:'):
            try:
                data['weight'] = int(e[len('weight:'):].strip())
            except ValueError:
                pass
    return data


def parse_module(file_path: str, default_title: str = ''):
    module_data = {}
    lessons = []
    for f in sorted(os.listdir(file_path)):
        fp = os.path.join(file_path, f)
        low = f.lower()
        if low in ('module.txt', 'module.yaml', 'module.yml'):
            with open(fp, 'r') as file:
                module_data = parse_module_fields(file.read())
        elif os.path.isdir(fp):
            lessons.append(parse_lesson_folder(fp, default_title=f))
        elif os.path.isfile(fp):
            # Legacy flat lesson file alongside module.txt.
            lessons.append(parse_lesson(fp))
    weight = module_data.get('weight', _folder_number(file_path))
    module_data['weight'] = weight
    module_data['module'] = weight
    if not module_data.get('title'):
        module_data['title'] = default_title or f"Module {weight}"
    module_data['lessons'] = lessons
    return module_data


def parse_course_fields(s: str):
    """Parse `course.txt` and normalise to what the loader expects:
    `name` → title, `language` → lang (ISO), `student_languages` (first) →
    to_lang (ISO). The raw keys are kept too for forward-compatibility."""
    raw = {}
    for e in s.split('\n'):
        elm = e.split(':')
        if len(elm) < 2:
            continue
        raw[elm[0].strip().lower()] = ':'.join(elm[1:]).strip()
    student = raw.get('student_languages') or raw.get('to_lang') or ''
    first_student = student.split(',')[0].strip() if student else ''
    return {
        **raw,
        'title': raw.get('name') or raw.get('title') or 'Course',
        'description': raw.get('description', ''),
        'lang': lang_to_code(raw.get('language') or raw.get('lang')),
        'to_lang': lang_to_code(first_student),
    }


def parse_course(file_path: str):
    if not (os.path.exists(file_path) and os.path.isdir(file_path)):
        print(f"course folder not found: {file_path}")
        return None
    course_txt = os.path.join(file_path, 'course.txt')
    if not os.path.exists(course_txt):
        print(f"course.txt not found in {file_path}")
        return None
    with open(course_txt, 'r') as file:
        course_data = parse_course_fields(file.read())

    modules = []
    for f in sorted(os.listdir(file_path)):
        full = os.path.join(file_path, f)
        if os.path.isdir(full):
            modules.append(parse_module(full, default_title=f))
    course_data['modules'] = modules
    return course_data


if __name__ == "__main__":
    import sys
    path = sys.argv[1] if len(sys.argv) > 1 else \
        '../../content/example_course'
    course_data = parse_course(path)
    print('title:', course_data.get('title'))
    print('lang:', course_data.get('lang'), '→', course_data.get('to_lang'))
    for m in course_data.get('modules', []):
        print('module:', m.get('title'), 'weight', m.get('weight'),
              'lessons', len(m.get('lessons', [])))
        for l in m.get('lessons', []):
            print('  lesson:', l.get('title'), 'exercises',
                  len(l.get('exercises', [])))
