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


async def load_course_content(course_id: int, folder_path: str) -> dict:
    """Best-effort ingestion into an existing `course_simple.course`
    row — used by /api/v1/editor/upload/ after the zip is extracted.
    Walks the folder for module YAML/JSON files matching
    `module_<n>.{yaml,json}` (and a few other shapes the test fixtures
    use) and loads each one. Silently skips files we don't understand
    so a partial archive still creates the course shell.

    Returns a small counts dict for the API response."""
    if not os.path.isdir(folder_path):
        return {'modules': 0, 'skipped': 0}

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


