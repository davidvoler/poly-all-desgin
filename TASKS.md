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
  

*** getting ready for MVP ***

- [v] solve oauth - consider alternatives for auth0
- [] upload some generated courses as an example - verify that the process works well
- [w] Dashboard - have the dashboard working for - public and non profit schools 
- [] dashboard scenario 
    - [] connection - shall we have only a single users management for schools 
    - [] Create school - let's hide it for now - we will find a way to do it later 
    - [] Start generating courses and try to upload 


- [] learn how to generate courses with AI



*** tasks saved for later stage ***
- [ ] I prefer using Oauth - so we can skip password change password functionality - for now at least
- [] Real SMTP for password reset — out of scope without infrastructure.
- [ ] Pagination on Students table (currently capped at 200).
- [ ] Cohort filter chips on Students page.
- [ ] Public-school sibling site (community-contributor variant from design_experiments/school_public/) — substantial new UI; deferred to dedicated pass.
