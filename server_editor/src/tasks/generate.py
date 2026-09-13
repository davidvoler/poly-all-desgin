"""
"""
from taskiq import Context, TaskiqDepends
from task_runner import broker
from models.tasks import TaskResults



@broker.task
async def generate_words_with_ai(
    course_id,
    module_id,
    count: int,
    school_user: SchoolUser,
    context: Context = TaskiqDepends(),
) -> TaskResults:
    """Generate words with AI - 
    1. send the request to AI service
    2. receive the generated words
    3. save to db 
    4. return results or errors - in a format redable by the calling 
    """
    
@broker.task
async def generate_quiz_with_ai(
    course_id,
    module_id,
    count: int,
    word: str,
    school_user: SchoolUser,
    context: Context = TaskiqDepends(),
)->TaskResults:
    """Generate quiz with AI - 
    """
    return []



@broker.task
async def generate_quiz_from_db_or_ai(
    course_id,
    module_id,
    count: int,
    word: str,
    school_user: SchoolUser,
    context: Context = TaskiqDepends(),
):
    """Generate quiz from DB or AI - 
    """
    return []


