-- =============================================================
-- School schema — supports the school-admin dashboard.
--
-- Steady-state shape:
--   - One row in school.schools per tenant (e.g. Riverside Academy).
--   - school.school_users links existing user_data.users rows to a
--     school with a role (owner / editor / viewer). Owners and editors
--     show up on the Editors page; viewers show up there too but read
--     only.
--   - school.school_invites holds pending invitations sent by email
--     before the invitee has signed up.
--   - school.student_enrollments holds the student roster shown on the
--     Students page — each row is one student + one course (a student
--     without any course yet is still allowed via a NULL course_id).
--   - school.course_access overlays per-school access/status on a
--     content-side course (public vs. members, published vs. draft).
-- =============================================================

CREATE SCHEMA IF NOT EXISTS school;

-- -------------------------------------------------------------
-- school.schools
-- -------------------------------------------------------------
DROP TABLE IF EXISTS school.schools CASCADE;
CREATE TABLE school.schools (
    school_id          serial4 PRIMARY KEY,
    slug               varchar(64)  NOT NULL,
    name               varchar(255) NOT NULL,
    plan               varchar(32)  NOT NULL DEFAULT 'free',  -- free | pro | enterprise
    streak_days        int4         NOT NULL DEFAULT 0,
    languages_taught   _varchar     NOT NULL DEFAULT '{}',    -- e.g. {ara,heb,ita}
    native_languages   _varchar     NOT NULL DEFAULT '{}',    -- student native langs
    logo_url           varchar(500) NULL,
    primary_color      varchar(8)   NOT NULL DEFAULT '#1E88E5',
    created_at         timestamp    NOT NULL DEFAULT now(),
    updated_at         timestamp    NOT NULL DEFAULT now(),
    CONSTRAINT schools_slug_uq UNIQUE (slug)
);

-- -------------------------------------------------------------
-- school.school_users — staff (owners / editors / viewers)
-- -------------------------------------------------------------
DROP TABLE IF EXISTS school.school_users CASCADE;
CREATE TABLE school.school_users (
    school_user_id      serial4 PRIMARY KEY,
    school_id           int4         NOT NULL,
    -- NULL until the invitee accepts and we link to user_data.users.
    user_id             int4         NULL,
    name                varchar(200) NOT NULL DEFAULT '',
    email               varchar(200) NOT NULL,
    password_hash       varchar(200) NULL,                       -- bcrypt; NULL until they accept an invite
    role                varchar(20)  NOT NULL DEFAULT 'editor',  -- owner | editor | viewer
    assigned_languages  _varchar     NOT NULL DEFAULT '{}',      -- empty array = all
    courses_owned       int4         NOT NULL DEFAULT 0,
    last_seen           timestamp    NULL,
    status              varchar(20)  NOT NULL DEFAULT 'active',  -- active | suspended
    created_at          timestamp    NOT NULL DEFAULT now(),
    CONSTRAINT school_users_uq UNIQUE (school_id, user_id),
    CONSTRAINT school_users_email_uq UNIQUE (school_id, email),
    CONSTRAINT school_users_role_chk CHECK (role IN ('owner','editor','viewer'))
);
CREATE INDEX IF NOT EXISTS school_users_school_idx ON school.school_users (school_id);
CREATE INDEX IF NOT EXISTS school_users_user_idx   ON school.school_users (user_id);

-- -------------------------------------------------------------
-- school.school_invites — email-based pending invites
-- -------------------------------------------------------------
DROP TABLE IF EXISTS school.school_invites CASCADE;
CREATE TABLE school.school_invites (
    invite_id           serial4 PRIMARY KEY,
    school_id           int4         NOT NULL,
    email               varchar(200) NOT NULL,
    role                varchar(20)  NOT NULL DEFAULT 'editor',
    assigned_languages  _varchar     NOT NULL DEFAULT '{}',
    invited_by_user_id  int4         NULL,
    token               varchar(120) NOT NULL,
    accepted_at         timestamp    NULL,
    expires_at          timestamp    NULL,
    created_at          timestamp    NOT NULL DEFAULT now(),
    CONSTRAINT school_invites_uq UNIQUE (school_id, email),
    CONSTRAINT school_invites_role_chk CHECK (role IN ('owner','editor','viewer'))
);
CREATE INDEX IF NOT EXISTS school_invites_token_idx ON school.school_invites (token);

-- -------------------------------------------------------------
-- school.student_enrollments — one row per (student, course) pair
-- -------------------------------------------------------------
DROP TABLE IF EXISTS school.student_enrollments CASCADE;
CREATE TABLE school.student_enrollments (
    enrollment_id   serial4 PRIMARY KEY,
    school_id       int4         NOT NULL,
    user_id         int4         NOT NULL,
    course_id       int4         NULL,                          -- NULL = student with no course yet
    plan_id         int4         NULL,                          -- which subscription plan they're on
    lang            varchar(12)  NULL,
    cohort          varchar(80)  NULL,                          -- e.g. 'Spring-A'
    progress        real         NOT NULL DEFAULT 0.0,          -- 0..1
    last_active     timestamp    NULL,
    status          varchar(20)  NOT NULL DEFAULT 'active',     -- active | slowing | inactive | no_course
    created_at      timestamp    NOT NULL DEFAULT now(),
    CONSTRAINT enrollments_status_chk CHECK (status IN ('active','slowing','inactive','no_course'))
);
CREATE UNIQUE INDEX IF NOT EXISTS enrollments_uq
    ON school.student_enrollments (school_id, user_id, COALESCE(course_id, 0));
