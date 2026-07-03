from pydantic import BaseModel

class CoursePermission(BaseModel):
    course_id: int
    edit: bool = False
    delete: bool = False
    view: bool = True
    review: bool = False
    publish: bool = False
    import_revision: bool = False
    export_revision: bool = False
    
class SchoolUserPermission(BaseModel):
    school_id: int
    import_course: bool = False
    export_course: bool = False
        
