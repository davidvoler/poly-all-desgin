from models.prompts import (
    PromptActionType,
    PromptRequest,
    PromptOption,
    PromptResponse,
    PromptOptionData,
    PromptType,
    PromptRouterType,
)
from utils.prompt_utils import save_prompt_request
from utils.course_utils import create_course
from models.course import Course


async def _identify_prompt_type(prompt_request: PromptRequest) -> PromptType:
    if "create course" in prompt_request.message.lower():
        return PromptType.CREATE_COURSE
    if "create" in prompt_request.message.lower() and "course"  in prompt_request.message.lower():
        return PromptType.CREATE_COURSE
    if "attributes" in prompt_request.message.lower():
        return PromptType.COURSE_ATTRIBUTES
    return None


def _create_options(prompt_request: PromptRequest) -> list[PromptOption]:
    options = [
        PromptOption(
            label="Create a new Course",
            value="create_course"
        ),
        PromptOption(
            label="Change course attributes",
            value="course_attributes"
        ),
        PromptOption(
            label="View course details",
            value="course_missing_data",
            option_data=[
                PromptOptionData(
                    label="lang",
                    value="en"
                )
            ]
        )
    ]
    return options

async def _process_prompt_request(prompt_request: PromptRequest, course_type: PromptType) -> PromptResponse:
    # Implement the logic to process the prompt request based on the identified course type
    match(course_type):
        case PromptType.CREATE_COURSE:
            save_prompt_request(prompt_request)
            course = Course(
                lang="en",  # Replace with actual value from prompt_request
                to_lang="fr",  # Replace with actual value from prompt_request
                user_id=1,  # Replace with actual value from prompt_request
                school="Example School",  # Replace with actual value from prompt_request
                title="Example Course",  # Replace with actual value from prompt_request
                description="Example Description",  # Replace with actual value from prompt_request
                course_options={},  # Replace with actual value from prompt_request
                status="draft"  # Replace with actual value from prompt_request
            )
            return await create_course(course)
        case PromptType.COURSE_ATTRIBUTES:
            # Handle course attributes logic
            pass
        case _:
            # Handle unknown prompt type
            pass

async def _offer_options(prompt_request: PromptRequest) -> PromptResponse:
    # Implement the logic to offer options to the user based on the prompt request
    options = _create_options(prompt_request)
    return PromptResponse(
        message="Please choose an option:",
        options=options
    )


def default_course_options(course_id:int)->list[PromptOption]:
    return [
        # PromptOption(
        #     course_id=course_id,
        #     option_text="Create first module",
        #     router_type=PromptRouterType.MODULE,
        #     prompt_type=PromptType.MODULE_CREATE,
        #     comment="Create the first module for the course."
        # ),
        PromptOption(
            course_id=course_id,
            option_text="Suggest words",
            router_type=PromptRouterType.VOCABULARY,
            prompt_type=PromptType.VOCABULARY_SUGGEST_WORDS,
            comment="Create a module and, Suggest words for the module."
        ),
    ]

async def handle_prompt_course_request(prompt_request: PromptRequest) -> PromptResponse:
    # TODO: _identify_prompt_type is out of date with the models; re-enable once fixed
    # course_type = await _identify_prompt_type(prompt_request)
    # Implement the logic to handle the prompt request based on the identified prompt type
    return PromptResponse(
        prompt_request=prompt_request,
        course=prompt_request.course,
        module=None,
        course_id=prompt_request.course_id,
        module_id=None,
        lesson_id=None,
        option=None,
        task_id=None,
        results=None,
        results_type=None,
        ui_chat_response={"message": "creating a course"},
        prompt_router_type=PromptRouterType.COURSE,
        prompt_type=PromptType.COURSE_CREATE,
        prompt_action_type=None,
    )
    # if not course_type:
    #     return await _offer_options(prompt_request)
    # else:
    #     return await _process_prompt_request(prompt_request, course_type)




