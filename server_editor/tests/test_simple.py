import asyncio
import os, sys
sys.path.append('../src/')
from  prompts.vocabulary import prompt_suggested_words

os.environ["OLLAMA_BASE_URL"] = "http://localhost:11434/v1"
async def test_prompt_suggested_words():
    result = await prompt_suggested_words("he", "ar", 'B2')
    print(result)

if __name__ == "__main__":
    asyncio.run(test_prompt_suggested_words())
