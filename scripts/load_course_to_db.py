from db import get_query_results, run_query
import yaml
import os


def create_course(course_name: str, lang: str, to_lang: str):
    sql = """
    INSERT INTO courses (name, lang,to_lang) 
    VALUES (%s, %s, %s)
    RETURNING course_id
    """
    params = (course_name, lang, to_lang)
    return run_query(sql, params)

def load_module(course_id: int, module: dict):
    sql = """
    INSERT INTO modules (course_id, name, weight) 
    VALUES (%s, %s, %s, %s) 
    RETURNING module_id
    """
    module_no = module.get('module')
    module_name = f"Module  {module_no}"
    params = (course_id,  module_name, module_no)
    return run_query(sql, params)

def load_lesson(module_id: int, lesson_name: str):
    sql = """
    INSERT INTO lessons (module_id, name) 
    VALUES (%s, %s) 
    RETURNING lesson_id
    """
    params = (module_id, lesson_name)
    return run_query(sql, params)

def load_exercise(lesson_id: int, exercise_name: str, exercise_content: str):
    sql = """
    INSERT INTO exercises (lesson_id, name, content) 
    VALUES (%s, %s, %s) 
    RETURNING exercise_id
    """
    params = (lesson_id, exercise_name, exercise_content)
    return run_query(sql, params)

def load_course_from_folder(folder_path: str, course_name: str, lang: str, to_lang: str):
    ## list all yaml files in the folder
    course_id = create_course(course_name, lang, to_lang)
    yaml_files = [f for f in os.listdir(folder_path) if f.endswith('.yaml')]
    for f in yaml_files:
        with open(os.path.join(folder_path, f), 'r') as file:
            data = yaml.safe_load(file)
            load_module(course_id, data)
