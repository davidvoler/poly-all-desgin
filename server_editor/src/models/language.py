from pydantic import BaseModel, Field



class Language(BaseModel):
    code: str = Field('', description="The ISO 639-1 code of the language")
    name: str = Field('', description="The name of the language in the requested UI language")
    native_name: str = Field('', description="The native name of the language")
    weight: int = Field(0, description="The weight of the language for ordering purposes")


