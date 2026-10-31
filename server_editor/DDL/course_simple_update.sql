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
