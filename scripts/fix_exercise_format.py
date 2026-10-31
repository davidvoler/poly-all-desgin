from utils.db import get_query_results, run_query
import asyncio
import json

async def fix_exercise_format(course_id):
    sql = """select * from course_simple.exercise where course_id = %s"""
    params = (course_id,)   
    res = await get_query_results(sql, params)
    for e in res:
        options = e.get("options")
        answer = e.get("answer")
        corrected_options = [{"text": o, "correct": o == answer} for o in options]
        update_sql = """update course_simple.exercise 
                        set options = %s,
                        exercise_type = %s
                        where exercise_id = %s"""
        update_params = (json.dumps(corrected_options),'simple', e.get("exercise_id"))
        await run_query(update_sql, update_params)

asyncio.run(fix_exercise_format(89))