# Polyglots Design System

The design system for **polyglots.social** — a language-learning app whose core experience is a quiz-driven listening/understanding loop. This document is the entry point for designers, agents, and engineers building branded artifacts (mockups, prototypes, slides, marketing pages, in-app variations) that match the existing Polyglots Student application.

> "Improve language through understanding."
> — header copy from the Polyglots home screen

---

## What is Polyglots?

Polyglots is an **authoring + learning platform for language courses**. Three apps share a common backend:

1. **Content Manager** — author/load/AI-generate sentences and word data (Flutter + Python)
2. **Editor** — assemble courses, modules, and lessons from content (Flutter + Python)
3. **Student** — the learning app itself, what users actually use (Flutter + Python). This is the surface this design system primarily covers.

**Core learning loop (Student):**
A *Course* contains *Modules*. Modules contain *Lessons*. Lessons are sequences of *Quiz* exercises around real sentences (from corpora or AI-generated). Sentences are played as audio, optionally annotated word-by-word (translation + per-word audio). The app is intentionally *gentle*: wrong answers receive no negative feedback — the system stays encouraging and supportive. Some exercises hide the written text so the student practices listening before reading.

**Quiz types observed in the codebase:**
- Single choice (translate / identify a sentence)
- Multiple choice (select all that apply)
- Identify words you hear (audio + tap matching options)
- Word search (find words in a letter grid — alphabet practice)
- Typing (memorize + type with on-screen letter buttons)
- Memory cards (pair-matching for letter/character learning)
- Explanation (informational screen, no answer required)

**Languages supported as either source or target:** Arabic, Czech, German, Greek, English, Spanish, French, Hebrew, Hindi, Italian, Japanese, Portuguese (BR/PT), Russian, Chinese. Heavy emphasis on Japanese (kanji/katakana/hiragana progression), Hebrew, and Arabic — non-Latin scripts are first-class.

---

## Sources

This system was reverse-engineered from:

- **GitHub repo** — `davidvoler/polyglots` (private, branch `main`). The `student/ui/` Flutter app is the reference implementation. Key files:
  - `student/ui/lib/main.dart` — app shell, theme, bottom nav
  - `student/ui/lib/core/theme/app_theme.dart` — Material theme (Inter, blue.600 primary, 16px card radius, 12px button radius)
  - `student/ui/lib/features/home/presentation/pages/home_page.dart` — home screen w/ language card, settings toggles
  - `student/ui/lib/features/quiz/presentation/pages/quiz_page.dart` — main quiz player
  - `student/ui/lib/features/quiz/presentation/pages/question_types_demo_page.dart` — all 7 question types in one place
  - `student/ui/lib/features/quiz/presentation/pages/widgets/*.dart` — per-type quiz widgets
  - `student/ui/lib/features/courses/presentation/pages/courses_page.dart` — course list
  - `student/ui/lib/features/progress/presentation/pages/progress_page.dart` — stats + recent words/sentences
  - `student/ui/lib/shared/models/app_data.dart` — language list w/ flags, fallback quiz data
- **Project planning docs** — `README.md`, `ITERATIONS.md`, `ROADMAP.md` at the polyglots repo root, where the product vision is laid out (gradual difficulty, "small steps 5–10%", refresh logic, encouraging tone).
- **`davidvoler/poly-all-desgin`** repo was attached but returned empty/inaccessible (409). If this repo contains additional design tokens or assets, the system should be re-imported and this README updated.

---

## Index — files in this system

| File / folder | Purpose |
|---|---|
| `README.md` | This document — overview, content + visual + iconography fundamentals |
| `SKILL.md` | Agent-Skill-compatible entry point for invoking this system |
| `colors_and_type.css` | All design tokens as CSS custom properties (colors, type ramp, spacing, radii, shadows) |
| `assets/` | Logos, icons, illustrations referenced from the system |
| `fonts/` | Webfonts (Inter, Noto Sans for non-Latin) |
| `preview/` | Per-token preview cards rendered on the Design System tab |
| `ui_kits/student-app/` | High-fidelity React recreation of the polyglots Student app (home, courses, quiz types, progress) |

