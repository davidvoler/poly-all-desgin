*** Initial Dashboard ***

- [v] create a flutter app called dashboard this app should be used for both public school and school dashboards - difference in the settings 

- [v] create the tables ddl from school in ./DDL in school schema  - schools, users, etc

- [v] Create initial design of the dashboard in ./dasboard flutter app based on the design in ./design_experiments/school_dashboard

- [v] implement the python server code in server/school all school related api should be in this folder 

- [v] implement the python api for course editing - in server/editor - for simplicity we are editing now by importing and exporting a single compressed file
- [v] implement the review of a course on both server and client side, We need to add to the course a status field (review, published )

- [v] Add a login page to the dashboard.  

- [v] Start implementing the dashboard with api to the server .  - write here tasks for any missing api end point
   - [v] Overview → GET /api/v1/school/{id}/stats + GET /api/v1/school/{id}/activity
   - [v] Languages → GET /api/v1/school/{id}/languages (added; per-language teach/native cards)
   - [v] Courses → GET /api/v1/editor/courses/ + POST /api/v1/editor/review/{id}/status (status menu)
   - [v] Editors → GET /api/v1/school_users/ + POST /api/v1/school_users/ (invite dialog)
   - [v] Students → GET /api/v1/school/{id}/students (filterable by lang + status)
   - [v] Settings → PUT /api/v1/school/{id} (editable profile)

*** Follow-ups — known gaps ***

- [v] Upload dropzone is visual only; wire it to POST /api/v1/editor/upload/ (multipart) + invalidate editorCoursesProvider on success
- [v] Course row "Export" action — call GET /api/v1/editor/export/{id} and trigger a browser download
- [v] Editors row actions (suspend / change role / delete) — server already supports PUT/DELETE on /api/v1/school_users/{id}; UI not wired yet
- [v] "Add students" CTA on Students page — single-student enroll + CSV bulk upload both wired
- [v] Settings: subscription plans, billing card, danger-zone deletion — DDL (`school.plans`, `school.plan_features`, `school.billing_methods`) + CRUD endpoints + UI all landed; danger-zone confirms by typing the school name then signs out
- [v] Activity feed only captures course status transitions today; expand `school.activity_log` writes from the upload, invite, and enrollment endpoints so the Overview panel reflects more

*** Still open ***

- [v] CSV bulk-enrol endpoint + Students-page CSV upload UI (POST /api/v1/school/{id}/students/csv?lang=ar accepting a CSV with email,name,course_id columns)
- [v] Settings page wiring — `school.plans`/`school.plan_features`/`school.billing_methods` tables seeded; full CRUD endpoints; danger-zone DELETE wired with type-name confirm + sign-out
- [v] Course detail page (drill-in from the Courses table) — read-only modules / lessons tree at /course; a per-lesson editor is the next pass
- [v] Real folder→DB ingestion at upload time — `editor.utils.folder_to_db.load_course_content` now runs after extraction; best-effort, swallows malformed modules

*** Next pass (new work) ***

- [v] Per-lesson exercise editor inside the course detail page (GET /api/v1/editor/lesson/{id} added; click any lesson row → glass-card dialog with title + per-exercise editor)
- [v] Show subscriber counts on plan cards — `plan_id` added to `school.student_enrollments`; `Plan.subscriber_count` populated server-side from COUNT(DISTINCT user_id); rendered on cards
- [v] Search box on the Courses / Students / Editors tables — server `q` filter (ILIKE on title/description/email/name) + debounced `SearchField` widget on all three pages
- [v] Real password reset flow — `school.password_resets` token table; POST /forgot_password issues + logs a 30-min token, POST /reset_password consumes it; login page has a two-step dialog (email → token + new password) with inline token shown for the demo
- [v] Remove page transition between sidebar sections — `_NoTransitionsBuilder` registered per platform

*** Dev notes ***

- Default seeded credentials: `lena@riverside.edu` / `changeme` (owner of "Riverside Academy", school_id=1)
- Reset tokens print to `docker logs server` and also return inline in the API response for the demo flow

