from click import prompt
from ollama import AsyncClient
import os
import hashlib


ollama_host = os.environ.get("OLLAMA_HOST", "http://host.docker.internal:11434")

ollama_client = AsyncClient(host=ollama_host)


async def get_ollama_response(prompt: str, model: str = "lamma3", role="user") -> str:
    response = await ollama_client.chat(
        model=model,
        messages=[{"role": role, "content": prompt}],
          
    )
    # print(response)
    print(response["message"]["content"])
    return response["message"]["content"]



async def get_ollama_response_system(system_prompt: str, user_prompt: str, model: str, response_model=None) -> str:
    kwargs = {}
    if response_model is not None:
        # Grammar-constrained decoding to the model's JSON schema — keeps the
        # shape valid even when the model would otherwise add prose/fences.
        kwargs["format"] = response_model.model_json_schema()
    response = await ollama_client.chat(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}

        ],
        options={"temperature": 0.1},
        **kwargs,
    )
    print(response["message"]["content"])
    return response["message"]["content"]
