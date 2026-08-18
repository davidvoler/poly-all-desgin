""" Generates exercise for a given sentences
What do we need to generate an exercise?
- Similar sentences - for the wrong options 
- Words for the wrong options 
Where do we get that from?
- Content DB
- Sentences in the course/module 
- AI generate - We can ask the AI to generate the wrong sentences for us  
"""
from models.edit.exercise import ExerciseEdit,ExerciseType
import random

async def get_wrong_options(lang, to_lang, sentence, words, option_count=3) -> list[str]:
    return []  


async def get_wrong_words(lang, to_lang, sentence, words, option_count=3) -> list[str]:
    return []  

async def generate_exercise(lang, to_lang, sentence:str, translation:list[str], exercise_type: ExerciseType|None=None) -> ExerciseEdit:
    if exercise_type is None:
        exercise_type = ExerciseType.SINGLE_CHOICE  
    option_sentences = await get_wring_options(lang, to_lang, sentence, [], option_count=3)
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
        wrong_words = await get_wrong_words(lang, to_lang, sentence, [], option_count=5)
        pass

