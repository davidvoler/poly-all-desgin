from utils.db import get_query_results, run_query
import yaml
import os
import asyncio
import json

async def create_course(course_name: str, lang: str, to_lang: str):
    sql = """
    INSERT INTO course_simple.course (title, lang, to_lang) 
    VALUES (%s, %s, %s)
    RETURNING course_id
    """
    params = (course_name, lang, to_lang)
    res = await get_query_results(sql, params)
    if len(res) > 0:
        return res[0].get('course_id')
    return None

async def load_module(course_id: int, module: dict, module_no: int):
    sql = """
    INSERT INTO course_simple.module (course_id, weight, title) 
    VALUES (%s, %s, %s) 
    RETURNING module_id
    """
    module_name = f"Module  {module_no}"
    params = (course_id,  module_no, module_name)
   

    res = await get_query_results(sql, params)
    if len(res) > 0:
        module_id = res[0].get('module_id')
        lessons = module.get('modules', [])[0].get('lessons', [])
        for l in lessons:
            await load_lesson(course_id, module_id, l)

async def load_lesson(course_id: int, module_id: int, lesson: dict):
    lesson_name = lesson.get('lesson')
    words = lesson.get('words', [])
    sql = """
    INSERT INTO course_simple.lesson (course_id, module_id, title, words) 
    VALUES (%s, %s, %s, %s) 
    RETURNING lesson_id
    """
    params = (course_id, module_id, lesson_name, words)
    res = await get_query_results(sql, params)
    if len(res) > 0:
        lesson_id = res[0].get('lesson_id')
        exercises = lesson.get('exercises', [])
        for ex in exercises:
            await load_exercise(course_id, module_id, lesson_id, ex)
        return lesson_id
    return None
    
    

async def load_exercise(course_id:int, module_id: int, lesson_id: int, exercise: dict):
    sentence = exercise.get('text', '')
    exercise_type = exercise.get('type', '')
    options = exercise.get('options', [])
    audio = exercise.get('voice', '')
    word1 = exercise.get('word1', '')
    word2 = exercise.get('word2', '')
    word3 = exercise.get('word3', '')
    sentence_id = exercise.get('sentence_id', None)
    to_sentence_id = exercise.get('sentence_to_id', None)

    sql = """
    INSERT INTO course_simple.exercise (course_id, module_id, lesson_id, exercise_type, sentence, options, audio, word1, word2, word3, sentence_id, to_sentence_id) 
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) 
    """
    params = (course_id, module_id, lesson_id, exercise_type, sentence, json.dumps(options), audio, word1, word2, word3, sentence_id, to_sentence_id)
    return await run_query(sql, params)

async def load_course_from_folder(folder_path: str, course_name: str, lang: str, to_lang: str):
    course_id = await create_course(course_name, lang, to_lang)
    yaml_files = [f for f in os.listdir(folder_path) if f.endswith('.yaml')]
    for f in yaml_files:
        f_items = f.split('.')
        m_no = int(f_items[0].split('_')[1])
        with open(os.path.join(folder_path, f), 'r') as file:
            data = yaml.safe_load(file)
            await load_module(course_id, data, m_no)


import re


# Common language names → ISO-639-1 code. The text-format `course.txt`
# accepts either, so we lookup names here and fall through to the raw
# value (assumed to be a code) when the name isn't recognised.
_LANG_NAME_TO_CODE: dict[str, str] = {
    'english': 'en',
    'italian': 'it', 'italiano': 'it',
    'arabic': 'ar', 'العربية': 'ar',
    'hebrew': 'he', 'עברית': 'he',
    'spanish': 'es', 'español': 'es',
    'french': 'fr', 'français': 'fr',
    'japanese': 'ja', '日本語': 'ja',
    'greek': 'el', 'ελληνικά': 'el',
}


def _to_lang_code(s: str) -> str:
    """Map a `course.txt` language name to an ISO code. Strings that
    don't match (custom languages, already-ISO codes) pass through
    lowercased."""
    raw = (s or '').strip()
    if not raw:
        return ''
    code = _LANG_NAME_TO_CODE.get(raw.lower())
    return code or raw.lower()


def _parse_kv_file(path: str) -> dict:
    """Read a `key: value` text file (course.txt / module.txt /
    lesson.txt). Skips comments + blank lines. Only the first colon
    is treated as the key separator so values can themselves contain
    colons."""
    out: dict[str, str] = {}
    try:
        with open(path, 'r', encoding='utf-8') as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if ':' not in line:
                    continue
                key, val = line.split(':', 1)
                out[key.strip().lower()] = val.strip()
    except Exception:
        pass
    return out


