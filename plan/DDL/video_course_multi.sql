-- Revises video_course.sql: a video course holds a *list* of videos, added
-- after creation (like course_simple.course.words), not a single URL fixed
-- at create time. Replace the single video_url column with a videos jsonb
-- list, each entry {video_url, title}.
ALTER TABLE course_simple.course DROP COLUMN IF EXISTS video_url;
ALTER TABLE course_simple.course ADD COLUMN IF NOT EXISTS videos jsonb NOT NULL DEFAULT '[]'::jsonb;
