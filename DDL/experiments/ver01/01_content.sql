-- ─────────────────────────────────────────────────────────────────────
-- content schema — static curriculum: courses → modules → lessons → questions
-- ─────────────────────────────────────────────────────────────────────
-- Postgres 13+ assumed (gen_random_uuid is built-in via pgcrypto).
-- Cross-file ordering: this file must run before 02_user_data.sql since
-- user_data.results references content.question.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS content;


-- ─── content.course ───
-- A learnable curriculum bundle (e.g. "Japanese for Beginners").
-- `code` is the stable client-facing identifier; `id` is the internal PK.
CREATE TABLE IF NOT EXISTS content.course (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    code          TEXT         NOT NULL UNIQUE,                         -- e.g. 'japanese-beginners'
    title         TEXT         NOT NULL,
    subtitle      TEXT,
    icon          TEXT         NOT NULL DEFAULT 'play_arrow',           -- material icon name
    level_pill    TEXT,                                                 -- e.g. 'A1·A2', 'In Progress'
    source_lang   TEXT         NOT NULL,                                -- ISO-style code: 'en', 'ja', …
    target_lang   TEXT         NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS course_lang_pair_idx
    ON content.course (source_lang, target_lang);


-- ─── content.module ───
-- A bundle of lessons within a course. A course may have one or many.
CREATE TABLE IF NOT EXISTS content.module (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id     UUID         NOT NULL REFERENCES content.course (id) ON DELETE CASCADE,
    code          TEXT         NOT NULL,                                -- stable per-course id, e.g. 'm3'
    name          TEXT         NOT NULL,
    order_index   INTEGER      NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (course_id, code),
    UNIQUE (course_id, order_index)
);

CREATE INDEX IF NOT EXISTS module_course_idx ON content.module (course_id, order_index);


-- ─── content.lesson ───
-- One vocabulary/sentence unit (the "card" the user studies). Lives inside
-- a module. `bucket` is the deterministic difficulty tier (1..N) seeded
-- from buckets.bucket_for() so a fresh DB lands in the same shape each run.
CREATE TABLE IF NOT EXISTS content.lesson (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id     UUID         NOT NULL REFERENCES content.module (id) ON DELETE CASCADE,
    code          TEXT,                                                 -- optional stable id within module
    native        TEXT         NOT NULL,                                -- target-lang text shown to learner
    translation   TEXT         NOT NULL,                                -- source-lang gloss
    bucket        SMALLINT,                                             -- difficulty tier from buckets.bucket_for()
    order_index   INTEGER      NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CHECK (bucket IS NULL OR bucket >= 1)
);

CREATE INDEX IF NOT EXISTS lesson_module_idx ON content.lesson (module_id, order_index);
CREATE INDEX IF NOT EXISTS lesson_bucket_idx ON content.lesson (bucket);


-- ─── content.question ───
-- A practice or assessment item. Often (but not always) tied to a lesson —
-- placement-test questions can be lesson-agnostic, hence the nullable FK.
CREATE TABLE IF NOT EXISTS content.question (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id       UUID         REFERENCES content.lesson (id) ON DELETE CASCADE,
    type            TEXT         NOT NULL,                              -- 'multiple_choice' | 'annotated' | 'translation' | …
    prompt          TEXT         NOT NULL,                              -- what the learner sees
    correct_answer  TEXT,                                               -- canonical text of the right answer
    options         JSONB,                                              -- e.g. multiple-choice alternatives, distractor data
    bucket          SMALLINT,                                           -- denormalised from lesson for fast level-test queries
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CHECK (bucket IS NULL OR bucket >= 1)
);

CREATE INDEX IF NOT EXISTS question_lesson_idx ON content.question (lesson_id);
CREATE INDEX IF NOT EXISTS question_type_bucket_idx ON content.question (type, bucket);
