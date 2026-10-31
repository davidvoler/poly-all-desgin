import json
from utils.db import run_query, get_query_results
from models.prompts import (
    PromptRequest,
    PromptResponse,
)


async def get_last_responses(course_id: int, module_id: int = 0, limit: int = 50):
    where_module = ''
    if module_id > 0:
        where_module = 'AND module_id = %s'
    sql = f"""SELECT * FROM course.prompt_response
             WHERE course_id = %s 
             {where_module}
             ORDER BY created_at DESC
             LIMIT %s"""
    if module_id > 0:
        values = (course_id, module_id, limit)
    else:
        values = (course_id, limit)
    return await get_query_results(sql, values)




async def save_prompt_response(prompt_response: PromptResponse)->int|None:
    sql = """INSERT INTO course.prompt_response (
        course_id,
        module_id,
        lesson_id,
        request_user_message,
        options,
        results,
        results_type,
        ui_chat_response,
        prompt_router_type,
        prompt_type,
        prompt_action_type
    ) VALUES (
        %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        RETURNING prompt_response_id
    """
    def enum_value(e):
        return e.value if e else None
    values = (
        prompt_response.course_id,
        prompt_response.module_id,
        prompt_response.lesson_id,
        prompt_response.request_user_message,
        json.dumps([o.model_dump(mode="json") for o in prompt_response.option or []]),
        json.dumps(prompt_response.results or {}),
        prompt_response.results_type,
        json.dumps(prompt_response.ui_chat_response or {}),
        enum_value(prompt_response.prompt_router_type),
        enum_value(prompt_response.prompt_type),
        enum_value(prompt_response.prompt_action_type),
    )
    res = await get_query_results(sql, values)
    return res[0]['prompt_response_id'] if res else None

async def save_prompt_request(prompt_request: PromptRequest) -> int|None:
    sql = """ INSERT INTO course.prompt_request (
        course_id,
        module_id,
        lesson_id,
        user_message,
        provider,
        model
    ) VALUES (
        %s,%s,%s,%s,%s,%s)
    RETURNING prompt_request_id
    """
    values = (
        prompt_request.course_id,
        prompt_request.module_id,
        prompt_request.lesson_id,
        prompt_request.user_message,
        prompt_request.provider,
        prompt_request.model,
    )
    # Execute the SQL statement with the values using your database connection
    res = await get_query_results(sql, values)
    return res[0]['prompt_request_id'] if res else None
