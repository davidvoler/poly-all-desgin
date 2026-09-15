import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from taskiq import Context, TaskiqDepends
from taskiq_redis import ListQueueBroker, RedisAsyncResultBackend

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = os.getenv("REDIS_PORT", "6379")
REDIS_URL = f"redis://{REDIS_HOST}:{REDIS_PORT}/0"

# Result backend only does quick EXISTS/GET calls, so a read timeout is fine here.
result_backend = RedisAsyncResultBackend(
    redis_url=REDIS_URL,
    socket_connect_timeout=30.0,
)
broker = ListQueueBroker(
    url=REDIS_URL,
    socket_connect_timeout=30.0,
    socket_timeout=None,
).with_result_backend(result_backend)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure broker connection starts on app boot
    if not broker.is_worker_process:
        await broker.startup()
    yield
    # Ensure connections cleanly close on shutdown
    if not broker.is_worker_process:
        await broker.shutdown()




