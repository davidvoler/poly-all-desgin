from pydantic import BaseModel

class Results(BaseModel):
    user_id: int 
    lang: str
    lesson_id: int
    module_id: int
    course_id: int
    word: str = ''
    sentence: str = ''
    #correct and timing values 




class UserData(BaseModel):
    user_id: int
    language: str
    to_lang: str
    