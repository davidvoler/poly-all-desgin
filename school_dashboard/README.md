# Polyglots — School Dashboard (design prototype)

Static HTML/CSS prototype for the school-admin **web** dashboard.

Visual language matches the Polyglots app: dark-blue radial gradient,
frosted-glass surfaces, white-pill primary CTAs. Tokens mirror
[poliglots_app/lib/theme.dart](../poliglots_app/lib/theme.dart) where
possible (brand `#1E88E5`, blues `#1565C0` / `#0D47A1`, dark bg
`#0C0F1A`, pill radius `999px`, card radius `16px`).

## Scope of this pass

**Steady-state, single school**, with a separate **create-school** page
for first-run onboarding. The mocks assume one school already exists —
**Riverside Academy** — and show the populated admin screens:

| Page                   | Function                                       |
| ---------------------- | ---------------------------------------------- |
| `create-school.html`   | First-run onboarding — name, languages, team   |
| `index.html`           | Overview — stats, activity, quick actions      |
| `languages.html`       | Languages we teach + student native languages  |
| `courses.html`         | Upload courses + course table (incl. Access)   |
| `editors.html`         | Roster of editors + invite by email            |
| `students.html`        | Roster of students + bulk CSV / manual add     |
| `settings.html`        | School profile, plans, promotions, billing, danger zone |

The create-school page is intentionally **not linked from inside the
dashboard** — in production it sits before any school exists. Open it
directly (`create-school.html`) to demo the onboarding flow.

## Layout

Classic SaaS shell:

```
┌──────────────┬──────────────────────────────────────────────┐
│  POLYGLOTS · SCHOOLS                                        │
│  ┌──────────┐│  Page title          [+ Primary CTA]  [icon] │
│  │ RA  Pro  │├──────────────────────────────────────────────┤
│  │ Riverside││                                              │
│  └──────────┘│  Content (stats, tables, cards, dropzone…)   │
│  • Overview  │                                              │
│  • Languages │                                              │
│  • Courses   │                                              │
│  • Editors   │                                              │
│  • Students  │                                              │
│  • Settings  │                                              │
│              │                                              │
│  LH  Lena ↗  │                                              │
└──────────────┴──────────────────────────────────────────────┘
```

## Preview

Just open `index.html` in a browser, or serve the folder:

```sh
cd school_dashboard
python3 -m http.server 8080
# → http://localhost:8080
```

Backdrop-filter blur needs a modern Chromium/Safari/Firefox; degrades
gracefully (cards stay readable, just less frosted) elsewhere.

## What's intentionally not here yet

- The **create-school** wizard (deferred to next pass).
- Real backend wiring. All counts/names/dates are mock; CTAs and the
  dropzone are visual only.
- The **student-side** experience — this is admin-only.
- The Settings page (school profile, branding, danger-zone).

When the prototype is approved, the next step is wiring the screens
into the existing FastAPI server (probably under `/api/v1/school/…`
and a `/api/v1/uploads/` endpoint for the course import that already
lives in [server/src/routers](../server/src/routers/)).