*** Next pass (selected this round) ***

Candidates considered (recommendation chosen because they round out the
auth+onboarding story without adding entirely new UX surfaces):

- [v] Persistent auth — `shared_preferences` cache; `AuthRestoring` state during cold-boot lookup; cleared on sign-out.
- [v] Create-school onboarding wizard at `/create-school` — auto-derives slug from name; `is_public` toggle (defaults on); POSTs `/api/v1/school/` + auto-logs in via `adoptSession`; linked from login page. Added `is_public` column to `school.schools` as part of this.
- [v] Auth middleware — `school.utils.auth.require_school_member` reads `X-School-User-Id` header, verifies caller belongs to requested school (path or query). 401 on bogus header, 403 on mismatch, 200 when header missing (back-compat). Wired into school stats/activity/languages/students/plans/billing + editor courses/review/upload + school_users list. Client Dio stamps the header on sign-in/restore, clears on sign-out.


*** School Types ***
We can have the following school types - with priority 1-4 
1. Public schools - Open content anyone can create content - user reviewed - open to anyone - priority 1
2. No Charge school - A real school or university that teaches languages and want to use our technology for enhancing the learning pace for its students - it may want also to open the content to others. Priority 2 
3. Private school that charges the students per course, monthly or annually - priority 4


- [] Create a Super Admin user
- [] Add a page schools - this page will show all existing schools and edit them
- [] Add school type - (one of the 3 above)
- [] Add create new school

   Decision points (resolving per workflow rule):
   - Where super-admin lives (REVISED 2026-05-23 after user clarified: super-admin is NOT bound to any school):
     - [ ] `school.school_users.is_super_admin bool` flag — rejected, still requires school_id.
     - [selected] Separate `school.super_admins(super_admin_id, name, email, password_hash, created_at, last_seen)` table. Login flow checks super_admins FIRST; if found, returns a `LoginInfo` with `school_id=0` and `role='super_admin'`. Auth middleware treats super-admin as belonging-to-every-school. Existing school_users login path stays unchanged for regular roles.
   - School type column:
     - [selected] Add `type varchar(20)` enum ('public' | 'no_charge' | 'private') alongside the existing `is_public bool`. Backfill type from is_public; keep is_public derived so older clients still work. Drop is_public later.
     - [ ] Replace is_public with type immediately — would invalidate the wizard + settings UI in this pass.
   - "Schools" admin page placement:
     - [selected] New top-level nav item visible only when `is_super_admin`. Route /super-admin/schools with a single page showing the list + inline edit dialog + "Create new school" CTA that reuses the existing wizard.
     - [ ] Build a separate super-admin sub-app — heavier; defer.

- [] Terms and conditions

   Decision points (resolving per workflow rule):
   - T&C storage:
     - [selected] Static markdown at `content/legal/terms_v1.md` served by GET /api/v1/terms — easy to revise, version bumps via filename.
     - [ ] DB-backed `school.terms_versions(version, content, created_at)` — flexible but heavier.
   - Acceptance tracking:
     - [selected] `school.terms_acceptances(school_user_id, version, accepted_at)` — one row per (user, version). Server returns "needs to accept" when there's no row for the current version.
     - [ ] Just a `school_users.accepted_terms_version varchar` column — less query-friendly when bumping versions.
   - When the dialog appears:
     - [selected] Editor invite on public schools — newly-created editor row marked `pending_terms = true`; the editor sees a one-time T&C dialog on next sign-in. Admins on public schools also see it once. Private schools skip the gate.
     - [ ] Every signed-in user must accept — annoying for students who won't author content.




*** Public School ***
Let's first define what is a public school 
- In a public school all content is free - no charge for learning 
- Initially we can have a single public school - maybe later we may think that different groups would like to maintain, different public schools. 
- It would be best if the public school would use the same functionality with the following differences 

