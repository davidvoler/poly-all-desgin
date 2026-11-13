import json
from datetime import datetime

from pydantic import BaseModel, Field



class CourseOption(BaseModel):
    extra_system_prompt: str|None = Field(..., description="Additional system prompt for all request related to the course.")
    target_language: str|None = Field(..., description="The target language for the course.")
    student_language: str|None = Field(..., description="The language spoken by the student.")
    level: str|None = Field(..., description="The level of the course.")
    target_audience: str|None = Field(..., description="The target audience for the course.")
    target_age_group: str|None = Field(..., description="The target age group for the course.")
    teaching_method: str|None = Field(..., description="The teaching method used for the course.")
    learning_objectives: str|None = Field(..., description="The learning objectives for the course.")



class Course(BaseModel):
    course_id: int | None = None
    school: str | None = None
    user_id: int | None = None
    lang: str | None = None
    to_lang: str | None = None
    level: str | None = None
    title: str | None = None
    description: str | None = None
    deleted: bool | None = False
    status: str | None = 'draft'  # draft, reviewed, published, archived
    course_options: dict|CourseOption|None = {}

    @property
    def diacritics(self) -> bool:
        """Whether exercises also keep the learned-language sentence with diacritics
        (course_options.diacritics), in sentence_alt1. sentence never has them."""
        options = self.course_options
        if isinstance(options, CourseOption):
            return False
        return bool((options or {}).get("diacritics"))

    @property
    def guidance(self) -> str | None:
        """The author's guidance for the course's AI prompts (course_options.extra_system_prompt)."""
        options = self.course_options
        if isinstance(options, CourseOption):
            return options.extra_system_prompt
        return (options or {}).get("extra_system_prompt")


