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

# ListQueueBroker.listen() runs `BRPOP <queue> 0` — a read that blocks on the
# Redis server until a task arrives. redis-py 8.x injects a default
# socket_timeout of 5s even when you don't pass one (see `orig_socket_timeout`
# in the pool's connection_kwargs), so that blocking read raises
# `redis.exceptions.TimeoutError: Timeout reading from redis:6379` after 5s
# idle. listen() only catches ConnectionError, so the worker dies and taskiq
# restarts it in a ~5s crash loop. Passing socket_timeout=None explicitly
# overrides the injected default and lets BRPOP block as intended.
broker = ListQueueBroker(
    url=REDIS_URL,
    socket_connect_timeout=30.0,
    socket_timeout=None,
).with_result_backend(result_backend)


@broker.task
async def process_data(
    item_id: int,
    context: Context = TaskiqDepends(),
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




