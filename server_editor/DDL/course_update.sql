-- Bring schema `course` in line with `course_simple`.
-- Additive only: adds the columns that exist in course_simple but not here.
-- Safe to re-run (IF NOT EXISTS everywhere).
--
-- Not changed on purpose (would need data checks first):
--   course.course.user_id      int8 NOT NULL   vs course_simple varchar(100) NULL
--   course.course.school       NOT NULL        vs course_simple NULL default 'pgs'
--   course.course.status       no check        vs course_simple check (draft, review, published, archived)
--                              (course.sql comment says 'reviewed', course_simple uses 'review')

BEGIN;

-- course.course
ALTER TABLE course.course
    ADD COLUMN IF NOT EXISTS lesson_count    int2        DEFAULT 0,
    ADD COLUMN IF NOT EXISTS owner_user_id   int4,
    ADD COLUMN IF NOT EXISTS metadata        jsonb,
    ADD COLUMN IF NOT EXISTS share_edit      varchar(20) DEFAULT 'private',
    ADD COLUMN IF NOT EXISTS "access"        varchar(20) DEFAULT 'private',
    ADD COLUMN IF NOT EXISTS edit_stage      varchar(20) DEFAULT 'draft',
    ADD COLUMN IF NOT EXISTS copied_from     int8        DEFAULT 0,
    ADD COLUMN IF NOT EXISTS school_id       int8        DEFAULT 1,
    ADD COLUMN IF NOT EXISTS active_revision int8        DEFAULT 0,
    ADD COLUMN IF NOT EXISTS words           jsonb       DEFAULT '[]'::jsonb NOT NULL,
    ADD COLUMN IF NOT EXISTS kind            varchar(20) DEFAULT 'ai' NOT NULL
        CONSTRAINT course_kind_chk CHECK (kind IN ('ai', 'video')),
    ADD COLUMN IF NOT EXISTS videos          jsonb       DEFAULT '[]'::jsonb NOT NULL,
    ADD COLUMN IF NOT EXISTS modules         jsonb       DEFAULT '[]'::jsonb NOT NULL;

-- course.module
ALTER TABLE course.module
    ADD COLUMN IF NOT EXISTS words       varchar[],
    ADD COLUMN IF NOT EXISTS created_at  timestamp DEFAULT now(),
    ADD COLUMN IF NOT EXISTS updated_at  timestamp DEFAULT now(),
    ADD COLUMN IF NOT EXISTS module_type varchar(20),
    ADD COLUMN IF NOT EXISTS subtitles   jsonb,
    ADD COLUMN IF NOT EXISTS sentences   varchar[],
    ADD COLUMN IF NOT EXISTS video_url   varchar,
    ADD COLUMN IF NOT EXISTS phrases     varchar[];

-- course.lesson
ALTER TABLE course.lesson
    ADD COLUMN IF NOT EXISTS annotations jsonb,
    ADD COLUMN IF NOT EXISTS ruby_text1  jsonb,
    ADD COLUMN IF NOT EXISTS ruby_text2  jsonb,
    ADD COLUMN IF NOT EXISTS ruby_text3  jsonb,
    ADD COLUMN IF NOT EXISTS status      varchar(20) DEFAULT 'draft' NOT NULL
        CONSTRAINT lesson_status_chk CHECK (status IN ('draft', 'ready')),
    ADD COLUMN IF NOT EXISTS sentences   jsonb DEFAULT '[]'::jsonb NOT NULL;

-- course.exercise
ALTER TABLE course.exercise
    ADD COLUMN IF NOT EXISTS sentence       varchar(300) DEFAULT '',
    ADD COLUMN IF NOT EXISTS audio          varchar(300) DEFAULT '',
    ADD COLUMN IF NOT EXISTS word1          varchar(100) DEFAULT '',
    ADD COLUMN IF NOT EXISTS word2          varchar(100) DEFAULT '',
    ADD COLUMN IF NOT EXISTS word3          varchar(100) DEFAULT '',
    ADD COLUMN IF NOT EXISTS sentence_id    int8,
    ADD COLUMN IF NOT EXISTS to_sentence_id int8,
    ADD COLUMN IF NOT EXISTS created_at     timestamp DEFAULT now(),
    ADD COLUMN IF NOT EXISTS updated_at     timestamp DEFAULT now();

COMMIT;
