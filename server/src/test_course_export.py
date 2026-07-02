import asyncio
from utils.course_export_from_db import export_course_from_db
from utils.course_import_to_db import course_to_db
import time


if __name__ == "__main__":
    start_time = time.time()
    asyncio.run(course_to_db("../../data/content/exported_course_from_db.yaml", users_id=1, school_id=1))
    end_time = time.time()
    print(f"Execution time: {end_time - start_time} seconds")