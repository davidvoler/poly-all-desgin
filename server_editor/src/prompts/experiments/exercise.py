from typing import Any
from pydantic import BaseModel, Field
from pydantic_ai import Agent


# 1. Output Schemas (What the LLM should return)
class SingleChoice(BaseModel):
    sentence: str = Field(description="The target sentence containing a blank or question context.")
    incorrect_options: list[str] = Field(description="List of 3 plausible but incorrect options for the user to choose from.")
    translation: str = Field(description="Native translation of the full target sentence.")

class SingleChoiceList(BaseModel):
    questions: list[SingleChoice] = Field( description="A list of generated single-choice questions.")

class SentenceTranslation(BaseModel):
    sentence: str = Field(description="The original target sentence.")
    translation: str = Field(description="The translation of the sentence.")

# 2. Prompt Configuration Model
class SingleChoicePromptConfig(BaseModel):
    prompt_template: str = ("Please create {num_sentences} single-choice questions for the word: '{word}'.")
    # Store schema as a dictionary (for APIs like OpenAI/Instructor)
    response_schema: dict[str, Any] = Field(default_factory=SingleChoiceList.model_json_schema)
    def render_prompt(self, word: str, num_sentences: int) -> str:
        """Helper method to fill template placeholders safely."""
        return self.prompt_template.format(word=word, num_sentences=num_sentences)



async def get_single_choice(word: str, num_sentences: int=4, model: str='ollama:llama3.1') -> SingleChoiceList:
    prompts_config = SingleChoicePromptConfig()
    prompt = prompts_config.render_prompt(word, num_sentences)
    agent = Agent(
        model, 
        result_type=SingleChoiceList,
        system_prompt="You are an expert language teacher."
    )
    result = await agent.run(prompt)
    return result.data