def _parse_exercises_file(path: str) -> list[dict]:
    """Parse the `---`-separated exercises file format used by
    content/example_course. Returns one dict per exercise in
    `course_simple.exercise` shape — same keys load_exercise() reads.

    Block layout:
      - first non-blank line  → sentence (prompt)
      - lines starting [+]/[-] → options (correct/incorrect)
      - a line starting `--- Explanation` or `---Explanation`
        (case-insensitive) opens an explanation block that runs to
        the next `---`. Joined with newlines.
    """
    if not os.path.isfile(path):
        return []
    try:
        with open(path, 'r', encoding='utf-8') as fh:
            text = fh.read()
    except Exception:
        return []

    # Split on lines that are exactly "---" (with optional whitespace),
    # NOT "--- Explanation" — that's handled below. Re-tag explanation
    # markers first so the split doesn't eat them.
    EXPL = re.compile(r'^---\s*explanation\s*$', re.IGNORECASE | re.MULTILINE)
    SEP = re.compile(r'^---\s*$', re.MULTILINE)

    out: list[dict] = []
    # Each exercise: sentence on first non-blank line, options below.
    # We walk blocks split by SEP (skipping pure-separator entries).
    for raw_block in SEP.split(text):
        block = raw_block.strip()
        if not block:
            continue

        sentence = ''
        options: list[dict] = []
        explanation_lines: list[str] = []
        in_explanation = False

        for line in block.splitlines():
            stripped = line.strip()
            if not stripped:
                continue
            if EXPL.match(stripped):
                in_explanation = True
                continue
            if in_explanation:
                explanation_lines.append(line.rstrip())
                continue
            if stripped.startswith('[+]'):
                options.append({
                    'text': stripped[3:].strip(),
                    'correct': True,
                })
            elif stripped.startswith('[-]'):
                options.append({
                    'text': stripped[3:].strip(),
                    'correct': False,
                })
            elif not sentence:
                sentence = stripped

        if not sentence and not options:
            continue
        ex = {
            'type': 'simple',
            'text': sentence,
            'options': options,
            'voice': '',
            'word1': '',
            'word2': '',
            'word3': '',
        }
        if explanation_lines:
            # Stored as the third "word" slot for now — the existing
            # exercise schema doesn't have a dedicated explanation
            # column, but `word3` is unused for simple-translation
            # exercises so we piggy-back without a migration.
            ex['word3'] = '\n'.join(explanation_lines).strip()
        out.append(ex)
    return out