- []  We do not limit languages - when a user creates a course - he can choose any language
- We keep the language page to see in what languages we already have courses 
- [] For now only I can edit my courses - 
- [] We may want to allow co-editing - We need a plan first on how it would happen - we need to think of concepts like in github or wikipedia - but it requires planning.
- [] Editor page - currently accessible on to admins - where you can see a list of contributors   
- [] settings - also accessible only to admins  
- [] We need to implement a simple ACL for public school - actually we need it also for private school
 
  Roles are
    - Admin
      Edit Languages 
      Edit settings 
      Add remove users 

    - Editor
      Edit your courses
      Add courses 
      Upload and download your courses  
    - Super Editor
      Edit other people's courses - Only on private for now  
    - Reviewer 
      - can write review comments 
      - can authorize a course to be published 
    - Student
      - can write review comments 
  In public school to become an editor you have to agree to the -  terms and conditions 
  maybe we need terms and condition for all roles even for student
  You see the ui according to your role
  




*** Next pass (selected this round) ***

Picking the ACL + public-school foundations now — they're the prerequisite
for almost everything else in the Public School section, and the role
rename is cheap to do while data is small. Deferring co-editing /
terms-and-conditions since the user flagged them as needing planning.

- [v] Role enum migrated to admin/editor/super_editor/reviewer/student. Data backfilled (owner→admin, viewer→reviewer); check constraint updated on `school_users` + `school_invites`; client `EditorRoleWire` enum + `roleToWire()` serialiser; tolerant of cached "owner" sessions from before the migration.
- [v] Page-level ACL on the dashboard — `NavItem.adminOnly` filters Editors + Settings out of the sidebar for non-admin sessions; `_Guarded(adminOnly: true)` swaps in an `_AdminOnlyDenied` empty-state for deep links.
- [v] Public school = any language — upload route checks `school.is_public`; private schools enforce `languages_taught` whitelist with a clear 400 message; public schools accept any code and auto-extend `languages_taught` so the Languages page picks it up.
- [v] Course ownership — `owner_user_id` column on `course_simple.course`; populated from `actor_user_id` on upload; `require_course_editor` helper enforces 403 on `set_course_status` + lesson save when the caller isn't owner / admin / super_editor. NULL owner (legacy/seed rows) short-circuits to back-compat allow.
- [ ] Terms-and-conditions acceptance for becoming an editor on a public school — deferred (needs UX + storage decisions).
- [ ] Real co-editing (github/wikipedia-style) — deferred per spec.


*** Content creation Formant  *** 
We have 2 main way of creating content 
1. Use the UI to create a course. lessons and modules 
2. Import the content from a compresses folder
- [v] We need an example course that users can export and extend - can be found in content/example_course

- [v] We need an explanation page describing the format
   - Markdown spec at `content/example_course/README.md` (folder layout + course.txt / module.txt / lesson.txt / exercises.txt keys + recognised language names + round-trip note).
   - Dashboard `Format help` ghost-button on the Courses upload dropzone opens an inline cheat-sheet dialog (code-block snippets, scrollable).
   - Parser extended: `editor.utils.folder_to_db.load_course_content` now detects `course.txt` and walks the `module<n>/lesson<n>/exercises.txt` shape — falls back to the old YAML/JSON loader when `course.txt` is absent.
   - Language naming: `_to_lang_code()` maps common English names (`Italian`) and a few native scripts (`العربية`, `日本語`) to ISO codes; unknown strings pass through lowercased so custom codes still work.
   - Bug fix during smoke-test: upload now syncs `course_simple.course.lesson_count` after ingestion so the Courses table + detail page show the right totals.
   - **Smoke-test:** uploading `content/example_course.zip` to school_id=2 produced course #7 with `modules: 2 · lessons: 4`, exercises parsed correctly including `--- Explanation` blocks (stored on `word3` for now — separate explanation column is a future schema tweak).




*** tasks for deployment ***