### UI kits at a glance

- **`ui_kits/student-app/index.html`** — clickable phone-frame demo. Bottom nav switches Home / Courses / Progress; "Start Learning" enters the Quiz player which cycles through translate → identify-words → memory-cards.
- Components are split by file: `Primitives.jsx` (buttons / toggles / chips / nav), `HomePage.jsx`, `CoursesPage.jsx`, `ProgressPage.jsx`, `QuizPage.jsx`, `App.jsx` (router).

---

## CONTENT FUNDAMENTALS

Polyglots' voice is **friendly, encouraging, and direct**. The product is for self-learners; copy treats the reader as a peer who showed up to do the work, not as a beginner who needs to be cheered on with hype.

### Tone

- **Supportive, never punishing.** The product *deliberately* does not show negative reactions to wrong answers. Mirror this in every microcopy decision — there is no "Wrong!", no red ❌ buzzer. Wrong answers are quietly moved past or softly noted ("Not quite. Try again or move on."). Right answers get a calm "Correct!" or just turn the option green.
- **Practical, not promotional.** The home subtitle is *"Improve language through understanding"* — not "Master 50 languages in 5 minutes a day!". Avoid superlatives, avoid exclamation marks (more than one per screen is too many).
- **Curious and a little nerdy.** The roadmap discusses Zipf frequency, kanji ordering, transliteration models — there is real interest in the linguistics. Marketing copy can lean into this without hiding it.

### Voice mechanics

- **Person:** Second-person *you* for instructions ("Listen and tap the words you hear.", "Type the word you just saw:"). First-person *I* never appears in UI. Possessives lean second-person ("Your Native Language", "Your Progress", "Words You've Learned").
- **Casing:** **Title Case for headings and buttons** ("Start Learning", "Check Answer", "Learning Options", "Quiz Progress", "Recent Learning"). Sentence case is fine for body and helper text.
- **Punctuation:** Periods on full sentences in instructions ("Find the words: CAT, CAR, ARC."). No period on button labels or short headers.
- **Numerals:** Always digits in UI ("12 Questions Today", "${current} of ${total}", "234 Total Questions").

### Examples lifted from the app

- Header: **Listen & Learn** — *Improve language through understanding*
- Buttons: **Start Learning** · **Check Answer** · **Continue** · **Next Question** · **Finish Quiz** · **New Quiz** · **Retry** · **Done**
- Section titles: **Learning Options** · **Quiz Progress** · **Your Progress** · **Recent Learning** · **Words You've Learned** · **Sentences You've Practiced**
- Settings labels w/ subtitle pattern: **Show Text** — *Display written text with audio* · **Auto Play** — *Play audio automatically* · **Transliteration** — *Show pronunciation guide*
- Quiz instructions: *"Listen and tap the words you hear."* · *"Find the words: CAT, CAR, ARC. Words can be in any direction."* · *"Memorize this word, then type it."* · *"Memorize the cards. They will hide shortly."* · *"Flip two cards at a time. Matched pairs stay visible."*
- Empty/error states: *"No questions available"* / *"Please try again later"* — soft, never blaming the user.
- Status pill on a degraded fetch: *"Using local questions"* with a small warning amber color and a *Retry* affordance.
- Stat copy: *"Questions Today"* · *"Total Questions"* · *"Last Quiz"* · *"Pairs found: 3 / 8"* · *"45% progress"*.

### Emoji & Unicode

- **Flags are emoji** (`🇯🇵 🇪🇸 🇮🇱 🇸🇦 🇨🇳 ...`) — always inline with the language's English name and native name. They are *the* way languages are visually identified in this product. Always include them.
- The arrow `→` is used heavily for **language pair direction** (e.g. `🇯🇵 → 🇪🇸`) — render as a clean Unicode arrow, not "->".
- Other emoji are **rare to absent** in product UI. Don't sprinkle them as decoration. Marketing surfaces *can* use them sparingly if they earn their place.

