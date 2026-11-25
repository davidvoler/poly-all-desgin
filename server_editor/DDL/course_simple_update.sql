-- Bring schema `course_simple` in line with `course`.
-- Additive only: adds the columns that exist in course but not here, and widens
-- two varchar columns that are shorter here. Safe to re-run.
--
-- Not changed on purpose (would need data checks first):
--   course_simple.course.user_id   varchar(100)  vs course int8 (ints insert fine into varchar)
--   course_simple.course.status    check (draft, review, published, archived) - course may hold 'reviewed'
--   course_simple.exercise.course_id / lesson_id  NOT NULL - course allows NULL

BEGIN;

-- course_simple.course
ALTER TABLE course_simple.course
    ADD COLUMN IF NOT EXISTS deleted        boolean DEFAULT false,
    ADD COLUMN IF NOT EXISTS course_options jsonb;

-- course.level is varchar(30); varchar(4) would truncate/reject e.g. 'beginner'
ALTER TABLE course_simple.course
    ALTER COLUMN "level" TYPE varchar(30);

-- course_simple.module
ALTER TABLE course_simple."module"
    ADD COLUMN IF NOT EXISTS deleted boolean DEFAULT false;

-- course_simple.lesson
ALTER TABLE course_simple.lesson
    ADD COLUMN IF NOT EXISTS deleted     boolean DEFAULT false,
    ADD COLUMN IF NOT EXISTS video_start float4  DEFAULT 0,
    ADD COLUMN IF NOT EXISTS video_end   float4  DEFAULT 0;

-- course_simple.exercise
ALTER TABLE course_simple.exercise
    ADD COLUMN IF NOT EXISTS word     varchar(255),
    ADD COLUMN IF NOT EXISTS question varchar(255);

-- course.exercise.answer is varchar(300)
ALTER TABLE course_simple.exercise
    ALTER COLUMN answer TYPE varchar(300);

COMMIT;

-- course_simple.exercise.item_kind: what the exercise practises, 'word' or 'sentence'.
-- Video lessons quiz the words before the video and the sentences after it.
BEGIN;
ALTER TABLE course_simple.exercise
    ADD COLUMN IF NOT EXISTS item_kind varchar(10)
        CONSTRAINT exercise_item_kind_chk CHECK (item_kind IN ('word', 'sentence'));

-- Video word exercises made before the flag left the sentence empty.
UPDATE course_simple.exercise
SET sentence = question
WHERE sentence IS NULL AND word IS NOT NULL AND exercise_type = 'single_choice'
  AND btrim(question) NOT LIKE '% %';

-- Backfill: an exercise whose sentence is a single word practises a word.
UPDATE course_simple.exercise
SET item_kind = CASE
        WHEN word IS NOT NULL AND btrim(COALESCE(sentence, question, '')) NOT LIKE '% %' THEN 'word'
        ELSE 'sentence'
    END
WHERE item_kind IS NULL;
COMMIT;
