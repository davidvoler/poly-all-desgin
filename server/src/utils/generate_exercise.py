from models.edit.exercise import ExerciseEdit,ExerciseType, Options
import random

def gen_identify_words(sentence, words, distractors_words):
    #verify distractors not in sentences
    words_not_in_sentence = [w for w in distractors_words if w not in sentence]
    #verify words are in the sentence
    words_in_sentence = [w for w in words if w in sentence]
    correct_words_count = random.randint(1,len(words_in_sentence))
    incorrect_words_count = 6 - correct_words_count
    random.shuffle(words_in_sentence)
    random.shuffle(words_not_in_sentence)
    options = []
    for w in words_in_sentence[:correct_words_count]:
        options.append(Options(text=w, correct=True))
    for w in words_not_in_sentence[:incorrect_words_count]:
        options.append(Options(text=w, correct=False))
    random.shuffle(options)
    exercise = ExerciseEdit(
        exercise_id=0,
        exercise_type=ExerciseType.IDENTIFY_WORDS,
        sentence=sentence,
        options=options
    )
    return exercise

def gen_single_choice_exercise(sentence, to_sentence, options):
    e_options = [Options(text=o, correct=False) for o in options]
    e_options.append(Options(text=to_sentence, correct=True))
    random.shuffle(e_options)
    exercise = ExerciseEdit(
        exercise_id=0,
        exercise_type=ExerciseType.SINGLE_CHOICE,
        sentence=sentence,
        options=e_options,
        answer=to_sentence,
    )
    return exercise
def gen_description_exercise():
    pass
def gen_multiple_choice_exercise():
    pass
