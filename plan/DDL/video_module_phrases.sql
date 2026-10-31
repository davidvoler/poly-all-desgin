-- Video modules also get "phrases" — subtitles split on both commas and
-- full stops (finer-grained than `sentences`, which only splits on '.').
ALTER TABLE course_simple.module ADD COLUMN IF NOT EXISTS phrases varchar[];
