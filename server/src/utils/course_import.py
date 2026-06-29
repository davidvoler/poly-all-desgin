import re

import yaml
import json



def _handle_none_valid_yaml(element):
    return {"TODO": "Handle None or invalid YAML element"}

def _handle_single_element(element):
    if element.strip():
        try:
            return  yaml.safe_load(element) 
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
    modules = []
    lessons = []
    exercises = []
    module_weight = 0
    lesson_weight = 0
    exercise_weight = 0
    current_module = {
    }
    current_lesson = {
    }
    for e in elements:
        element_type = e.get('type', 'exercise')
        if element_type == 'course':
            course.update(e)
        elif element_type == 'module':
            module_weight += 1
            if current_lesson or len(exercises) > 0:
                module_weight = current_module.get('weight', module_weight)
                current_lesson['exercises'] = exercises
                lessons.append(current_lesson)
                current_module['lessons'] = lessons
                modules.append(current_module)
                current_lesson = {}
                lessons = []
                exercises = []
                lesson_weight = 0
                exercise_weight = 0
            current_module = e
            current_module['weight'] = module_weight
            current_module['lessons'] = []
        elif element_type == 'lesson':
            lesson_weight += 1
            if current_lesson or len(exercises) > 0:
                lesson_weight = current_lesson.get('weight', lesson_weight)
                current_lesson['weight'] = lesson_weight
                current_lesson['exercises'] = exercises
                lessons.append(current_lesson)
                exercises = []
                exercise_weight = 0
            current_lesson = e
        elif element_type == 'exercise':
            exercise_weight += 1
            exercise_weight = e.get('weight', exercise_weight)
            e['weight'] = exercise_weight
            exercises.append(e)
    current_lesson['exercises'] = exercises
    current_module['lessons'] = lessons
    modules.append(current_module)
    course['modules'] = modules    
    return course
    


def parse_elements(elements):
    parsed_elements = []
    for element in elements:
        parsed_element = _handle_single_element(element)
        if parsed_element is not None:
            parsed_elements.append(parsed_element)
    return parsed_elements


def _print_course(course:dict):
    print("Title:", course.get('title', 'N/A'))
    print("Description:", course.get('description', 'N/A'))
    print("lang:", course.get('lang', 'N/A'))
    print("To Lang:", course.get('to_lang', 'N/A'))
    for module in course.get('modules', []):
        print("\tTitle:", module.get('title', 'N/A'))
        print("\tDescription:", module.get('description', 'N/A'))
        for lesson in module.get('lessons', []):
            print("\t\tTitle:", lesson.get('title', 'N/A'))
            print("\t\tDescription:", lesson.get('description', 'N/A'))
            for exercise in lesson.get('exercises', []):
                print("\t\t\t", exercise)

def load_course_from_file(file_path):
    with open(file_path, 'r') as file:
        course_data = file.read()
    elements = course_data.split('---')
    return parse_elements(elements)
    



if __name__ == "__main__":
    file_path = "/Users/davidle/dev/tutorial/poly-all-desgin/content/example_course2.yaml"
    elements = load_course_from_file(file_path)
    course = elements_to_course(elements)
    _print_course(course)
    with open('output_course.json', 'w') as json_file:
        json.dump(course, json_file, indent=4)  