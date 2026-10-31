import json
import yaml







def export_course(course: dict, target_file: str):
    title = course.get('description', 'No description provided.')
    description = course.get('description', 'No description provided.')
    lang = course.get('lang', 'en')
    to_lang = course.get('to_lang', 'en')
    modules = course.get('modules', [])
    with open(target_file, 'w') as file:
        file.write(f"type: course\n")
        file.write(f"title: {title}\n")
        file.write(f"description: {description}\n")
        file.write(f"lang: {lang}\n")
        file.write(f"to_lang: {to_lang}\n")
        for module in modules:
            file.write(f"---\n")
            file.write(f"type: module\n")
            file.write(f"title: {module.get('title', 'Untitled Module')}\n")
            file.write(f"description: {module.get('description', 'No description provided.')}\n")
            lessons = module.get('lessons', [])
            file.write(f"weight: {module.get('weight', 0)}\n")
            for lesson in lessons:
                file.write(f"---\n")
                file.write(f"type: lesson\n")
                file.write(f"title: {lesson.get('title', 'Untitled Lesson')}\n")
                file.write(f"description: {lesson.get('description', 'No description provided.')}\n")
                file.write(f"weight: {lesson.get('weight', 0)}\n")
                exercises = lesson.get('exercises', [])
                for exercise in exercises:
                    file.write("---\n")
                    yaml_str = yaml.dump(exercise, default_flow_style=False, sort_keys=False, allow_unicode=True)
                    file.write(yaml_str)












if __name__ == "__main__":
    file_path = "output_course.json"
    with open(file_path, 'r') as json_file:
        course = json.load(json_file)
    export_course(course, 'exported_course.yaml')