import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from taskiq import Context
from taskiq_redis import ListQueueBroker, RedisAsyncResultBackend

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = os.getenv("REDIS_PORT", "6379")
REDIS_URL = f"redis://{REDIS_HOST}:{REDIS_PORT}/0"

# Result backend handles static reads/writes, so connect_timeout is safe here
result_backend = RedisAsyncResultBackend(
    redis_url=REDIS_URL,
    socket_connect_timeout=10.0,
)

# DO NOT pass socket_timeout to ListQueueBroker — it breaks long-polling Pub/Sub loops
broker = ListQueueBroker(
    url=REDIS_URL,
    socket_connect_timeout=10.0,
).with_result_backend(result_backend)


@broker.task
async def process_data(
    item_id: int, 
    context: Context,
) -> str:
    task_id = context.message.task_id
    print(f"Executing task {task_id} for item {item_id}")
    return task_id


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure broker connection starts on app boot
    if not broker.is_worker_process:
        await broker.startup()
    yield
    # Ensure connections cleanly close on shutdown
    if not broker.is_worker_process:
        await broker.shutdown()


# MUST pass lifespan to FastAPI instance
app = FastAPI(lifespan=lifespan)


@app.post("/items/{item_id}")
async def trigger_task(item_id: int):
    task = await process_data.kiq(item_id)
    return {"task_id": task.task_id}