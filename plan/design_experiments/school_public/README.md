# Polyglots — Open Content Dashboard (design prototype)

Sibling to [school_dashboard/](../school_dashboard/), but for the
**open-content** variant: a community of contributors authoring free
public courses, no billing, no member gating.

Same Polyglots design language (dark-blue radial gradient, frosted glass,
white-pill CTAs); the sidebar identifies a *person* (Lena Hayes) instead
of a school.

## Mental-model differences from school_dashboard

| | school_dashboard | school_public *(this folder)* |
| --- | --- | --- |
| Identity in sidebar | Riverside Academy | Lena Hayes (Reviewer · 🇮🇱) |
| Access | Public ↔ Members-only | All courses public, all free |
| Authority | Owner / Editor / Viewer | Reviewer (per-language) + Co-editor (per-course) |
| Money | Plans + promotions | None |
| Feedback | Stats | Student **comments** on each course |
| Discovery | None | Browse other authors' work |

## Pages

| Page              | Purpose                                                    |
| ----------------- | ---------------------------------------------------------- |
| `index.html`      | Overview — editors, courses, new this week, waiting review |
| `courses.html`    | My courses ↔ Community toggle · language filter · search   |
| `comments.html`   | Student comments on your courses · reply / pin / resolve   |
| `reviews.html`    | Review queue + reviews on your courses                     |

## Preview

```sh
cd school_public
python3 -m http.server 8081
# → http://localhost:8081
```

## Shared with the school dashboard

- All design tokens (colors, radii, type)
- Shell components (sidebar, topbar, glass cards, tables, pills, dropdowns)
- The `lang-card`, `stats`, `activity`, `filters` patterns

## Net-new components introduced here

- `.course-card` + `.course-grid` (catalog view, not table)
- `.search` (pill-shaped full-text input)
- `.toggle` (Mine ↔ Community switcher)
- `.comment-feed` + `.comment-row` (with `.unread` state)
- `.review-list` + `.review-row`
- `.rev-badge` (per-language reviewer credential)
- `.metric` (heart/comment/view counters)

The `school_dashboard` CSS was copied wholesale and extended at the
bottom — the two prototypes will likely diverge over time, so a hard
copy is cleaner than a symlink.
