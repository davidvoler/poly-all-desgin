import asyncio
from utils.course_export_from_db import export_course_from_db
import time


if __name__ == "__main__":
    start_time = time.time()
    asyncio.run(export_course_from_db(38, "../../data/content/exported_course_from_db.yaml"))
    end_time = time.time()
    print(f"Execution time: {end_time - start_time} seconds")