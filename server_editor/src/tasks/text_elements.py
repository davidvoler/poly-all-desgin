from pydantic import BaseModel
from prompts.single_choice import SingleChoiceList, SingleChoicePrompt, get_single_choice
from models.exercise import Exercise
from models.generate import QuizRequest

async def get_quiz_cache(quiz_request: QuizRequest)->SingleChoiceList:
    return SingleChoiceList(questions=[])

async def save_exercise(exercises: list[Exercise]):
    pass

async def generate_single_choice_quiz(quiz_request: QuizRequest):
    #Get from cache first
    number_of_questions = quiz_request.number_of_questions
    if quiz_request.cache:
        cached_quiz_list:SingleChoiceList = await get_quiz_cache(quiz_request)
        number_of_questions = quiz_request.number_of_questions - len(cached_quiz_list)
    if number_of_questions > 0:
        ai_quiz_list:SingleChoiceList  = await get_single_choice(
            word=quiz_request.word,
            number_of_questions=number_of_questions,
            provider=quiz_request.provider,
            model=quiz_request.model)
    #3. save the verified quiz to the database
    quizzes = cached_quiz_list.questions + ai_quiz_list.questions if quiz_request.cache else ai_quiz_list.questions
    exercises = []
    for quiz in quizzes:
        options = [{"text": option} for option in quiz.incorrect_options] + [{"text": quiz.translation, "correct":True}]
        exercise = Exercise(
            course_id=quiz_request.course_id,
            module_id=quiz_request.module_id,
            lesson_id=quiz_request.lesson_id,
            question=quiz.sentence,
            choices=options,
            correct_answer=quiz.translation
        )
        exercises.append(exercise)
    await save_exercise(exercises)
    #4. return results - what format
    return exercises

