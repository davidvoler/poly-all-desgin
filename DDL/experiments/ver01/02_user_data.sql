-- ─────────────────────────────────────────────────────────────────────
-- user_data schema — per-user state: preferences, attempt history.
-- ─────────────────────────────────────────────────────────────────────
-- Depends on content.question existing (results.question_id FK).
-- Run after 01_content.sql.

CREATE SCHEMA IF NOT EXISTS user_data;


-- ─── user_data.preference ───
-- One row per user. Keeps the three-axis language state from the client
-- (UI / "I speak" / "Learning"), plus the current proficiency bucket the
-- placement test landed them in.
CREATE TABLE IF NOT EXISTS user_data.preference (
    user_id            UUID         PRIMARY KEY,
    ui_language        TEXT,
    speak_language     TEXT,
    learning_language  TEXT,
    level              SMALLINT,                            -- starting bucket from placement test
    active_course_id   UUID         REFERENCES content.course (id) ON DELETE SET NULL,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CHECK (level IS NULL OR level >= 1)
);


-- ─── user_data.results ───
-- One row per attempt. Append-only audit trail: drives spaced-repetition,
-- scoreboards, and the "you got these wrong" review queue.
--
-- ON DELETE SET NULL on the FKs so we keep historical attempts even if a
-- question or lesson gets edited / removed from the curriculum.
CREATE TABLE IF NOT EXISTS user_data.results (
    id                 BIGSERIAL    PRIMARY KEY,
    user_id            UUID         NOT NULL,
    question_id        UUID         REFERENCES content.question (id) ON DELETE SET NULL,
    lesson_id          UUID         REFERENCES content.lesson  (id) ON DELETE SET NULL,
    correct            BOOLEAN      NOT NULL,
    response_time_ms   INTEGER,
    bucket             SMALLINT,                            -- snapshot of the question's bucket at attempt time
    attempted_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CHECK (bucket IS NULL OR bucket >= 1),
    CHECK (response_time_ms IS NULL OR response_time_ms >= 0)
);

-- "Latest attempts for this user" — the dashboard / streak-feed query.
CREATE INDEX IF NOT EXISTS results_user_attempted_idx
    ON user_data.results (user_id, attempted_at DESC);

-- "How is this user doing on this question?" — spaced-repetition queries.
CREATE INDEX IF NOT EXISTS results_user_question_idx
    ON user_data.results (user_id, question_id);

-- "Aggregate accuracy at bucket N for this user" — placement / level-up.
CREATE INDEX IF NOT EXISTS results_user_bucket_idx
    ON user_data.results (user_id, bucket);
