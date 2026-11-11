from pydantic import BaseModel, Field


class Sentence(BaseModel):
    sentence_id: int = Field(..., description="The ID of the sentence.")
    lesson_id: int | None = Field(None, description="The lesson (video part) the sentence comes from.")
    sentence: str = Field(..., description="The sentence in the learned language.")
    translation: str = Field("", description="Translation of the sentence in the student's language.")
    used: bool = Field(False, description="Whether an exercise in the module asks this sentence.")
