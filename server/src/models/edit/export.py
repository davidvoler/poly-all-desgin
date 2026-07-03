from pydantic import BaseModel

class ExportCourseRequest(BaseModel):
    school_id: int

class ExportRevisionRequest(BaseModel):
    course_id: int
    revision_id: int
    user_id: int
    school_id: int
