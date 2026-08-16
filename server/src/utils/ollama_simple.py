import asyncio
from ollama import AsyncClient


async def get_ollama_response(prompt: str, model: str = "lamma3", role="user") -> str:
    client = AsyncClient(host="http://host.docker.internal:11434")
    response = await client.chat(
        model=model,
        messages=[{"role": role, "content": prompt}],
    )
    # print(response)
    print(response["message"]["content"])
    return response["message"]["content"]