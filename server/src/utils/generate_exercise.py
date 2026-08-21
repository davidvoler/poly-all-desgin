""" Generates exercise for a given sentences
What do we need to generate an exercise?
- Similar sentences - for the wrong options 
- Words for the wrong options 
Where do we get that from?
- Content DB
- Sentences in the course/module 
- AI generate - We can ask the AI to generate the wrong sentences for us 

# TODO:
- Implement the AI generation of wrong sentences and words
- Implement with corpus
"""
from gettext import translation

from models.edit.exercise import ExerciseEdit,ExerciseType
import random
from utils.ollama_simple import get_ollama_response
from utils.lang_utils import get_lang_name

async def get_distractors(lang, to_lang, sentence, translation, option_count=3) -> list[str]:
    prompt = f"""You are a language learning assistant. You are given a sentence in {get_lang_name(lang)} and its translation in {get_lang_name(to_lang)}. 
Your task is to generate {option_count} distractor sentences that are similar in meaning but incorrect. 
The distractors should be plausible and grammatically correct, but they should not convey the same meaning as the original sentence.
Here is the sentence: "{sentence}"
Here is the translation: "{translation}"
Please provide the distractor sentences in a JSON array."""
    response = await get_ollama_response(prompt)
    return response


async def get_distractors_words(lang, to_lang, sentence, words, option_count=3) -> list[str]:
    return []  

async def generate_exercise(lang, to_lang, sentence:str, translation:list[str], exercise_type: ExerciseType|None=None) -> ExerciseEdit:
    if exercise_type is None:
        exercise_type = ExerciseType.SINGLE_CHOICE  
    option_sentences = await get_distractors(lang, to_lang, sentence, translation, option_count=3)
    if exercise_type == ExerciseType.SINGLE_CHOICE:
        return ExerciseEdit(
            exercise_type=exercise_type,
            sentence=sentence,
            options=options,
            answer=sentence
        )
    if exercise_type == ExerciseType.MULTIPLE_CHOICE:
        if len(translation) < 2:
            # Create a single choice exercise instead
            pass

    if exercise_type == ExerciseType.IDENTIFY_WORDS:
        # Identify words exercise
        wrong_words = await get_distractors_words(lang, to_lang, sentence, [], option_count=5)
        pass


def gen_identify_words():
    pass
def gen_single_choice_exercise():
    pass
def gen_description_exercise():
    pass
def gen_multiple_choice_exercise():
    pass
def gen_reading_exercise():
    pass



def gen_exercise_by_type(lang, to_lang, sentence:str, translation:list[str], exercise_type: ExerciseType|None=None) -> ExerciseEdit:
    if exercise_type is None:
        exercise_type = ExerciseType.SINGLE_CHOICE  
    if exercise_type == ExerciseType.SINGLE_CHOICE:
        return ExerciseEdit(
            exercise_type=exercise_type,
            sentence=sentence,
            options=translation,
            answer=translation[0]