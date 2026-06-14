# Create a course with AI

Goal: let an editor describe the course they want, have an LLM draft it in
our existing **course import format**, optionally enrich it (audio, Japanese
ruby), and import it — without hand-writing `exercises.txt` files.

The import format already exists (see `content/example_course/README.md`),
so the AI's job is "fill that format". This keeps the AI an *authoring aid*
on top of the deterministic importer rather than a new content pipeline.

---

## Plan

- [v] Design the UI for creating a course with AI  → see **Design** below.
- [v] What would be the structure of the course     → reuses the import format
      (course → modules → lessons → exercises). No new structure invented.
- [in progress] Create examples that generate a full course → one worked
      example below; more to live under `content/example_course/`.
- [~] Type of exercise — mapping to the import format:
    - [v] sentences / single option — prompt line + one `[+]`, rest `[-]`.
    - [v] sentence / multiple correct options — multiple `[+]` lines.
    - [v] identify words in a sentence — same `[+]`/`[-]` format, options are
          the candidate words (correct = words present in the sentence).
    - [v] explanations — `--- Explanation` block after the options.
    - [ ] words — match — **NOT** in the current import format. Needs a format
          extension (e.g. a `[match] a = b` line type) + parser + app widget.
    - [ ] learn alphabet — **NOT** in the current format. Needs a new exercise
          type (single glyph → reading/sound) + parser + app widget.
- [~] Other services the platform can offer (post-generation enrichment):
    - [ ] Generate audio (Azure / Google TTS) — a backend job that walks the
          generated sentences, synthesises `.mp3` per sentence slug, and drops
          them beside `exercises.txt` (the importer already links audio by
          sentence text). Azure Neural / Google WaveNet, picked per language.
    - [v] Generate Japanese ruby text — backend utility already exists (the
          `ruby_text` jsonb on exercises is produced this way). The AI does
          NOT write furigana; the backend annotates after import.
- [v] Ask AI to create the course in the import format — the dashboard builds
      a ready-to-run **prompt** that embeds the format spec + the editor's
      parameters; the model returns the folder text, which goes through the
      existing upload/import path.

---

## Design (UI)

A dashboard page at `/create-course` ("Create with AI"), reachable from the
sidebar and a CTA on the Courses page. Single scrolling form, grouped:

1. **Basics** — course title, language taught, student language(s), CEFR level
   (A1–C1), topic/focus blurb.
2. **Structure** — modules, lessons per module, exercises per lesson. Shows a
   live total ("≈ 120 exercises") which drives the cost estimate.
3. **Exercise mix** — multi-select of the supported types (single-option,
   multiple-correct, identify-words, explanations). Unsupported types
   (word-match, alphabet) are shown disabled with a "format extension needed"
   note so the roadmap is visible.
4. **Enrichment** — switches: generate audio (Azure/Google), generate ruby
   (Japanese only), include explanations.
5. **Generate** — a live **AI prompt** preview assembled from the inputs +
   the import-format spec. Two paths:
   - **Copy prompt** → run it in any LLM → paste/upload the result on the
     Courses page (works today, no backend needed).
   - **Generate with AI** (phase 2) → backend `/editor/ai/generate` calls the
     LLM server-side, runs enrichment, and hands back a course id.

The **initial implementation** ships steps 1–5 as a frontend prompt-builder
(Copy prompt path). The server generation + enrichment is phase 2.

### Built (phase 1)

- Dashboard page `/create-course` ("Create with AI") — sidebar item + a CTA on
  the Courses page. Form (basics, structure with live exercise count, exercise
  mix, audio/ruby enrichment) → **live AI prompt** + Copy.
- **Cost estimate** panel (≈1 credit/exercise, audio per 1k chars) per the
  pricing below.
- **Paste result & import** — paste the model's `=== path ===` output and import
  it directly via `POST /api/v1/editor/upload/text`, which splits the document
  into the course folder and runs the same parser + loader as the zip upload,
  then opens the new course.