- [v] Client env via `flutter_dotenv` — both apps load `assets/.env` at
  startup. `lib/config/app_config.dart` centralises reads; precedence is
  `--dart-define` > `.env` > hardcoded default. Variables:
  `API_BASE_URL`, `AUDIO_BASE_URL` (both apps), plus `AUTH_PROVIDER`,
  `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID`, `AUTH0_AUDIENCE`,
  `AUTH0_REDIRECT_URI` (dashboard only). `.env.example` committed,
  `assets/.env` gitignored.
- [v] Auth0 sign-in in the dashboard — `auth0_flutter` wrapped in
  `lib/auth/auth0_service.dart` (web uses `Auth0Web`, native uses
  `Auth0`). Login page shows a "Sign in with Auth0" button only when
  `AUTH_PROVIDER` is `auth0` or `both`; the `AuthNotifier` exchanges
  the ID token at `POST /api/v1/school_users/login_auth0`. On web,
  `restoreWebSession()` runs during cold-boot so the post-redirect
  ID token gets traded for a `LoginInfo` without an extra click.
- [v] Server-side Auth0 verification — `server/src/school/utils/auth0.py`
  fetches the tenant JWKS, caches it for 1h, and verifies issuer +
  signature + expiry (+ audience when configured). Route
  `/api/v1/school_users/login_auth0` requires an existing
  `school.school_users` row matching the verified `email` claim — Auth0
  identities are not auto-provisioned, so school ACLs still gate access.
  Returns 503 when `AUTH0_DOMAIN` is unset (the dashboard falls back to
  local login gracefully).
- [v] Local dev keeps using passwords — `AUTH_PROVIDER` defaults to
  `local` so a fresh `flutter run` + `docker compose up` needs no
  Auth0 setup. The server's `login_auth0` route is dormant until
  `AUTH0_DOMAIN` is exported (see docker-compose.yaml).


*** login page for polyglots_app ***
- [v] Auth0 sign-in for the learner app — `Auth0Service` wraps
  `auth0_flutter` (web + native). `AuthNotifier` drives the four-state
  lifecycle (restoring / signedOut / signingIn / signedIn). On
  sign-in the client posts the Auth0 ID token to
  `POST /api/v1/auth/get_or_create_user`; on cold-boot it tries
  `POST /api/v1/auth/login_with_cookie` first, then the
  `SharedPreferences` cache as an optimistic fallback.
- [v] Server `/api/v1/auth/get_or_create_user` — verifies the Auth0
  token via `school.utils.auth0`, then upserts `user_data.users` by
  email (composite PK is (email, user_id), so the lookup-then-insert
  path avoids surprising no-ops). Returns the user + their most-recent
  Preference and sets an HttpOnly `user_id` cookie (+ `lang` / `to_lang`
  mirrors, matching the legacy code). 1-year `max_age` matches the
  previous version.
- [v] Server `/api/v1/auth/login_with_cookie` — reads the `user_id`
  cookie and returns the same `UserPref` shape. 401 when the cookie is
  missing or points at a deleted row so the client falls back to the
  login screen.
- [v] Server `/api/v1/auth/logout` — clears the `user_id` / `lang` /
  `to_lang` cookies; client also flushes its SharedPreferences cache
  and best-effort hits Auth0's logout endpoint.
- [v] Dev escape-hatch — when `AUTH0_DOMAIN` is unset on the server,
  `/get_or_create_user` accepts an unverified email so the client's
  "Continue as guest" CTA works without an Auth0 tenant. Setting
  `AUTH0_DOMAIN` automatically disables this path so prod can't
  accidentally accept unverified emails.
- [v] `kCurrentUserId` migrated from a `const` to a mutable bound to
  the auth state — every existing call site keeps working. The
  `PreferenceNotifier` now watches `currentUserIdProvider` and
  short-circuits to null when signed out, so the auth gate never
  fetches a stale user's preferences.
