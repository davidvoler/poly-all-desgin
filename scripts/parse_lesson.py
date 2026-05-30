



def parse_lesson_fields(s:str):
    elements = s.split('\n')
    lesson_data = {}
    for e in elements:
        elm=  e.split(':')
        if len(elm) < 2:
            continue
        lesson_data[elm[0].strip()] = ':'.join(elm[1:]).strip()
    return lesson_data


def parse_course_fields(s:str):
    elements = s.split('\n')
    course_data = {}
    for e in elements:
        elm=  e.split(':')
        if len(elm) < 2:
            continue
        course_data[elm[0].strip()] = ':'.join(elm[1:]).strip()
    return course_data

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
    return lesson_data, exercises
        

if __name__ == "__main__":
    lesson_data, exercises = parse_lesson('../data/content/ja/ja_en_basic_course_v1/module_1/lesson_1.txt')
    # print(lesson_data)
    print(exercises)
    for ex in exercises:
        print(ex)
        print("------------------")