- **Importer fix (prerequisite):** `editor/utils/parse_course.py` +
  `folder_to_db.py` did not actually parse the documented/exported format — it
  crashed on nested lesson folders, never captured the prompt sentence, ignored
  `--- Explanation`, didn't map `name`/`language`/`student_languages` →
  `title`/`lang`/`to_lang`, and inserted `''` into the jsonb columns. All fixed
  and verified end-to-end (example course imports with correct sentences,
  options, explanations, and ISO langs). The zip upload benefits from the same
  fix.

Phase 2 (not built): server-side `/editor/ai/generate` (LLM + audio + ruby).

### Course generation flow (phases)

```
editor form ──▶ build prompt ──▶ [phase 1] copy → external LLM → upload zip
                              └──▶ [phase 2] POST /editor/ai/generate
                                       │  LLM → import-format text
                                       │  → existing importer → course (draft)
                                       │  → audio job (Azure/Google)
                                       │  → ruby job (ja)
                                       ▼
                                   course opens in the editor (review)
```

### Output format the AI is asked for

The model returns the same per-file text the importer reads, as a single
fenced document the dashboard splits by path header, e.g.:

```
=== course.txt ===
name: Japanese for Hebrew Speakers
description: Everyday Japanese for absolute beginners.
language: Japanese
student_languages: Hebrew

=== module1/module.txt ===
module: Greetings

=== module1/lesson1/lesson.txt ===
lesson: Saying hello

=== module1/lesson1/exercises.txt ===
---
こんにちは
[+] שלום
[-] תודה
[-] להתראות
--- Explanation
Used during the day; おはよう is for the morning.
```

(Single-document form keeps phase-1 copy/paste simple; phase-2 server path can
zip the split files straight into the existing upload endpoint.)

---

## Pricing (proposals)

Two metered costs, billed as credits so the editor sees an estimate before
committing.

**Course generation (LLM):** cost is dominated by output tokens. A lesson of
~10 exercises is roughly ~1–2k output tokens; a 6-module × 5-lesson × 10-ex
course ≈ 300 exercises ≈ 0.4–0.8M output tokens.
- Proposal: price per generated exercise (predictable for editors), e.g.
  **1 credit / exercise**, with 1 credit ≈ raw LLM cost × ~4 markup. Show the
  running estimate from the structure step. Regeneration of a single
  lesson/exercise costs only that slice.

**Audio recording (TTS):** Azure Neural ≈ **$16 / 1M characters**, Google
WaveNet ≈ **$16 / 1M chars** too. A sentence ≈ 30–60 chars.
- Proposal: price **per 1,000 characters** (or a flat per-sentence rate ≈
  cents), TTS cost × ~3 markup, charged when the audio job runs (separately
  from generation, since audio can be (re)done on an existing course).

Ruby generation is a cheap backend utility (no per-call LLM) → bundle it free
with Japanese courses.



## Creating course with Claude - Lesson learned 

- The sentences got very long after a few lessons 
- We have a single exercise oer sentences - beginners need repetition and need multiple exercise per lesson
- show translation for any sentence - after checking answer
- add comments to exercise - after exercise
- new format is nice 
- annotated sentences could be an exercise type - with some explanation
A sentence like:
Good morning, and thanks for the water
can not be in the 5 lesson for beginner 
it is too complicated and has 2 parts

I am not sure Claude is good for the task 
romanji: Kōhī wa arigatō gozaimasu ka
option: Would you like coffee?
this looks to me like a wrong translation
### Suggestion

- Create multiple steps for each lesson/module 
  - words - suggest to start with common known words like greeting words 
  - sentences 
  - exercise 
- In each lesson/module define 
  - max words per sentences 
  - number of exercise per sentence

We can also think of a course that has a curve of values 
 - number of words per module/lesson
 - number of sentences per lesson
 - number of exercises per lesson 
 - max number of words in sentences 
 - number of exercises per sentences 
 

### Summary 
words -> sentences -> exercise
well defined parameters for each module/lesson.
Finalize the structure 
Add comments after exercise is solved. 
guess the verb game. 
hint


try with different models. 