- [v] Cookie plumbing — added `dio_cookie_manager` + `cookie_jar` so
  native targets remember the server-set cookie. Flutter web uses the
  browser cookie jar via `Options.extra: {'withCredentials': true}`.
  
  **Setup checklist (when going live):**
  1. Create an Auth0 SPA application; add the dashboard origin (e.g.
     `http://localhost:8000`) to Allowed Callback/Logout URLs.
  2. `cp dashboard/.env.example dashboard/assets/.env` and fill
     `AUTH_PROVIDER=auth0`, `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID`,
     `AUTH0_AUDIENCE`, `AUTH0_REDIRECT_URI`.
  3. Export the same `AUTH0_DOMAIN` / `AUTH0_AUDIENCE` /
     `AUTH0_CLIENT_ID` before `docker compose up` (compose passes them
     through to the server container).
  4. Pre-invite each Auth0 user via the Editors page so a matching
     `school_users.email` row exists — that's the ACL hook.
  5. `cd dashboard && flutter pub get` to install `flutter_dotenv` +
     `auth0_flutter` (same for `poliglots_app` — only flutter_dotenv).
  




*** school types subscription content access etc - planning  ***
The full school types and rules 

1. public - content is open 

school type | subscription  | roles        | content access   | payment plan
----------------------------------------------------------------
open content| NA.           |Ad,Au,Ed,Re   | open.            | NA
non profit. | by invite,    |              | open to sub.     | NA
Payment     |               |              | By Subscription  | Plan


Questions
1. do we have a single space where you can see all courses - some are free, some require schools subscription and some require paying money
In that concept a school is yet another filter 
The alternative - each school has its own space and yuo can see courses belonging to a certain school only when you are in a school context. 
If we are taking this approach - all tables should have school in them, a user's data is also schools based (words, sentences and of course lessons and courses)

How about freelance teachers - does the system cater for them - can they offer payed content 
Can they offer teacher student relationship? 




*** Tasks ***

- [v] API calls should include user_id so we can get course per specific user - we had the default user_id=1 it is time to remove it and get the real user_id from secured cookie 

- [v] We can allow anonymous user - in that case user_id = 0 - we do not save results 
- [v] When getting lessons we now have this information - lets use this data in the student app
class Lesson(BaseModel):
    lesson_id: int 
    title: str| None = ''
    description: str | None = ''
    words: list[str] | None = []
    completed: int | None = 0
    max_score: float | None = 0.0
    sum_score: float | None = 0.0
    num_attempts: int | None = 0

- [v] when getting courses we have now the info:
class Course(BaseModel):
    course_id: int 
    title: str| None = ''
    description: str | None = ''
    lang: str
    to_lang: str 
    tags : list[str] | None = []
    lesson_count: int | None = 0
    user_lessons_done: int | None = 0
    avg_score: float | None = 0.0
    progress: int | None = 0
    current_module: int | None = 1
    current_lesson: int | None = 1
please use it in the client side to mark the current course - current module and current lesson
We also have the progress information 
- [v] modules also return now the following fields 
 completed: int | None = 0
    max_score: float | None = 0.0
    sum_score: float | None = 0.0
    num_attempts: int | None = 0
    current: int 


*** user state ***

- [v] when a user logs-in we should have the following information 
  - [v] lang - the language she is learning 
  - [v] to_lang - the languages she speaks 
  - [v] ui_lang - user interface lang  
  - [v] current course - name + id  (DDL + `Preference` model now carry
        `course_name`; client `Preference` model / save() extended)
  - [v] current module  (`module_name` added; persisted on module tap +
        lesson tap)
  - [v] current lesson (`lesson_name` persisted on lesson tap and on
        auto-advance in quiz_page)

When to update?
- [v] whenever a user starts a lesson — `_LessonsSection` tap saves
      module_id/name + lesson_id/name in one POST; quiz_page next-lesson
      handler saves lesson_id/name.
- [v] when ever a user selects a new course — `_CourseCard` tap saves
      course_id/name + lang/to_lang and silently syncs the speak/learning
      providers so the home medallion follows immediately.
- [v] When a user changes lang or to lang preference — `SpeakLangNotifier`
      / `LearningLangNotifier` already POST `to_lang` / `lang` via
      `preferenceProvider.save`.
