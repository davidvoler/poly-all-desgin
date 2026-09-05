# main.py
from contextlib import asynccontextmanager
from arq import create_pool
from arq.connections import RedisSettings
from arq.jobs import Job
from fastapi import FastAPI, HTTPException


@asynccontextmanager
async def lifespan(app: FastAPI):
  # Startup: Initialize the Redis connection pool
  app.state.redis = await create_pool(RedisSettings(host="localhost", port=6379))
  yield
  # Shutdown: Close the Redis pool
  await app.state.redis.close()

