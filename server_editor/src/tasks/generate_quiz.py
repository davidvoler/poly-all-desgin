"""
"""
from server.src.models.edit.generate_poc import Course
from taskiq import Context, TaskiqDepends
from task_runner import broker
from models.tasks import TaskResults



def _get_quizzes_from_ai(lang, to_lang, count, word):
    pass

def _get_quizzes_from_corpus_or_cache(lang, to_lang, count, word):
    pass

def verify_quiz(quiz, lang, to_lang)->tuple[str, bool]:
    pass

def _save_exercise_to_db(quiz: dict, course_id, module_id, lesson_id):
    pass

def _save_sentences_to_db(quiz: dict):
    pass


@broker.task
async def generate_quiz_with_ai(
    lang,
    to_lang,
    course_id,
    module_id,
    lesson_id,
    count: int,
    word: str,
    context: Context = TaskiqDepends(),
)->TaskResults:
    """Generate quiz with AI - returns TaskResults containing the results and any errors.
    """
    results = TaskResults()
    quizzes = _get_quizzes_from_ai(lang,to_lang, count, word)
    for quiz in quizzes:
        error, verified = verify_quiz(quiz, lang, to_lang)
        if verified:
            exercise_id = _save_exercise_to_db(quiz, course_id, module_id,lesson_id)
            results.results.append(exercise_id)
            _save_sentences_to_db(quiz)
        else:
            results.errors.append(error)
    return results


@broker.task
async def generate_words_ai(
    lang,
    to_lang,
    course_id,
    module_id,
    count: int,
    context: Context = TaskiqDepends(),
)->TaskResults:
    """Generate quiz with AI - returns TaskResults containing the results and any errors.
    """
    results = TaskResults()
    quizzes = _get_quizzes_from_ai(lang,to_lang, count, word)
    for quiz in quizzes:
        error, verified = verify_quiz(quiz, lang, to_lang)
        if verified:
            exercise_id = _save_exercise_to_db(quiz, course_id, module_id,lesson_id)
            results.results.append(exercise_id)
            _save_sentences_to_db(quiz)
        else:
            results.errors.append(error)
    return results
