# Polyglots API

FastAPI server for the Polyglots Flutter client.

We have a single server now that serves both poliglots_app and dashboard

## Run

```bash
docker compose up -d
```

OpenAPI docs: <http://localhost:8004/docs>

## Endpoints

| Method | Path                        | Returns                                |
|--------|-----------------------------|----------------------------------------|
| GET    | `/health`                   | `{"status": "ok"}`                     |
| GET    | `/courses`                  | `CourseSummary[]` — list view          |
| GET    | `/courses/{course_id}`      | `CourseDetail` — modules + lessons     |

`/courses` accepts optional `?source=` and `?target=` query params (e.g. `?source=en&target=ja`) to filter by language pair.

## Quick smoke check

```bash
curl -s http://localhost:8000/courses | jq '.[].title'
curl -s http://localhost:8000/courses/japanese-beginners | jq '.modules[].name'
```