- [v] when a user changes ui_lang preferences — `UiLangNotifier.set`
      already POSTs `ui_lang`.

What to do with This preferences 
- [v] home page
  - [v] top round section — `_Medallion` no longer takes a hardcoded
        progress; reads the current course's progress from
        `coursesListProvider` keyed on `preference.courseId`.
  - [v] rectangular course section — `_CourseCaption` now prefers
        `preference.{course,module,lesson}Name`, falling back to the
        old courses-list / lessons-provider lookup when names aren't
        persisted (legacy rows).
  - [v] practice now button label — switches to "Continue · <lesson
        name>" when `preference.lessonName` is set; falls back to the
        translated "Practice Now" otherwise.
- [v] course select page 
  - [v] "I speak" / "Learning" pickers — the boot-time
        `_PreferenceBootstrap` already silently seeds them; tapping a
        course on the courses page now silently syncs both to the
        course's lang pair too.
- [v] Course page
  - [v] We should scroll to the current module and lesson — added
        `ScrollController`s on the modules strip + lessons list and a
        one-shot post-frame animateTo keyed on (course, module) and
        (module, currentLesson) so the strip jumps to the user's
        active row when the page first paints.




*** getting ready for MVP Student ***
- [v] solve oauth - consider alternatives for auth0
- [] upload some generated courses as an example - verify that the process works well
- [] current lessons - get it correctly in client
- [] lessons done/started/current get it from server
- [] view lessons by school - save current school? 
*** getting ready for MVP School ***
- [w] Dashboard - have the dashboard working for - public and non profit schools 
- [] unify users student and school 
- [] we do need a school role (and maybe subscription)
- [] Different pages visible to different users 
- [] dashboard scenario 
    - [] connection - shall we have only a single users management for schools 
    - [] Create school - let's hide it for now - we will find a way to do it later 
    - [] Start generating courses and try to upload 
*** getting ready for MVP Content ***
- [] learn how to generate courses with AI
- [] Generate  arabic v3 again 
    - [] but this time without diacritical signs 
    - [] prefer sentences with sound 
- [w] Generate Japanese



*** Dashboard and content tasks ***

- [v] full round - generate and upload
- [] simplify user permission - you can see and edit your courses 
- [v] export japanese with sentence id and to sentences id 
- [v] export japanese with correct hiragana and katakana (text or kana)
- [] on student show the ability to replace text alt1
- [] add to exercise elements for future use of annotated text
- [] dashboards - do not load full course - load module by module - create a lesson page
- [] dashboard - add delete course 


*** summary - trying to load Japanese course ***
- [v] create and load Japanese course 
- [] Lesson Learned 
  - [] We need a correct weight for module - we got it wrong 
  - [w] We need a correct weight for lesson
  - [w] We need a correct wight for exercise 
- [] there are too many identical translations for the same text in japanese - maybe we should limit to 2 or three

*** UI Tasks - Quiz Page ***

- [v] align the sentence to the right or left according to the language 
- [v] The sentences box should contain only the sentences - remove question_type from this box 
- [v] remove the text "- Translate this sentences -"
- [v] ToolBox (play sound, correct) in a separate section under the sentence 
- [v] Remove A, B, C and D from options 
- [v] Option text should be bigger - by default 
- [v] Add configuration button to the quiz page with the following options 
  - [v] resize sentences  - 3 sizes 
  - [v] resize options - 3 sizes 
  - [v] Auto play audio - play audio automatically when moving to the next question 
- [v] The sentence area should be sized to contain 2 lines
- [v] Next to the play button add a button play slow - with a different icon - this should play in 0.75 of the speed
- [v] The button order should be from left to right play - correct incorrect - play slow - even when correct/incorrect icon is not visible it should keep its place 
- [v] The button toolbox should not have a background 
- [v] The heart icon and a number (3) on the top for the page - Replace it with a star icon indicating the number of answers we got correct

