
import os


def parse_lesson_fields(s:str):
    elements = s.split('\n')
    lesson_data = {}
    for e in elements:
        elm=  e.split(':')
        if len(elm) < 2:
            continue
        lesson_data[elm[0].strip()] = ':'.join(elm[1:]).strip()
    return lesson_data


def parse_exercise_fields(s:str):
    elements = s.split('\n')
    exercise_data = {}
    options = []
    for e in elements:
        if e.startswith("[-]"):
            options.append({"text": e[3:].strip()})
            continue
        if e.startswith("[+]"):
            options.append({"text": e[3:].strip(), "correct": True})
            continue
        elm=  e.split(':')
        if len(elm) < 2:
            continue
        exercise_data[elm[0].strip()] = elm[1].strip()
    if options:
        exercise_data['options'] = options
    return exercise_data

def parse_lesson(file_path):
    with open(file_path, 'r') as file:
        lesson = file.read().strip()
    parts = lesson.split('---\n')
    lesson_data = parse_lesson_fields(parts[0])
    exercises = []
    for e in parts[1:]:
        exercise_data = parse_exercise_fields(e)
        exercises.append(exercise_data)
    lesson_data['exercises'] = exercises    
    return lesson_data

def parse_module_fields(s:str):
    elements = s.split('\n')
    module_data = {}
    for e in elements:
        elm=  e.split(':')
        if len(elm) < 2:
            continue
        module_data[elm[0].strip()] = ':'.join(elm[1:]).strip()
    return module_data

def parse_module(file_path,default_title=""):
    list_files = os.listdir(file_path)
    module_data = {}
    lessons = []
    for f in list_files:
        if f == 'module.txt':
           with open(os.path.join(file_path, f), 'r') as file:
               module = file.read().strip()
           module_data = parse_module_fields(module)
        else:
            lesson_data = parse_lesson(os.path.join(file_path, f))
            lessons.append(lesson_data)
    if not module_data.get('title'):
        module_data['title'] = default_title
    module_data['lessons'] = lessons
    return module_data

def parse_course_fields(s:str):
    elements = s.split('\n')
    course_data = {}
    for e in elements:
        elm=  e.split(':')
        if len(elm) < 2:
            continue
        course_data[elm[0].strip()] = ':'.join(elm[1:]).strip()
    return course_data




def parse_course(file_path):
    corse_data = {}
    if os.path.exists(file_path) and os.path.isdir(file_path):
        if os.path.exists(os.path.join(file_path, 'course.txt')):
            with open(os.path.join(file_path, 'course.txt'), 'r') as file:
                course = file.read().strip()
            course_data = parse_course_fields(course)
        else:
            print(f"course.txt not found in {file_path}")
            return None, None
    list_files = os.listdir(file_path)
    modules = []
    for f in list_files:
        if os.path.isdir(os.path.join(file_path, f)):
            module_data = parse_module(os.path.join(file_path, f), default_title=f)
            modules.append(module_data)
    course_data['modules'] = modules
    return course_data



if __name__ == "__main__":
    course_data = parse_course('../data/content/ja/ja_en_basic_course_v1')
    # print(course_data)
    print(course_data.get('title'))
    print(course_data.get('lang'))
    print(course_data.get('to_lang'))
    for m in course_data.get('modules', []):
        print(m.get('title'))
        print(len(m.get('lessons', [])))
        for l in m.get('lessons', []):
            print(l.get('title'))
            print(len(l.get('exercises', [])))