CREATE INDEX IF NOT EXISTS enrollments_school_idx ON school.student_enrollments (school_id);
CREATE INDEX IF NOT EXISTS enrollments_user_idx   ON school.student_enrollments (user_id);

-- -------------------------------------------------------------
-- school.course_access — per-school access/status overlay
-- -------------------------------------------------------------
DROP TABLE IF EXISTS school.course_access CASCADE;
CREATE TABLE school.course_access (
    school_id   int4         NOT NULL,
    course_id   int4         NOT NULL,
    access      varchar(20)  NOT NULL DEFAULT 'members',     -- public | members
    status      varchar(20)  NOT NULL DEFAULT 'published',   -- published | draft | archived
    updated_at  timestamp    NOT NULL DEFAULT now(),
    PRIMARY KEY (school_id, course_id),
    CONSTRAINT course_access_access_chk CHECK (access IN ('public','members')),
    CONSTRAINT course_access_status_chk CHECK (status IN ('published','draft','archived'))
);

-- -------------------------------------------------------------
-- school.activity_log — feeds the "Recent activity" panel on Overview
-- -------------------------------------------------------------
DROP TABLE IF EXISTS school.activity_log CASCADE;
CREATE TABLE school.activity_log (
    activity_id   serial4 PRIMARY KEY,
    school_id     int4         NOT NULL,
    actor_user_id int4         NULL,           -- NULL for system actions
    kind          varchar(40)  NOT NULL,       -- e.g. course_upload, editor_invite, students_added, language_added
    summary       text         NOT NULL,       -- short, pre-rendered headline
    created_at    timestamp    NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS activity_log_school_idx
    ON school.activity_log (school_id, created_at DESC);

-- -------------------------------------------------------------
-- school.plans + school.plan_features — Subscription plans section
-- on Settings. plan_features is a per-row feature list ("Audio
-- downloads", "1:1 sessions", etc.) with an `included` flag that
-- drives the green check / grey dash in the UI.
-- -------------------------------------------------------------
DROP TABLE IF EXISTS school.plan_features CASCADE;
DROP TABLE IF EXISTS school.plans CASCADE;

CREATE TABLE school.plans (
    plan_id      serial4 PRIMARY KEY,
    school_id    int4         NOT NULL,
    tier         varchar(40)  NOT NULL,
    price_cents  int4         NOT NULL DEFAULT 0,
    cadence      varchar(20)  NOT NULL DEFAULT 'monthly',  -- monthly | yearly
    blurb        text         NULL,
    featured     bool         NOT NULL DEFAULT false,
    weight       int4         NOT NULL DEFAULT 0,
    created_at   timestamp    NOT NULL DEFAULT now(),
    CONSTRAINT plans_cadence_chk CHECK (cadence IN ('monthly','yearly'))
);
CREATE INDEX IF NOT EXISTS plans_school_idx ON school.plans (school_id, weight);

CREATE TABLE school.plan_features (
    plan_feature_id  serial4 PRIMARY KEY,
    plan_id          int4         NOT NULL,
    label            text         NOT NULL,
    included         bool         NOT NULL DEFAULT true,
    weight           int4         NOT NULL DEFAULT 0,
    CONSTRAINT plan_features_plan_fk
        FOREIGN KEY (plan_id) REFERENCES school.plans(plan_id) ON DELETE CASCADE,
    CONSTRAINT plan_features_uq UNIQUE (plan_id, label)
);
CREATE INDEX IF NOT EXISTS plan_features_plan_idx
    ON school.plan_features (plan_id, weight);

-- -------------------------------------------------------------
-- school.billing_methods — payment card shown on Settings → Billing.
-- One "primary" row per school for now; the schema allows additional
-- rows so adding a second card later is just a flag flip.
-- -------------------------------------------------------------
DROP TABLE IF EXISTS school.billing_methods CASCADE;
CREATE TABLE school.billing_methods (
    billing_method_id  serial4 PRIMARY KEY,
    school_id          int4         NOT NULL,
    brand              varchar(40)  NOT NULL DEFAULT 'Card',
    last4              varchar(4)   NOT NULL,
    exp_month          int2         NOT NULL,
    exp_year           int4         NOT NULL,
    is_primary         bool         NOT NULL DEFAULT true,
    created_at         timestamp    NOT NULL DEFAULT now(),
    updated_at         timestamp    NOT NULL DEFAULT now(),
    CONSTRAINT billing_exp_month_chk CHECK (exp_month BETWEEN 1 AND 12)
);
CREATE UNIQUE INDEX IF NOT EXISTS billing_primary_uq
    ON school.billing_methods (school_id) WHERE is_primary;

-- -------------------------------------------------------------
-- course_simple.course — review workflow column.
-- Courses move draft → review → published. The Editors dashboard lists
-- everything; the public Polyglots app only serves status='published'.
-- -------------------------------------------------------------
ALTER TABLE course_simple.course
    ADD COLUMN IF NOT EXISTS status varchar(20) NOT NULL DEFAULT 'draft';

ALTER TABLE course_simple.course
    DROP CONSTRAINT IF EXISTS course_status_chk;
ALTER TABLE course_simple.course
    ADD CONSTRAINT course_status_chk
        CHECK (status IN ('draft','review','published','archived'));

-- -------------------------------------------------------------
-- Seed: one Riverside Academy + its owner, matching the mocks.
-- -------------------------------------------------------------
INSERT INTO school.schools (slug, name, plan, streak_days, languages_taught, native_languages)
VALUES ('riverside-academy', 'Riverside Academy', 'pro', 14,
        '{ar,he,it}', '{en,he,ar}')
ON CONFLICT (slug) DO NOTHING;
