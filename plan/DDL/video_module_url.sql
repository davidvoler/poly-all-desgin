-- course_simple.module now supports video modules (module_type='video',
-- subtitles jsonb, sentences varchar[] added directly on the table). Add
-- the one missing piece: the module's own video URL — there's nowhere
-- else on the row to hold it.
ALTER TABLE course_simple.module ADD COLUMN IF NOT EXISTS video_url varchar;
