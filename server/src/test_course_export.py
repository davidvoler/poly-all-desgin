import asyncio
from utils.course_export_from_db import export_course_from_db



if __name__ == "__main__":
    asyncio.run(export_course_from_db(38, "../../data/content/exported_course_from_db.yaml"))