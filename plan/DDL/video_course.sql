-- Adds video-course support to course_simple.course: a `kind` discriminator
-- ('ai' | 'video') so the existing course list/workspace can distinguish AI
-- text courses from video courses, and a `video_url` column for the source
-- video link.
ALTER TABLE course_simple.course ADD COLUMN IF NOT EXISTS kind varchar(20) NOT NULL DEFAULT 'ai';
ALTER TABLE course_simple.course ADD COLUMN IF NOT EXISTS video_url text;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'course_kind_chk'
    ) THEN
        ALTER TABLE course_simple.course
            ADD CONSTRAINT course_kind_chk CHECK (kind IN ('ai','video'));
    END IF;
END $$;
