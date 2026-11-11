from models.prompts import (
    PromptRequest,
    PromptOption,
    PromptActionType,
    PromptResponse,
    PromptType,
)   
from utils.prompt_utils import save_prompt_request, save_prompt_response
from utils.course_utils import get_course
from utils.words_utils import save_words
from prompts.vocabulary import prompt_suggested_words
async def _identify_prompt_type(prompt_request: PromptRequest) -> PromptType:
    if prompt_request.prompt_type:
        return prompt_request.prompt_type
    return None


async def _process_prompt_request(prompt_request: PromptRequest, prompt_type: PromptType) -> PromptResponse:
    # Implement the logic to process the prompt request based on the identified prompt type
    match(prompt_type):

        case PromptType.VOCABULARY_SUGGEST_WORDS:
            course = await get_course(prompt_request.course_id)
            words_list = await prompt_suggested_words(
                lang=course.lang,
                to_lang=course.to_lang,
                level=course.level,
                provider=prompt_request.provider,
                model=prompt_request.model,
            )
            #save words
            await save_words(lang=course.lang,
                            to_lang=course.to_lang,
                course_id=prompt_request.course_id,
                module_id=prompt_request.module_id,
                words=words_list.words_translations,
            )
            response = PromptResponse(
                request_user_message=prompt_request.user_message,
                results=words_list.model_dump(),
                prompt_action_type=PromptActionType.ASK_AI,
                course_id=prompt_request.course_id,
                module_id=prompt_request.module_id,
                lesson_id=prompt_request.lesson_id,
                prompt_type=prompt_request.prompt_type,
            )
            await save_prompt_response(response)
            return response
        case _:
            # Handle unknown prompt type
            pass



async def _offer_options(prompt_request: PromptRequest) -> PromptResponse:
    # Implement the logic to offer options to the user based on the prompt request
    pass


async def handle_prompt_vocabulary_request(prompt_request: PromptRequest) -> PromptResponse:
    prompt_type = await _identify_prompt_type(prompt_request)
    # Implement the logic to handle the prompt request based on the identified prompt type
    if not prompt_type:
        # await save_prompt_request(prompt_request)
        return await _offer_options(prompt_request)
    else:
        # await save_prompt_request(prompt_request)
        return await _process_prompt_request(prompt_request, prompt_type)








