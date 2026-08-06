# Polyglots Student — UI Kit

High-fidelity HTML/React recreation of the Polyglots Student app (the learning surface). Mobile-first, single-column, three-tab bottom nav.

## Screens included
- **Home** — language card (current course + progress), Learning Options card with Show Text / Auto Play / Transliteration toggles, Questions Today summary, "See question type demos" CTA.
- **Courses** — list of courses for the current target language, each with module/lesson counts and a chevron.
- **Progress** — Total Questions stat, recent words you've learned, recent sentences you've practiced.
- **Quiz player** — header with back, progress bar, "n of N" count; the active question; primary action button. Shows three quiz types: single-choice translate, listen-and-tap-words, memory cards.

## Components (`*.jsx`)
- `AppShell` — phone-frame wrapper, status bar, page background switcher
- `BottomNav` — Home / Courses / Progress
- `LanguageCard`, `LearningOptionsCard`, `QuestionsTodayCard` — Home cards
- `CourseRow` — Courses list item with avatar, title, chips, chevron
- `StatCard`, `WordChipList`, `SentenceList` — Progress cards
- `QuizHeader`, `AnswerTile`, `AudioControls`, `MemoryCard` — Quiz primitives
- `ToggleRow`, `Chip`, `PrimaryButton`, `OutlinedButton`, `TextButton` — shared

## How to view

Open `index.html` in the preview. The phone frame has a working bottom nav and a "Start Learning" button on Home that opens the quiz player.