---

## VISUAL FOUNDATIONS

### Color palette

Colors come straight from Flutter's Material `Colors.*.shade*` palette as used in the codebase. Captured here as CSS variables in `colors_and_type.css`.

- **Primary brand color:** `Colors.blue.shade600` → `#1E88E5`. Used for primary buttons, the active progress bar, the "selected" tile state, and the active bottom-nav icon.
- **Surface neutrals:** white cards (`#FFFFFF`) on washed gradient backgrounds; dividers and idle borders are `grey.shade200`–`grey.shade300`; body copy is `grey.shade800`, secondary text is `grey.shade600`, hint text is `grey.shade500`/`shade400`.
- **Per-screen background gradients** (top-left → bottom-right, soft pastels — they are the page identity):
  - **Home:** `blue.shade50` → `indigo.shade100` (`#E3F2FD` → `#C5CAE9`)
  - **Quiz:** `green.shade50` → `teal.shade100` (`#E8F5E9` → `#B2DFDB`)
  - **Progress:** `yellow.shade50` → `orange.shade100` (`#FFFDE7` → `#FFE0B2`)
  - **Courses:** flat `grey.shade100` (`#F5F5F5`) — courses screen is calmer, list-driven
- **Semantic state colors** (used on quiz answer tiles, status pills, stat numbers):
  - **Correct / success:** `green.shade50/300/600/800` (`#E8F5E9 / #81C784 / #43A047 / #2E7D32`)
  - **Incorrect / warning:** `red.shade50/300/600/800` (`#FFEBEE / #E57373 / #E53935 / #C62828`) — used minimally
  - **Selected / active:** `blue.shade50/300/600/800` (`#E3F2FD / #64B5F6 / #1E88E5 / #1565C0`)
  - **Notice / degraded fetch:** `orange.shade100/300/700/800`
  - **Settings accent palette** (one per toggle, very lightweight): blue (Show Text), green (Auto Play), purple (Transliteration)

### Typography

- **Family:** **Inter** (declared in `AppTheme` as `fontFamily: 'Inter'`). Inter renders cleanly across Latin, Cyrillic, Greek, and works as a UI fallback for Hebrew/Arabic where script-specific fonts (Noto) are layered on top.
- **For non-Latin scripts** (Japanese kanji/kana, Chinese, Arabic, Hebrew, Hindi), use **Noto Sans** family variants (`Noto Sans JP`, `Noto Sans SC`, `Noto Sans Arabic`, `Noto Sans Hebrew`, `Noto Sans Devanagari`) with Inter as the Latin co-font. Arabic and Hebrew get `direction: rtl` on the relevant container — the language model carries an `rtl: true` flag.
- **Type ramp** (extracted from observed `fontSize:` values):
  - Display / hero — **32px / 700**, `grey.shade800` (e.g. "Listen & Learn")
  - Page title — **24px / 700**
  - Stat number — **48px / 700** (`Questions Today` huge), or **32px / 700** (smaller card stat)
  - Section title — **18px / 600**
  - Quiz sentence — **36px / 600** (large, scannable mid-card)
  - Body strong — **18px / 400–600**
  - Body — **16px / 400**
  - Helper / caption — **14px / 400** secondary, or **13px / 400** chip text
  - Micro — **12px / 500** (degraded-state pill copy)
- **Italic:** used for transliteration only — *italic, grey.shade600, slightly smaller than the source sentence*.

### Spacing & layout

- **Page padding:** 24px on quiz/home/progress; 16px on the courses list.
- **Vertical rhythm:** sections separated by `SizedBox(height: 24)` (24px) most commonly, with `16px` for sub-blocks and `8/12px` for tight pairs (text + helper, label + chip).
- **Card padding:** **24px** for primary feature cards (the language card, the learning options card, the quiz card); **16px** for compact info cards (Questions Today summary).
- **Standard horizontal control padding:** `16px vertical / 16px horizontal` on buttons; `12px / 12px` on toggles and answer tiles.
- **Touch targets:** answer tiles ~56–64px tall with 12px bottom margin between them.

