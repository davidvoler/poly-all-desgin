
import os 


def split_exercise(exercise:str):
    exercise = exercise.strip()
    lines = exercise.split('\n')
    ex = {
        "sentence": '',
        "options": [],
        "exercise_type": ''
    }
    for line in lines:
        if line.strip() == '':
            continue
        elif line.strip() in ['simple', 'recognize', 'read']:
            ex['exercise_type'] = line.strip()
        elif line.startswith('[-]'):
            ex['options'].append({
                "option": line[len('[-]'):].strip(),
                "is_correct": False
            })
        elif line.startswith('[+]'):
            ex['options'].append({
                "option": line[len('[+]'):].strip(),
                "is_correct": True
            })
        else:
            ex['sentence'] += line.strip() + ' '
    return ex


def import_lesson(lesson_file:str):
    exercises = []
    with open(lesson_file, 'r') as f:
        data = f.read()
    exercise_data = data.split('---')
    for exercise in exercise_data:
        ex = split_exercise(exercise)
        print(ex)
        exercises.append(ex)
    return exercises

if __name__ == "__main__":
    import_lesson('/Users/davidle/dev/tutorial/poly-all-desgin/data/content/arabic_course_v3/module__46/words:_كرّسَ,_تأثّرت,_أغنى_....txt')
    