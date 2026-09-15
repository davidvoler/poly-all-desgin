"""
"""
from taskiq import Context, TaskiqDepends
from task_runner import broker
from models.tasks import TaskResults



def _get_words_from_ai(lang, to_lang, count, words_used):
    pass

def _get_quizzes_from_corpus_or_cache(lang, to_lang, count, words_used):
    pass

def verify_words(words:list, lang, to_lang)->tuple[list[str], list[str]]:
    return words, []

def _save_words_to_db(words: list[str], course_id, module_id):
    pass


@broker.task
async def generate_words_ai(
    lang,
    to_lang,
    course_id,
    module_id,
    words_used: list[str],
    count: int,
    context: Context = TaskiqDepends(),
)->TaskResults:
    """Generate quiz with AI - returns TaskResults containing the results and any errors.
    """
    results = TaskResults()
    words = _get_words_from_ai(lang,to_lang, count, words_used)
    verified_words, error_words = verify_words(words, lang, to_lang)
    _save_words_to_db(verified_words, course_id, module_id)
    results.results.extend(verified_words)
    results.errors.extend(error_words)
    return results

    