-- Create with AI — align with the existing module/lesson/exercise CRUD
-- convention discovered in TASKS.md ("API Manual planning": always POST,
-- ids in the request body) and the existing course_simple.lesson.words
-- text[] column, instead of a separate course_word_id join table.

-- lesson_word is no longer used — word selection lives on
-- course_simple.lesson.words (text[]) directly, like every other lesson
-- column.
DROP TABLE IF EXISTS course_simple.lesson_word;

-- lesson_sentence now stores the word string directly (matching
-- lesson.words) instead of a course_word_id FK.
ALTER TABLE course_simple.lesson_sentence
    ADD COLUMN IF NOT EXISTS word varchar(200);
ALTER TABLE course_simple.lesson_sentence
    DROP COLUMN IF EXISTS course_word_id;
