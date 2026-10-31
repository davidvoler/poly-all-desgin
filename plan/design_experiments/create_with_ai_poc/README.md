# Create with AI — chat POC (design prototype)

Static HTML/CSS/JS prototype for the "Create with AI" course-building
experience. Same dark-blue glass visual language as
[school_dashboard](../school_dashboard) — tokens mirror
`poliglots_app/lib/theme.dart` where possible.

This explores the **purpose-built chat** idea from
[TASKS.md](../../../TASKS.md): not a general ask-me-anything box, but a
guided copilot whose replies are mostly quick-action buttons (mirroring the
real `PromptResponse.options` shape in
[server/src/models/edit/generate_poc.py](../../../server/src/models/edit/generate_poc.py)),
with a free-text box as a secondary way to steer it.

## What it covers

- **`index.html`** — "My courses": every course you've started with the AI
  copilot, with a progress summary, plus a bare-bones create form (learning
  language, student language, level, optional title — **no prompt**, per
  the task).
- **`course.html`** — the course workspace, once a course exists. Two panes:
  - **Left (40% width)** — a "← My courses" link back to the list, and four
    tabs:
    - **Words** — the course's word bank as chips (add/remove manually).
      Words already picked into a lesson show a ✓ and dim, so you can see
      what's already been used at a glance.
    - **Lessons** — grouped under **modules** (see below). Only the module
      and lesson currently being worked on expand; everything else
      collapses to its title + status pill. Sentences default to read-only
      with a pencil-icon edit toggle; exercises are fully editable
      (prompt/options/correct answer) and can also be added manually via
      "+ Add exercise", not just AI-generated.
    - **Edit Course** — course-level stats (words / modules / lessons /
      exercises) plus the settings form (title, learning language, student
      language, level).
    - **Preview** — a read-only student-facing render of the course.
  - **Right** — the chat. The assistant drives the flow with action
    buttons (Create word list → Select words for a lesson → Create
    sentences *or* jump straight to exercises → …), each one a mocked
    stand-in for a `/generate_poc/*` call, tagged with a fake token/cost
    usage line (mirrors `PromptResponse.actual_tokens`/`actual_cost`) — a
    running total sits in the chat header. A "Preview course" action jumps
    the left pane straight to the Preview tab; a "Start a new module"
    action is how a course grows past one module.

Lessons belong to **modules** (`course.modules`, each holding an ordered
`lessonIds`-style grouping via `lesson.moduleId`). The word picker shown
when starting a lesson sorts not-yet-used words first and pre-checks them
("next words to teach"); words already used elsewhere are still selectable
but shown dimmed and unchecked.

## What's fake

Everything. There is no backend call — `assets/store.js` generates words/
sentences/exercises from a small curated vocabulary (real, correct
Japanese/Hebrew/Spanish A1 content) and falls back to obviously-labelled
placeholder text for any other language typed into the create form. State
persists in `localStorage` per browser (key `poc_create_with_ai_courses_v1`)
so "switch courses and continue where you left off" actually works across
reloads — clear it (or your browser's site data) to reset the two seeded
demo courses.

## Preview

```sh
cd plan/design_experiments/create_with_ai_poc
python3 -m http.server 8080
# → http://localhost:8080
```

## What's intentionally not here

- Real AI generation, or any network call.
- Free-text chat steering — the input box exists (and is on the state
  machine's roadmap) but doesn't change what gets generated yet.
- A course switcher inside `course.html` — deliberately dropped in favor of
  the "← My courses" link; switching courses means going back to the list.
- Any student-facing app chrome beyond the Preview tab — this is the
  editor/copilot side only.

When this direction is approved, the next step is wiring the chat's
action buttons to the real `/api/v1/generate_poc/*` endpoints (see
[TASKS.md](../../../TASKS.md)) instead of the mock generators here.