async def _load_text_format(course_id: int, root: str) -> dict:
    """Walk a `content/example_course`-shaped folder and load it into
    `course_simple`. Returns counts in the same shape as
    `load_course_content` so callers can mix-and-match outputs."""
    modules_loaded = 0
    skipped = 0

    # course.txt at the root is metadata for the COURSE row itself;
    # update title / description / lang / to_lang from it when present.
    course_meta = _parse_kv_file(os.path.join(root, 'course.txt'))
    if course_meta:
        title = course_meta.get('name', '')
        desc = course_meta.get('description', '')
        lang = _to_lang_code(course_meta.get('language', ''))
        # student_languages may be comma-separated; we only persist the
        # first one for now (course_simple.course has a single `to_lang`).
        student = course_meta.get('student_languages', '').split(',')[0]
        to_lang = _to_lang_code(student)
        await run_query(
            """
            UPDATE course_simple.course
               SET title       = COALESCE(NULLIF(%s, ''), title),
                   description = COALESCE(NULLIF(%s, ''), description),
                   lang        = COALESCE(NULLIF(%s, ''), lang),
                   to_lang     = COALESCE(NULLIF(%s, ''), to_lang),
                   updated_at  = now()
             WHERE course_id = %s
            """,
            (title, desc, lang, to_lang, course_id),
        )

    # Module dirs — alphabetical so module1 / module2 / module03 work.
    for module_dir in sorted(os.listdir(root)):
        full_mod = os.path.join(root, module_dir)
        if not os.path.isdir(full_mod):
            continue
        module_meta = _parse_kv_file(os.path.join(full_mod, 'module.txt'))
        if not module_meta:
            # Not a text-format module dir — skip silently (might be a
            # YAML-format module, which the legacy loop will handle).
            continue

        # Preserve numeric suffix in `module<n>` as weight when present.
        m = re.search(r'(\d+)$', module_dir)
        m_no = int(m.group(1)) if m else modules_loaded + 1
        module_title = module_meta.get('module', module_dir)

        inserted = await get_query_results(
            """
            INSERT INTO course_simple.module (course_id, weight, title)
            VALUES (%s, %s, %s)
            RETURNING module_id
            """,
            (course_id, m_no, module_title),
        )
        if not inserted:
            skipped += 1
            continue
        module_id = inserted[0]['module_id']
        modules_loaded += 1

        # Lesson dirs inside this module.
        for lesson_dir in sorted(os.listdir(full_mod)):
            full_les = os.path.join(full_mod, lesson_dir)
            if not os.path.isdir(full_les):
                continue
            lesson_meta = _parse_kv_file(os.path.join(full_les, 'lesson.txt'))
            lesson_title = lesson_meta.get('lesson', lesson_dir)

            lesson_rows = await get_query_results(
                """
                INSERT INTO course_simple.lesson (course_id, module_id, title, words)
                VALUES (%s, %s, %s, %s)
                RETURNING lesson_id
                """,
                (course_id, module_id, lesson_title, []),
            )
            if not lesson_rows:
                continue
            lesson_id = lesson_rows[0]['lesson_id']

            for ex in _parse_exercises_file(os.path.join(full_les, 'exercises.txt')):
                await run_query(
                    """
                    INSERT INTO course_simple.exercise
                        (course_id, module_id, lesson_id, exercise_type,
                         sentence, options, audio, word1, word2, word3)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        course_id, module_id, lesson_id,
                        ex.get('type', 'simple'),
                        ex.get('text', ''),
                        json.dumps(ex.get('options', [])),
                        ex.get('voice', ''),
                        ex.get('word1', ''),
                        ex.get('word2', ''),
                        ex.get('word3', ''),
                    ),
                )

    return {'modules': modules_loaded, 'skipped': skipped}


def _looks_like_text_format(root: str) -> str | None:
    """Return the root that contains the text-format files, or None.
    Checks both `root/course.txt` and `root/<single subdir>/course.txt`
    so uploads that wrap content in a top-level directory still work."""
    if os.path.isfile(os.path.join(root, 'course.txt')):
        return root
    # Single-subdirectory wrapper (common when zipping a folder).
    try:
        entries = [e for e in os.listdir(root) if not e.startswith('.')]
    except OSError:
        return None
    subdirs = [e for e in entries if os.path.isdir(os.path.join(root, e))]
    if len(subdirs) == 1:
        inner = os.path.join(root, subdirs[0])
        if os.path.isfile(os.path.join(inner, 'course.txt')):
            return inner
    return None


async def load_course_content(course_id: int, folder_path: str) -> dict:
    """Best-effort ingestion into an existing `course_simple.course`
    row — used by /api/v1/editor/upload/ after the zip is extracted.

    Detection order:
      1. `course.txt` present (text format from content/example_course
         and the public-school import path) → walk module/lesson dirs.
      2. Fallback to YAML/JSON module files (`module_<n>.yaml|json`)
         for backwards compatibility with the test fixtures.

    Returns a small counts dict for the API response."""
    if not os.path.isdir(folder_path):
        return {'modules': 0, 'skipped': 0}

    text_root = _looks_like_text_format(folder_path)
    if text_root is not None:
        return await _load_text_format(course_id, text_root)

    # ----- legacy YAML / JSON loader -----
    # Look one level deep too — uploaded zips sometimes wrap their
    # contents in a single top-level directory.
    candidates: list[str] = []
    for fname in sorted(os.listdir(folder_path)):
        full = os.path.join(folder_path, fname)
        if os.path.isdir(full):
            for inner in sorted(os.listdir(full)):
                candidates.append(os.path.join(full, inner))
        else:
            candidates.append(full)

    modules_loaded = 0
    skipped = 0
    module_no = 1
    for path in candidates:
        if not os.path.isfile(path):
            continue
        ext = os.path.splitext(path)[1].lower()
        if ext not in ('.yaml', '.yml', '.json'):
            continue
        # Pull the module index from `module_<n>` when present so
        # weights stay stable across re-imports; otherwise auto-number.
        stem = os.path.splitext(os.path.basename(path))[0]
        m_no = module_no
        if stem.startswith('module_'):
            try:
                m_no = int(stem.split('_', 1)[1])
            except ValueError:
                pass
        try:
            with open(path, 'r', encoding='utf-8') as fh:
                data = yaml.safe_load(fh) if ext != '.json' else json.load(fh)
        except Exception:
            skipped += 1
            continue
        if not isinstance(data, dict):
            skipped += 1
            continue
        try:
            await load_module(course_id, data, m_no)
            modules_loaded += 1
            module_no += 1
        except Exception:
            skipped += 1

    return {'modules': modules_loaded, 'skipped': skipped}


