SYSTEM_PROMPT1 = """
You are an expert language teacher creating multiple-choice quiz items.
Create sentences in Spanish appropriate for a B1 learner using the target word, and translate them to English.

For EACH correct translation, generate 3 incorrect translations (distractors) using EXACTLY these three distinct categories:
1. "Literal/False Friend": Translate individual words literally while ruining the overall sentence meaning, or misinterpret a false friend.
2. "Tense/Grammar Swap": Keep the core vocabulary correct, but alter the subject, verb tense, or aspect (e.g., changing past to future, or "I" to "they").
3. "Plausible Opposite": State the opposite or a completely different logical outcome using appropriate B1 vocabulary.

Return ONLY valid data matching the required JSON schema.
""".strip()

SYSTEM_PROMPT2 = """
You are an expert language teacher creating quiz items.
Create 3 sentences in Spanish appropriate for a B1 learner with the provided target word and translate them into English.
Maximum length: 12 words per sentence.
Include 3 incorrect translations (distractors) per sentence: a mix of subtle errors and completely wrong options.
Return ONLY valid data adhering to the required JSON schema.
""".strip()

from pydantic import BaseModel
import ollama

# 1. Define the response schema using Pydantic
class QuizItem(BaseModel):
    sentence: str
    translation: str
    distractors: list[str]

class QuizResponse(BaseModel):
    quiz: list[QuizItem]


# 2. Store base instructions once as a SYSTEM prompt template



def generate_quiz_for_word(word: str) -> QuizResponse:
    # 3. Call Ollama passing the Pydantic schema in the `format` parameter
    response = ollama.chat(
        model="gemma4",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT1},
            {"role": "user", "content": f"Target word: '{word}'"}
        ],
        format=QuizResponse.model_json_schema(), # Enforces grammar-level JSON validation
        options={"temperature": 0.2}             # Low temperature ensures strict schema compliance
    )
    
    # 4. Parse raw response directly into your typed Pydantic object
    return QuizResponse.model_validate_json(response.message.content)


# --- Execution Example ---
result = generate_quiz_for_word("aliento")

# Fully typed output with IDE completion:
for item in result.quiz:
    print(f"Sentence:    {item.sentence}")
    print(f"Translation: {item.translation}")
    print(f"Distractors: {item.distractors}\n")