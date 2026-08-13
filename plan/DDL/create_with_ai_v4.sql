-- Create with AI v4 — simplify the data model per design review:
-- - course.level: smallint -> varchar. Store CEFR strings ("A1"..."C1")
--   directly; drops the need for utils/level.py's int<->string mapping.
-- - Words are NOT a database entity. Drop course_word (a table with its
--   own id) in favor of an ordered course.words jsonb list — the AI
--   generates words in frequency order (simplest/most common first) and
--   that order is just preserved as list order. The word string itself
--   is the identity, same as course_simple.lesson.words already was.
-- - Sentences ARE a database entity (course_simple.sentence), but
--   nothing holds a foreign key to them. sentence_id is a deterministic
--   hash of "lang:text" (utils/ai_course_content.py:sentence_id_for),
--   computed in application code — so a lesson or exercise can carry
--   that id inline without a join, matching the pre-existing (and
--   never FK-enforced) course_simple.exercise.sentence_id/to_sentence_id
--   columns. lesson_sentence (a link table keyed by serial id) is
--   dropped in favor of an ordered lesson.sentences jsonb list,
--   mirroring lesson.words. Editing an exercise's text does not touch
--   the sentence it was generated from, and deleting a draft sentence
--   does not cascade to any exercise already built from it — no complex
--   links to maintain in either direction.

ALTER TABLE course_simple.course
    ALTER COLUMN level TYPE varchar(4)
    USING (CASE level
        WHEN 1 THEN 'A1' WHEN 2 THEN 'A2' WHEN 3 THEN 'B1'
        WHEN 4 THEN 'B2' WHEN 5 THEN 'C1' ELSE '' END);
ALTER TABLE course_simple.course ALTER COLUMN level SET DEFAULT '';

ALTER TABLE course_simple.course
    ADD COLUMN IF NOT EXISTS words jsonb NOT NULL DEFAULT '[]'::jsonb;

DROP TABLE IF EXISTS course_simple.course_word;

ALTER TABLE course_simple.lesson
    ADD COLUMN IF NOT EXISTS sentences jsonb NOT NULL DEFAULT '[]'::jsonb;

DROP TABLE IF EXISTS course_simple.lesson_sentence;

-- Content-addressable cache, not a relation: sentence_id = hash(lang:text),
-- computed by the app before insert. No FK points at this table.
CREATE TABLE IF NOT EXISTS course_simple.sentence (
    sentence_id bigint PRIMARY KEY,
    lang varchar(12) NOT NULL,
    text varchar(300) NOT NULL,
    gloss varchar(300) DEFAULT '',
    created_at timestamp DEFAULT now()
);