### Shape

- **Corner radii:** **16px** for cards and the primary CTA hero, **12px** for buttons, answer tiles, and audio player chrome, **8px** for progress chips and stat pills, **circle** for icon avatars (course list `CircleAvatar` radius 26).
- **Borders:** 1px in `grey.shade200`–`grey.shade300` for idle states; semantic colored borders for state (green / red / blue / orange shade-300).

### Elevation / shadow

Two recurring elevations:

- **Card elevation (primary):** `boxShadow: rgba(0,0,0,0.10) blur 10 offset (0,4)` — used on the home language card, learning options card, quiz container, progress cards.
- **Card elevation (compact):** `boxShadow: rgba(0,0,0,0.05) blur 8 offset (0,2)` — used on the small "Questions Today" tile and memory cards.

No inner shadow patterns observed. No glassmorphism. No color-shift shadows.

### Animation & motion

The Flutter app uses Material defaults — restrained, never showy.

- **Transitions:** standard Material page transitions; `IndexedStack` swaps for the bottom nav (instant, preserves state).
- **Progress:** `LinearProgressIndicator` for both quiz progress and language progress (`minHeight: 8`).
- **Memory cards:** flip after a 700ms delay if the pair doesn't match — a soft "show, then hide" rather than a literal 3D flip.
- **Typing prompt:** word displayed for **4s**, then a **10s countdown** progress bar (blue, switching to red below 3s remaining).
- **Recommended easing for any web/HTML reproductions:** `cubic-bezier(0.4, 0, 0.2, 1)` (Material standard) at **200ms** for hover/press, **300ms** for layout/page-level changes. No bounces. No spring physics.

### States — hover, press, disabled, focus

- **Press (Material `InkWell`):** the subtle material ripple is the press response; no shrinking, no scale change. For HTML reproductions, use `:active { opacity: 0.85 }` or a 4–8% darker background.
- **Hover:** Flutter mobile doesn't really hover, but for the web variant, lighten the background by 4% for cards, deepen by 6% for primary buttons.
- **Selected (multi/single choice):** background switches to `blue.shade50`, border to `blue.shade300`, text to `blue.shade800`, font-weight goes to 600. After submit, color shifts to green (correct) or red (selected-but-incorrect).
- **Disabled buttons:** Flutter default — washed primary (~40% opacity).
- **Focus rings:** Material default focus highlight; in HTML use a 2px `blue.shade300` outline at 2px offset.

### Backgrounds & imagery

- **No photography in the app.** No hero images. No illustrations beyond Material icons.
- **No repeating patterns or textures.**
- **The diagonal pastel gradient *is* the imagery.** Each major area (Home, Quiz, Progress) owns one gradient pair (blue/indigo, green/teal, yellow/orange). Do not invent additional gradients without asking.
- **No grain, no noise, no color shifts** in any visual layer.

### Use of transparency & blur

- Transparent backgrounds appear only inside `Material(color: Colors.transparent)` for InkWell-clickable rows that want to show their parent's color.
- **No backdrop blur** anywhere. No frosted glass.

### Layout rules

- **Mobile-first.** The Flutter app targets phones (it does run on web/desktop too via Flutter, but the layout is single-column at all breakpoints).
- **Bottom navigation** with three items (Home / Courses / Progress) is the primary nav. `BottomNavigationBarType.fixed`, blue.600 selected / grey.500 unselected.
- **Page header pattern:** big title + 1-line subtitle on Home; back arrow + section title + linear progress + "n of N" on the Quiz page.
- **Cards stack vertically** with 24px gaps. No multi-column dashboards.

### What to avoid