*** UI Tasks - phase 2  - Quiz Page ***
- [v] Add Instruction between the the lesson title section and and the sentences section 
  - [v] for exercise of type simple - select correct translation -
  - [v] for exercise of type recognize - select words in the sentence -
  - [v] for exercise of type read  = select the correct reading - 
- [v] in exercise of type recognize - hide the sentence text - add a button to show text - it should always be there 
- [v] in recognize - When we check answers keep the words in the same size - now they are growing 
- [v] We should have the following types of indication for words 
    - words that are in sentences and user selected 
    - words that are not in sentence and user selected 
    - words that are in sentence and usr did not select 
    - words that are not in sentence and user did not select - stay in original color
- [v] The score for identify words is (correct_selected - incorrect_selected) 
      Partial credit: score = correctRatio - 0.2*incorrectCount, -1 if zero
      correct, 1.0/0.9 if all correct. Best logic computable from the server's
      (correct_ratio, incorrect_count) contract; rewards finding some words.

   Decision points (resolved per workflow rule — "write options + pick best"):
   - Data source for text variants / annotations (diacritics, transliteration,
     furigana, per-word translation+audio). The Exercise/server model has NONE
     of these fields today.
     - [selected] Build phases 3 & 4 as a self-contained DEMO (the phase-4 demo
       page, linked from home) driven by in-app sample data, with reusable,
       data-driven widgets (RubyText, AnnotatedSentence, text-variant toggle) so
       the live quiz can be wired later once the server supplies the fields.
     - [ ] Add fields across server + DB + content pipeline now — out of scope
       for a UI pass; would block the visible feature on a backend change.
     - [ ] Generate variants client-side (transliteration/romaji libs) — no
       reliable maintained Dart lib for Arabic diacritics or JA romaji; rejected.
   - Ruby-text rendering:
     - [selected] Custom RubyText widget (no dependency), Wrap of per-segment
       [reading / base] columns → guaranteed multiline, no abandoned-package risk.
     - [ ] flutter_ruby_text package — aging, multiline support uncertain.

*** Quiz Page UI -  phase 3  ***

- [v] Add text alternative button - it should be different for each language
      (text-variant toggle, demonstrated in the annotations demo page)
  - [v] for arabic show diacritical signs 
  - [v] for languages that it is applicable - transliteration
*** Quiz Page UI -  phase 4 - annotations ***
- [v] lets now implement The following in a demo page - with a link to this demo page from home page  
- [v] for japanese - It is common to annotate kanji with the correct reading in Hiragana, Katakano or Romanji - HAve used in the past a flutter lib called Flutter Ruby Text  - https://pub.dev/documentation/flutter_ruby_text/latest/ - I am not use it is the best but any working library will do - we need it to support multiline ruby text
      (implemented a custom multiline RubyText widget — see decision above)
- [v] annotated sentence - for any language we may want to annotate some words in the sentence - the annotation should be small - the translation - and an icone to play the sound of the word

*** Quiz Page - phase 5 - implement demo ***

   Decision points (resolved per workflow rule — "write options + pick best"):
   - Where the new options live:
     - [selected] BOTH — full controls in the quiz Settings sheet, plus
       quick-toggle icons in the toolbox for the two most-used (text-alternative
       cycle + annotations on/off). Lets us compare which feels better.
     - [ ] Settings only — fewer surfaces but more taps to reach.
   - Availability gating granularity (some exercises lack transliteration /
     annotated format):
     - [selected] Per-exercise data flags — a control shows/enables only when
       the current exercise carries that data (hasTransliteration / hasDiacritics
       / hasRuby / hasAnnotations). Naturally covers per-course too (if no
       exercise has it, it never appears).
     - [ ] Per-course flag only — coarser, can't vary within a course.
   - Source of the alt/ruby/annotation DATA (server sends none today):
     - [selected] New OPTIONAL fields on the Exercise JSON, populated by the
       content pipeline / translation-API later; controls hidden until present.
       The /annotated demo already shows the rendering.
     - [ ] Block phase 5 on the content/API work — would stall the UI.
   - quiz_settings persistence (task 6):
     - [selected] jsonb column on user_data.preference + mirrored in client
       Preference; QuizSettings still cached in SharedPreferences as the local
       fallback, synced up to the server prefs when signed in.
     - [ ] Local SharedPreferences only — already exists, but not cross-device.

