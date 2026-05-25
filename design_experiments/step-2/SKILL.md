---
name: polyglots-design
description: Use this skill to generate well-branded interfaces and assets for polyglots.social, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the README.md file within this skill, and explore the other available files.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

## Quick orientation

- **`README.md`** — start here. Brand overview, content tone, visual foundations, iconography, spacing/shape/elevation rules.
- **`colors_and_type.css`** — every design token as a CSS custom property. Link this from any HTML output: `<link rel="stylesheet" href=".../colors_and_type.css">`. Includes Material Symbols Rounded webfont (use `<span class="poly-icon">name</span>`) and Inter + Noto Sans non-Latin fallbacks.
- **`ui_kits/student-app/`** — interactive React recreation of the Student app. Use components here as the source of truth for any in-app mockup. `index.html` is a clickable phone-frame demo of Home / Courses / Progress / Quiz.
- **`preview/`** — small per-token preview cards. Useful as inspiration / examples when picking colors, type sizes, etc.

## Top-level rules to follow

- The app voice is **supportive and never punishing**. No "Wrong!" buzzers. Wrong answers go quiet or get a soft "Not quite". Right answers turn green and say "Correct!".
- Headers and buttons are **Title Case**. Avoid exclamation marks (more than one per screen is too many).
- **Country flag emoji** are first-class for languages. The arrow `→` is used between language pairs.
- **Each route owns a soft pastel diagonal gradient**: Home blue/indigo, Quiz green/teal, Progress yellow/orange, Courses flat grey. Don't invent new ones.
- **Inter** for Latin, **Noto Sans JP/SC/Arabic/Hebrew/Devanagari** for non-Latin scripts. Arabic/Hebrew get `dir="rtl"`.
- **Material Symbols Rounded** is the only icon family. Filled for active states, outline for idle. Don't sub Heroicons/Lucide.
- **Two shadow elevations only** — `var(--shadow-card)` for primary cards, `var(--shadow-card-compact)` for compact ones. No glass, no inner shadows, no neumorphism.
- **Mobile-first**, single column. Bottom nav with Home / Courses / Progress.
