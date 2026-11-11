from pydantic import BaseModel, Field

class Word(BaseModel):
    text: str = Field(..., description="The word.")
    used: bool = Field(..., description="Indicates whether the word has been used.")
    translation: str = Field("", description="Translation target word to student language.")
   
   
class WordTranslation(BaseModel):
    word: str = Field(description="A word in the target language.")
    translation: str = Field(description="Translation target word to student language.")

class WordTranslationList(BaseModel):
    words_translations: list[WordTranslation] = Field(description="A list of generated words and their translations.")