- [v] We have some new options for quiz - we can ad them to the quiz settings, and to the toolbox - or only to the settings We can see what looks better and more user friendly
      (both: settings sheet has the full controls; toolbox has the text-alternative
      quick-toggle. Compare and tell me which placement you prefer.)
- [v] Some options are available per corse - only if the course - or even exercise level - some exercise will not have the annotated text format - some will not have transliteration. 
      (gated on per-exercise data: text-alt/ruby controls appear only when the
      exercise carries the matching sentence_alt* fields)
- [v] Add text alternative icon to the toolbox/settings - transliteration, diacritical signs 
      (uses existing sentence_alt1/2/3; JA content already has hiragana/romaji/katakana)
- [v] if Japanese we should have RubyText options - with a selection of what transliteration to put on tom - hiragana, katakana or romanji 
      (settings "Ruby" picker; renders the chosen reading above the sentence.
      NOTE: whole-sentence ruby for now — per-kanji furigana needs token-level
      data the live exercise lacks; the /annotated demo shows per-token ruby.)
- [~] Add Annotated text to the toolbox 
      PARTIAL: showAnnotations setting + plumbing exist and the /annotated demo
      renders annotations, but the live-quiz toggle is gated OFF because real
      exercises carry no per-word annotation data (only word1/2/3, no per-word
      translation/audio). Lights up once that data exists — see the "Word
      translation + audio API integration" decision block above.
- [v] Add a json field to the user preferences for quiz_settings
      (preference.quiz_settings jsonb; client QuizSettings mirrors to it + reads
      it back, SharedPreferences as offline fallback)


- [v] Fixing logic for lesson score calculation = the lessons score calculation should stay as it was - sum(score) - for all lessons 
      Verified: lesson score is already sum(score) of exercises — client
      _buildSummary.totalScore (sum) → posted per attempt → server lesson.py
      rolls up sum(score)/max(score) across attempts from user_data.lesson_status.
      Locked the intent with comments (client + server) so future scoring
      changes don't drift it to avg/normalised. Also fixed a latent bug:
      course.py user_course_status queried a non-existent `lesson_completed`
      table → now `lesson_status` (it was unused/dead, so no behaviour change).
      NOTE: course-level avg_score (courses list) is intentionally avg, not sum.

- [] In exercise type recognize - the icon for show text should be in the toolbar under the sentence - and should be an icon only with tooltip show text. Add tooltip to all other icons - play, play slow
- [] 




*** Demo Page - More options ***

- [v] in the demo page add a version of annotated sentence - where the annotation are simpler and are show in a tooltip above the word with only the word translation and a icon to play.  



*** Demo continue *** 
- [v] Ruby Text + annotated sentence + play and translation - tooltip annotation over furigana words (demo, in-app data). Google-api/live-data wiring still pending. 
- [] prepare the Japanese - Hebrew with the new data 


*** Annotated sentence data - Discussion ***

-  the annotation should come from imported data - we can do some automation to get the data - but google translate is not so good with context 
-  find a way to describe simple text annotations in text
-  maybe we can use the audio from lingva.ml

data format in text file:
translation annotation

sentences: I was looking for my dog
-*- looking : cercare
-*- dog: cane


- ruby text format - we have to verify if ruby text format can be automated - and if the automation is correct 
- we need to as claude about the data format 

*** Annotated sentence data - implementation ***

- [v] let's start from creating a ui format for combined ruby text with annotations 
- [v] Let's create the new exercise format - annotated text + ruby text
- [] japanese we have 3 ruby text and word annotation will be shared in all versions 
- [] decide the format in exercise - we do not want to do any formatting on server side we can have the data in multiple formats. 
- [] describe the text file format 

