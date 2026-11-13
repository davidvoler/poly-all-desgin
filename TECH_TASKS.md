# Tech Tasks 

## Architecture

Stream is used for waiting longer for an answer and closing it when all data is done

WebSocket provides dual sided communication
you need to keep the connection open , could be an issue with mobile app , and manage the logic  of what message belongs to which user

WebSocket IO is a client and server protocol with a lot of extra features, like managing reconnection, rooms and other features. 
it is has common clients and server libraries 

currently I need only the Stream

When would I need more than that?
Maybe when I want co-editing - or co learning in this case I want the message to reach more than one user 
I want a mirror of the data sent to both users and I want them to communicate while learning 


### Stream, WS, or Websocket.io 

- [] Consider using Web Socket to replace polling 
      - [] if we use WS do we still need a worker?
      - [] No worker - We just run an async 

Workers with WebSocket 
1. Workers is good for stability and scale 
2. WebSoket is also good for stability, ans scale to save time on polling 


The process
 - Prompt 
 - run worker
 - worker updates the

 here is an alternative offered by Gemini using SSE
Server-Sent Events

```python
import asyncio
import redis.asyncio as redis
from fastapi import FastAPI, Depends, HTTPException
from sse_starlette.sse import EventSourceResponse

app = FastAPI()

@app.get("/events")
async def user_event_stream(user = Depends(get_current_user)):
    # Subscription check right at the door
    if not user.has_active_subscription:
        raise HTTPException(status_code=403, detail="Active subscription required")
    async def event_generator():
        r = redis.from_url("redis://localhost:6379")
        pubsub = r.pubsub()
        await pubsub.subscribe(f"user:{user.id}:events")
        try:
            async for message in pubsub.listen():
                if message["type"] == "message":
                    yield {
                        "event": "task_update",
                        "data": message["data"].decode("utf-8"),
                    }
        finally:
            await pubsub.unsubscribe(f"user:{user.id}:events")
            await r.aclose()
    return EventSourceResponse(event_generator())

@broker.task
async def process_heavy_job(user_id: str, job_id: str):
    r = redis.from_url("redis://localhost:6379")
    # ... do heavy work ...
    await r.publish(
        f"user:{user_id}:events",
        json.dumps({"job_id": job_id, "status": "completed"})
    )
    await r.aclose()
```


```dart
final response = await dio.get<ResponseBody>(
  'https://api.example.com/events',
  options: Options(
    responseType: ResponseType.stream,
    headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
    receiveTimeout: null, // also override per request in case BaseOptions sets one
  ),
);
```