"""
This example is returning the distractors in Spanish
We have to work on it further but the idea is good
"""

from pydantic import BaseModel, Field
import ollama

class QuizItem(BaseModel):
    sentence: str = Field(description="The source language sentence")
    translation: str = Field(description="The correct translation")
    distractor_literal: str = Field(description="Literal word swap or false friend error")
    distractor_grammar: str = Field(description="Tense, aspect, or subject swap error")
    distractor_opposite: str = Field(description="Plausible opposite or distinct meaning error")

class QuizResponse(BaseModel):
    quiz: list[QuizItem]


SYSTEM_PROMPT = """
You are an expert language teacher creating quiz items.
Create 3 sentences in Spanish appropriate for a B1 learner with the target word and provide the correct English translation.

For EACH sentence, create 3 distractors that follow these SPECIFIC strategies:
- distractor_literal: A translation that takes words too literally or confuses a false friend.
- distractor_grammar: Uses the right vocabulary, but changes the tense, pronoun, or grammatical structure.
- distractor_opposite: Replaces key terms to create an opposite or completely different meaning.

### EXAMPLE INPUT:
Target word: 'embarazada'

### EXAMPLE OUTPUT:
Sentence: "Ella está embarazada de cuatro meses."
Translation: "She is four months pregnant."
Distractors:
- distractor_literal: "She is embarrassed for four months." (False friend error)
- distractor_grammar: "They will be four months pregnant." (Pronoun & tense shift)
- distractor_opposite: "She has been feeling sick for four months." (Different context entirely)
""".strip()


def generate_varied_quiz(word: str) -> QuizResponse:
    response = ollama.chat(
        model="gemma4",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"Target word: '{word}'"}
        ],
        format=QuizResponse.model_json_schema(),
        # Slightly increasing temperature (0.5 to 0.7) adds natural variability across categories
        options={"temperature": 0.6}
    )
    
    return QuizResponse.model_validate_json(response.message.content)

result = generate_varied_quiz("aliento")

# Fully typed output with IDE completion:
for item in result.quiz:
    print(item)