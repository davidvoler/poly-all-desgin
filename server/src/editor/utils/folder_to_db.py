from utils.db import get_query_results, run_query
from editor.utils.parse_course import parse_course
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
    sentence_alt1 = exercise.get('text_alt1', '')
    sentence_alt2 = exercise.get('text_alt2', '')
    sentence_alt3 = exercise.get('text_alt3', '')
    sql = """
    INSERT INTO course_simple.exercise (course_id, module_id, lesson_id, exercise_type, sentence, options, audio, word1, word2, word3, sentence_id, to_sentence_id, sentence_alt1, sentence_alt2, sentence_alt3) 
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) 
    """
    params = (course_id, module_id, lesson_id, exercise_type, sentence, json.dumps(options), audio, word1, word2, word3, sentence_id, to_sentence_id, sentence_alt1, sentence_alt2, sentence_alt3)
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


async def _load_text_format(course_id: int, root: str) -> dict:
    print(f"Loading text-format course from {root}...")
    course_data = parse_course(root)
    print(course_data.get('title'))
    print(course_data.get('lang'))
    print(course_data.get('to_lang'))
    for m in course_data.get('modules', []):
        print(m.get('title'))
        print(len(m.get('lessons', [])))
        for l in m.get('lessons', []):
            print(l.get('title'))
            print(len(l.get('exercises', [])))




async def _load_text_format_old(course_id: int, root: str) -> dict:
    """Load a text-format course folder into `course_simple`.

    Parsing is delegated to the standalone `parse_course` (in
    editor.utils.parse_course), which walks the folder into a nested
    course → modules → lessons → exercises dict in the new lesson
    format (lesson front-matter + `key: value` exercise blocks). This
    function only persists that dict; the parser is kept in its own
    file so the format can evolve independently.

    Returns counts in the same shape as `load_course_content`."""
    course_data = parse_course(root)
    if not course_data:
        return {'modules': 0, 'skipped': 0}

    # course.txt drives the COURSE row's title / lang / to_lang.
    title = course_data.get('title', '')
    desc = course_data.get('description', '')
    lang = _to_lang_code(course_data.get('lang') or course_data.get('language', ''))
    # student_languages may be comma-separated; persist only the first
    # (course_simple.course has a single `to_lang`).
    to_lang = _to_lang_code(
        course_data.get('to_lang')
        or course_data.get('student_languages', '').split(',')[0]
    )
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

    modules_loaded = 0
    skipped = 0
    for idx, module in enumerate(course_data.get('modules', []), start=1):
        module_title = module.get('title') or f'Module {idx}'
        # Weight from an explicit `weight:` field, else the trailing
        # number of the module folder name (module_1 → 1), else order.
        try:
            weight = int(str(module.get('weight')).strip())
        except (TypeError, ValueError):
            m = re.search(r'(\d+)$', module_title)
            weight = int(m.group(1)) if m else idx

        inserted = await get_query_results(
            """
            INSERT INTO course_simple.module (course_id, weight, title)
            VALUES (%s, %s, %s)
            RETURNING module_id
            """,
            (course_id, weight, module_title),
        )
        if not inserted:
            skipped += 1
            continue
        module_id = inserted[0]['module_id']
        modules_loaded += 1

        for lesson in module.get('lessons', []):
            lesson_title = lesson.get('title', '')
            words = lesson.get('words', []) or []
            lesson_rows = await get_query_results(
                """
                INSERT INTO course_simple.lesson (course_id, module_id, title, words)
                VALUES (%s, %s, %s, %s)
                RETURNING lesson_id
                """,
                (course_id, module_id, lesson_title, words),
            )
            if not lesson_rows:
                continue
            lesson_id = lesson_rows[0]['lesson_id']

            for ex in lesson.get('exercises', []):
                await load_exercise(course_id, module_id, lesson_id, ex)

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


