from models.exercise import Exercise
from models.prompts import (
    PromptRequest,
    PromptActionType,
    PromptResponse,
    PromptRouterType,
    PromptType,
)
from prompts.single_choice import WRONG_TRANSLATIONS, get_fill_in_blank_for_words, get_single_choice_for_words
from utils.context_options import context_stats, EXERCISES_PER_REQUEST, EXERCISES_PER_WORD
from utils.course_utils import get_course
from utils.exercise_utils import create_exercise, get_options
from utils.prompt_utils import save_prompt_response


def _translation_choices(common: dict, questions) -> list[Exercise]:
    """The sentence in the learned language; the options are its translations, in random
    order. sentence_alt1-3 stay empty for now."""
    return [Exercise(**common, word=q.word, question=q.sentence, sentence=q.sentence, answer=q.translation,
                     options=get_options([q.translation], q.incorrect_translations[:WRONG_TRANSLATIONS]))
            for q in questions]


async def _generate(prompt_request: PromptRequest, exercise_type: PromptType, words: list[str],
                    course, context) -> list[Exercise]:
    """Exercises of exercise_type for words, one per word, as the AI wrote them."""
    kwargs = dict(lang=course.lang, to_lang=course.to_lang, level=course.level,
                  provider=prompt_request.provider, model=prompt_request.model)
    common = dict(course_id=context.course_id, module_id=context.module_id, lesson_id=context.lesson_id,
                  exercise_type=exercise_type.value)
    if exercise_type == PromptType.EXERCISE_FILL_IN_THE_BLANK:
        generated = (await get_fill_in_blank_for_words(words, **kwargs)).exercises
        return [Exercise(**common, word=g.word, question=g.sentence, answer=g.word,
                         options=get_options([g.word], g.incorrect_options[:3]),
                         sentence_alt1=g.translation)
                for g in generated]
    if exercise_type == PromptType.EXERCISE_SINGLE_CHOICE:
        return _translation_choices(common, (await get_single_choice_for_words(words, **kwargs)).questions)

    if exercise_type == PromptType.EXERCISE_MULTIPLE_CHOICE:
        return _translation_choices(common, (await get_single_choice_for_words(words, **kwargs)).questions)

async def _create_exercises(prompt_request: PromptRequest, exercise_type: PromptType) -> PromptResponse:
    """Turns the module's unused words into exercises in the current lesson."""
    stats = await context_stats(prompt_request.course_id)
    context = stats.context
    count = min(EXERCISES_PER_REQUEST, stats.words_that_fit)
    # Single choice makes EXERCISES_PER_WORD steps per word; the other types one.
    per_word = EXERCISES_PER_WORD if exercise_type == PromptType.EXERCISE_SINGLE_CHOICE else 1
    # The words the picked option names, else the first unused ones.
    requested = [str(w) for w in prompt_request.prompt_values or []]
    words = [w for w in requested if w in stats.unused_words][:count] if requested else stats.unused_words[:count]
    created = []
    if words:
        course = await get_course(context.course_id)
        # Keep per_word exercises for each requested word, in the order the model wrote
        # them; it may repeat or invent words.
        generated = await _generate(prompt_request, exercise_type, words, course, context)
        for word in words:
            for e in [e for e in generated if e.word.strip().lower() == word.lower()][:per_word]:
                e.word = word
                created.append(await create_exercise(e))
    message = (f"Created {len(created)} exercises." if created
               else "There are no unused words to make exercises for." if not words
               else "The AI did not return usable exercises; try again.")
    response = PromptResponse(
        request_user_message=prompt_request.user_message,
        course_id=context.course_id, module_id=context.module_id, lesson_id=context.lesson_id,
        results={"exercises": [
            {"word": e.word, "question": e.question, "answer": e.answer,
             "wrong_options": ", ".join(option.text for option in e.options or [] if not option.correct),
             # Single choice: the answer is the translation; fill in the blank keeps it in sentence_alt1.
             "translation": e.sentence_alt1 or e.answer}
            for e in created
        ]} if created else {},
        ui_chat_response={"message": message},
        prompt_router_type=PromptRouterType.EXERCISE,
        prompt_type=exercise_type,
        prompt_action_type=PromptActionType.ASK_AI,
    )
    await save_prompt_response(response)
    return response


async def handle_prompt_exercise_request(prompt_request: PromptRequest) -> PromptResponse:
    # Single choice unless fill in the blank is asked for; the other types are not generated yet.
    exercise_type = (PromptType.EXERCISE_SINGLE_CHOICE
                     if prompt_request.prompt_type == PromptType.EXERCISE_SINGLE_CHOICE
                     else PromptType.EXERCISE_SINGLE_CHOICE)
    return await _create_exercises(prompt_request, exercise_type)
