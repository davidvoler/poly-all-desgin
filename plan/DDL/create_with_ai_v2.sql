-- Create with AI — backend for the chat-driven course-building copilot
-- (see plan/design_experiments/create_with_ai_poc and TASKS.md "Planning
-- the api"). Adds: lesson draft/ready status, a course-scoped word bank,
-- the lesson<->word selection, editable lesson sentences, and the
-- exercise "correct answer" column the POC needs but course_simple.exercise
-- didn't have.

ALTER TABLE course_simple.lesson
    ADD COLUMN IF NOT EXISTS status varchar(20) NOT NULL DEFAULT 'draft';

ALTER TABLE course_simple.lesson
    DROP CONSTRAINT IF EXISTS lesson_status_chk;
ALTER TABLE course_simple.lesson
    ADD CONSTRAINT lesson_status_chk CHECK (status IN ('draft', 'ready'));

ALTER TABLE course_simple.exercise
    ADD COLUMN IF NOT EXISTS answer varchar(200);

CREATE TABLE IF NOT EXISTS course_simple.course_word (
    course_word_id serial PRIMARY KEY,
    course_id bigint NOT NULL,
    word varchar(200) NOT NULL,
    gloss varchar(300) DEFAULT '',
    example_sentence varchar(300) DEFAULT '',
    example_gloss varchar(300) DEFAULT '',
    created_at timestamp DEFAULT now()
);
CREATE INDEX IF NOT EXISTS course_word_course_id_idx ON course_simple.course_word (course_id);

-- Which words (from the course word bank) are selected into which lesson.
CREATE TABLE IF NOT EXISTS course_simple.lesson_word (
    lesson_id bigint NOT NULL,
    course_word_id bigint NOT NULL,
    PRIMARY KEY (lesson_id, course_word_id)
);
CREATE INDEX IF NOT EXISTS lesson_word_course_word_id_idx ON course_simple.lesson_word (course_word_id);

-- Draft example sentences for a lesson's selected words. `chosen` tracks
-- which ones the editor kept when asked to pick before exercises are
-- generated from them; exercise.sentence_id (already on the exercise
-- table) points back at lesson_sentence_id.
CREATE TABLE IF NOT EXISTS course_simple.lesson_sentence (
    lesson_sentence_id serial PRIMARY KEY,
    lesson_id bigint NOT NULL,
    course_word_id bigint,
    text varchar(300) NOT NULL,
    gloss varchar(300) DEFAULT '',
    chosen boolean NOT NULL DEFAULT true,
    created_at timestamp DEFAULT now()
);
CREATE INDEX IF NOT EXISTS lesson_sentence_lesson_id_idx ON course_simple.lesson_sentence (lesson_id);
