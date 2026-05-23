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
      Edit LAnguages 
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

- [selected] Rename `school.school_users.role` enum from owner/editor/viewer to admin/editor/super_editor/reviewer/student. Migrate Lena → admin. Update the check constraint + server-side defaults + the `EditorRoleWire` enum on the client.
- [selected] Page-level ACL on the dashboard — `Editors` and `Settings` nav items + routes only visible to role=admin; everyone else gets a 403-ish empty state if they deep-link.
- [selected] Public school = any language — when `school.is_public=true`, skip the language whitelist on the upload endpoint and accept any 2-letter code (server already accepts any code; this is mostly the public-school check on the wizard).
- [selected] Course ownership — add `owner_user_id` to `course_simple.course`; populated on upload from the uploader; `set_course_status` and `editor/lesson` save reject 403 when the caller isn't the owner (unless they're admin or super_editor).
- [ ] Terms-and-conditions acceptance for becoming an editor on a public school — deferred (needs UX + storage decisions).
- [ ] Real co-editing (github/wikipedia-style) — deferred per spec.

*** tasks saved for later stage ***
- [ ] I prefer using Oauth - so we can skip password change password functionality - for now at least
- [] Real SMTP for password reset — out of scope without infrastructure.
- [ ] Pagination on Students table (currently capped at 200).
- [ ] Cohort filter chips on Students page.
- [ ] Public-school sibling site (community-contributor variant from design_experiments/school_public/) — substantial new UI; deferred to dedicated pass.
