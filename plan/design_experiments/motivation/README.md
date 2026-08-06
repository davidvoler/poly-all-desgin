# Motivation — Design Experiments

A visual exploration of how the **student motivation** ideas from
[PLAN.md](../../PLAN.md) would actually land inside the consumer Polyglots
app.

## The two-element model (the lens this gallery uses)

Every motivator on the list has two faces:

- **The CHALLENGE** — a CTA that says *"here is something worth doing"*.
- **The ACCOMPLISHMENT** — the moment of payoff that says *"you did it"*.

Each mockup below labels both, plus an **eligibility condition** — when the
challenge should actually appear. Eligibility matters as much as the idea
itself: *"master your first 50 words"* shown to a user who has only seen 12
is demoralizing; the same challenge shown next to the Words page header
when they're at 38/50 is irresistible.

## What's in the gallery

Six phone-frame mockups, side-by-side. Each highlights one or two
motivation surfaces with a subtle green focus-ring so it's easy to see
what's new vs. what's existing app chrome.

| # | Screen | Idea on display |
| - | --- | --- |
| 1 | Home | Milestone chip in the top-right slot (replaces the streak chip) + a "Still recall" segment in the vocabulary card |
| 2 | Home | Welcome-back hero — the anti-streak. The hero takes over the home screen when the user returns after ≥7 days |
| 3 | Home | Goal card + compound projection + practice-mix CTA — autonomy and forward-looking framing in one screen |
| 4 | Words | Milestone progress strip in the page header (the 50-words canonical example) |
| 5 | Quiz | Long-dormant-word celebration — mid-quiz inline payoff when an old word is recalled correctly |
| 6 | Quiz-complete | First-50-words milestone overlay — the accomplishment side of the canonical example |

The **50-words example** runs as a thread through mockups #1, #4, and #6,
so you can see the challenge → progress → payoff arc end-to-end.

## Preview

Just open `index.html` in a browser:

```sh
cd design_experiments/motivation
python3 -m http.server 8082
# → http://localhost:8082
```

## Out of scope (deliberately)

- No JavaScript, no backend. Pure CSS mockups.
- Not pixel-perfect to the Flutter app — illustrative shape and placement only.
- Not all motivation ideas from PLAN.md are mocked yet; this is the first pass on the highest-leverage ones.
