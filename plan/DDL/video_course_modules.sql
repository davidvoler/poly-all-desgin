-- Video courses gain "Video Modules" — groups of videos + manually-authored
-- exercises, mirroring the same lightweight jsonb-list pattern already used
-- for course_simple.course.videos (no separate table).
ALTER TABLE course_simple.course ADD COLUMN IF NOT EXISTS modules jsonb NOT NULL DEFAULT '[]'::jsonb;
