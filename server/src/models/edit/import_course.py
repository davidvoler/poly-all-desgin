from pydantic import BaseModel

class ImportCourseRequest(BaseModel):
    course_id: int
    revision_id: int
    user_id: int
    school_id: int

class ImportRevisionRequest(BaseModel):
    course_id: int
    revision_id: int
    user_id: int
    school_id: int