- ❌ Bluish-purple gradients (we use blue/indigo, but the codebase doesn't go violet)
- ❌ Emoji decoration on cards beyond country flags
- ❌ Cards with rounded corners and a single colored left-border accent
- ❌ Heavy drop shadows or neumorphism
- ❌ Black-on-yellow alert banners — keep warnings to soft `orange.shade100`
- ❌ Custom-drawn iconography — stick to Material Icons (see ICONOGRAPHY)

---

## ICONOGRAPHY

The Polyglots Student app uses **Material Icons** (Flutter's built-in `Icons.*` set, served from the `MaterialIcons` font that ships with Flutter and `material-design-icons`). For HTML reproductions, we use the **Material Symbols** webfont via Google Fonts CDN — it's the modern, browser-native equivalent and matches the look 1:1.

### Icons used in the app

Catalogued from the Student codebase:

| Material name | Used for |
|---|---|
| `home` | Home tab in bottom nav |
| `menu_book` | Courses tab; course card avatar |
| `trending_up` | Progress tab |
| `arrow_back` | Quiz back button |
| `play_arrow` | Audio play (normal speed) |
| `slow_motion_video` | Audio play (slow) |
| `volume_up` | "Auto Play" settings toggle accent icon |
| `visibility` | "Show Text" settings toggle accent icon |
| `text_fields` | "Transliteration" settings toggle accent icon |
| `language` | Loading-state language placeholder |
| `quiz` | Empty-quiz icon |
| `play_circle_fill` | "See question type demos" CTA |
| `check`, `close`, `radio_button_unchecked`, `check_circle` | Answer tile state markers |
| `error_outline` | Course load error |
| `warning_amber_rounded` | "Using local questions" notice |
| `chevron_right` | Course card affordance |
| `folder` | Module chip |
| `school` | Lessons-count info chip |
| `layers` | Modules-count info chip |

### Style

- **Filled / rounded corners**, single weight — Flutter's default Material set is filled. For Material Symbols on the web, use the **Rounded** style with **`fill: 1`** for active states, **`fill: 0`** for idle / outline icons.
- **Default size:** 24px in compact contexts, 16px in chip contexts, 32–64px on hero/empty states.
- **Color:** icons inherit text color in their context. Bottom nav uses `blue.shade600` selected / `grey.shade500` idle. Settings-toggle accent icons take their colored background pill (blue / green / purple).
- **No icon font swap:** if a CDN-fetched Material Symbols sprite is unavailable, use the Material Symbols Outlined fallback rather than substituting Heroicons or Lucide. Stick to one family.

### Logo

> ⚠️ **No logo file was found in the repo.** The Flutter app surfaces the wordmark **"Listen & Learn"** as a 32px / 700 Inter title in `grey.shade800`, with the subtitle *"Improve language through understanding"*. Until a logo asset is provided, design system reproductions render the same wordmark + subtitle.
>
> The product brand name on the public-facing side is **polyglots.social**. For social/marketing surfaces, use a clean Inter wordmark + the `.social` TLD as a smaller subscript/accent until a real mark is supplied.
>
> **Action for the user:** if you have a logomark or wordmark file (SVG/PNG), drop it into `assets/` and we'll regenerate the brand cards.

### Flags

- Country flags are **Unicode emoji** (`🇯🇵`, `🇪🇸`, `🇸🇦`, etc.). The `Language` model in `app_data.dart` ships these directly. Render them inline at 24–32px (use `font-size`, since they're text). On Windows where flag emoji don't render, fall back to the country-code 2-letter pill.

### Substitution flags

- **Inter** webfont — needs to be downloaded into `fonts/` or loaded via Google Fonts CDN. The Flutter app declares it but doesn't ship the file. We're loading from Google Fonts on the web side; if you need offline, ask for the .ttf bundle.
- **Material Symbols** — loaded from Google Fonts CDN. For air-gapped use we'd swap to a self-hosted sprite.
- **Logo** — currently a wordmark fallback. Pending real logo file from product team.

