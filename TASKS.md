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

- [] Per-lesson exercise editor inside the course detail page (uses existing POST /api/v1/editor/lesson/)
- [] Show subscriber counts on plan cards (needs a plan_id column on `school.student_enrollments` or a separate `school.subscriptions` table)
- [] Search box on the Courses / Students / Editors tables (server-side LIKE filter)
- [] Real password reset flow (forgot-password link on login currently no-op)

