import asyncio
from ollama import AsyncClient
import os

ollama_host = os.environ.get("OLLAMA_HOST", "http://host.docker.internal:11434")

async def get_ollama_response(prompt: str, model: str = "lamma3", role="user") -> str:
    client = AsyncClient(host=ollama_host)
    response = await client.chat(
        model=model,
        messages=[{"role": role, "content": prompt}],
    )
    # print(response)
    print(response["message"]["content"])
    return response["message"]["content"]