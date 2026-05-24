# Polyglots — course import format

A course is a folder. Zip it and upload it from the dashboard's
**Courses** page (or POST it to `/api/v1/editor/upload/`). The same
folder shape is what the server's exporter writes when you click
**Export as .zip** on a course row, so you can round-trip your work
through any text editor.

This document describes the format by example — see
[`./course.txt`](course.txt) and the `module1/` / `module2/`
subfolders alongside it for a complete working sample.

---

## Folder layout

```
my-course/
├── course.txt              ← course-level metadata (required)
├── module1/
│   ├── module.txt          ← module title
│   ├── lesson1/
│   │   ├── lesson.txt      ← lesson title
│   │   └── exercises.txt   ← one or more exercises
│   └── lesson2/
│       ├── lesson.txt
│       └── exercises.txt
└── module2/
    └── …
```

Rules:

- Modules and lessons can be named anything; the loader walks them in
  alphabetical order, so `module01/` / `module02/` is the easy way to
  control sequence. The numeric suffix in `module<n>` (if present) is
  preserved as the module's `weight`.
- `course.txt` and at least one `module<n>/lesson<n>/exercises.txt`
  are required. Everything else is optional.
- YAML / JSON files (`module_01.yaml`, `module_01.json`) are still
  accepted alongside the text format for backwards compatibility.

---

## `course.txt`

One `key: value` per line. Recognised keys:

| Key                 | Required | Notes                                              |
| ------------------- | -------- | -------------------------------------------------- |
| `name`              | yes      | Title shown on the Courses page and in the app.    |
| `description`       | no       | Free-text blurb shown under the title.             |
| `language`          | yes      | The language the course teaches. ISO code (`it`) **or** English name (`Italian`) — both work. |
| `student_languages` | yes      | The student's native language. Same code-or-name rule. Comma-separated when more than one (`English, Spanish`). |

Example:

```
name: Italian for English Speakers
description: A course designed to help English speakers learn Italian, covering essential grammar and vocabulary.
language: Italian
student_languages: English
```

### Recognised language names

The loader maps these common names to ISO codes:

| Name                         | Code |
| ---------------------------- | ---- |
| English                      | `en` |
| Italian / Italiano           | `it` |
| Arabic / العربية             | `ar` |
| Hebrew / עברית               | `he` |
| Spanish / Español            | `es` |
| French / Français            | `fr` |
| Japanese / 日本語             | `ja` |
| Greek / Ελληνικά             | `el` |

Anything else: pass the 2-letter ISO 639-1 code directly.

---

## `module<n>/module.txt`

One line:

```
module: Introduction to Italian
```

- `module:` is the module title.
- If the parent folder is named `module<n>`, `<n>` is used as the
  module's `weight` (so the dashboard lists modules in the right
  order). Otherwise weights are auto-numbered from 1.

---

## `module<n>/lesson<n>/lesson.txt`

One line:

```
lesson: Greeting sentences
```

- `lesson:` is the lesson title.

---

## `module<n>/lesson<n>/exercises.txt`

This is where the actual quiz content lives. Each exercise is a block,
blocks are separated by a `---` line:

```
---
Buona sera
[+] Good evening
[-] Good morning
[-] How are you
[-] Are you talking to me?
--- Explanation
In Italian the vowels often blend together when the next word starts with a vowel.
This is called *elision*.
---
Buonanotte
[-] Good evening
[-] Good morning
[-] How are you
[+] Good night
```

Block layout:

1. **First non-blank line** = the prompt / sentence. This is what the
   student is asked to translate or recognise.
2. **Option lines** start with `[+]` (correct) or `[-]` (incorrect).
   Whitespace is trimmed. You need at least one `[+]` per exercise;
   the rest are distractors.
3. **Optional explanation block** — a line that starts with
   `--- Explanation` (or `---Explanation`) begins a free-text note
   shown to the student after they answer. The block ends at the next
   `---` separator. Multiple lines are joined with newlines.

Tip: The first line of the file can be a leading `---` or you can
skip it — both are accepted, so you can paste new content at the top
without thinking about it.

---

## Audio

When a sentence has audio, name the file the same as the sentence
slug and drop it alongside `exercises.txt` (e.g.
`module1/lesson1/buona-sera.mp3`). The loader picks up `.mp3` /
`.m4a` / `.wav` and links them to the matching exercise by sentence
text. Audio is optional.

---

## Export

`GET /api/v1/editor/export/{course_id}` returns a zip in this same
shape. Click **Export as .zip** on any course row in the dashboard
to get a copy you can edit locally and re-upload.
