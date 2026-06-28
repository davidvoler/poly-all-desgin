import yaml




def _handle_none_valid_yaml(element):
    return {"TODO": "Handle None or invalid YAML element"}

def _handle_single_element(element):
    if element.strip():
        try:
            return yaml.safe_load(element)
        except yaml.YAMLError as e:
            print(f"Error parsing YAML element: {e}")
        try:
            return _handle_none_valid_yaml(element)      
        except Exception as e:
            print(f"Error handling None or invalid YAML element: {e}")
    return None


def elements_to_course(elements):
    course = {
        'modules': []
    }
    module = {}
    lesson = {}
    exercises = []
    for e in elements:
        element_type = e.get('type', 'exercise')
        if element_type == 'course':
            course.update(e)
        elif element_type == 'module':
            if module:
                if lesson:
                    if len(exercises) > 0:
                        lesson['exercises'] = exercises
                        exercises = []
                    module['lessons'].append(lesson)
                    lesson = {}
                course['modules'].append(module)
            module = e
            module['lessons'] = []
        elif element_type == 'lesson':
            if lesson:
                if len(exercises) > 0:
                    lesson['exercises'] = exercises
                    exercises = []
                module['lessons'].append(lesson)
                lesson = {}
        elif element_type == 'exercise':
            exercises.append(e)
    
    if len(exercises) > 0:
        lesson['exercises'] = exercises
    if lesson:
        module['lessons'].append(lesson)
    if module:
        course['modules'].append(module)

    return course
    


def parse_elements(elements):
    parsed_elements = []
    for element in elements:
        parsed_element = _handle_single_element(element)
        if parsed_element is not None:
            parsed_elements.append(parsed_element)
    return parsed_elements


def _print_course(course:dict):
    print("Course Title:", course.get('title', 'N/A'))
    print("Course Description:", course.get('description', 'N/A'))
    print("Modules:")
    for module in course.get('modules', []):
        print("  Module Title:", module.get('title', 'N/A'))
        print("  Module Description:", module.get('description', 'N/A'))
        print("  Lessons:")
        for lesson in module.get('lessons', []):
            print("    Lesson Title:", lesson.get('title', 'N/A'))
            print("    Lesson Description:", lesson.get('description', 'N/A'))
            print("    Exercises:")
            for exercise in lesson.get('exercises', []):
                print("      Exercise Content:", exercise)

def load_course_from_file(file_path):
    with open(file_path, 'r') as file:
        course_data = file.read()
    elements = course_data.split('---')
    return parse_elements(elements)



if __name__ == "__main__":
    file_path = "/Users/davidle/dev/tutorial/poly-all-desgin/content/example_course.yaml"
    elements = load_course_from_file(file_path)
    course = elements_to_course(elements)
    _print_course(course)