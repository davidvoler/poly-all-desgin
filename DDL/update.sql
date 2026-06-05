

-- add school

ALTER TABLE user_data.users ADD COLUMN school VARCHAR(255) default 'pgs';
ALTER TABLE course_simple.course ADD COLUMN school VARCHAR(255) default 'pgs';


alter table user_data.results RENAME COLUMN mark TO score;
ALTER TABLE course_simple.course ADD COLUMN lesson_count int2 default 0;

-- Password support for the learner app's local-test login flow.
-- bcrypt hashes are 60 chars; the column is intentionally NULLABLE so
-- Auth0-issued accounts (which carry no local password) keep working.
ALTER TABLE user_data.users ADD COLUMN password_hash VARCHAR(100);



ALTER TABLE user_data.preference ADD COLUMN course_name VARCHAR(300);
ALTER TABLE user_data.preference ADD COLUMN module_name VARCHAR(300);
ALTER TABLE user_data.preference ADD COLUMN lesson_name VARCHAR(300);


CREATE TABLE user_data.user_roles (
    user_id int4 NOT NULL,
    school_id int4 NOT NULL,
    role varchar(50) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
	CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, school_id, role)
);

ALTER TABLE course_simple.exercise ADD COLUMN sentence_alt1 VARCHAR(300);
ALTER TABLE course_simple.exercise ADD COLUMN sentence_alt2 VARCHAR(300);
ALTER TABLE course_simple.exercise ADD COLUMN sentence_alt3 VARCHAR(300);





create index idx_sentence_elements_lang_word1 on content_raw.sentence_elements (lang, len_c, word1, id);




alter table course_simple.lesson ADD COLUMN weight int2 default 0;

-- Quiz display preferences (text size, text-alternative, ruby mode,
-- annotations). Free-form jsonb owned by the client.
ALTER TABLE user_data.preference ADD COLUMN quiz_settings jsonb;
ALTER TABLE course_simple.exercise ADD COLUMN ruby_text jsonb;
ALTER TABLE course_simple.exercise ADD COLUMN annotations jsonb;
-- DONE

-- Course-level display metadata: which reading/alternative variants the
-- course offers and how to label them in the quiz. Shape:
--   {
--     "ruby_text":    [{"name": "hiragana", "icon": "translate",
--                       "tooltip_text": "Hiragana reading"}, ...],
--     "sentence_alt": [{"slot": 1, "name": "Diacritics", "icon": "format_size",
--                       "tooltip_text": "With diacritical marks"}, ...]
--   }
-- Lets the app render variant pickers from data instead of hardcoded
-- per-language labels. Free-form jsonb; null/empty falls back to defaults.
ALTER TABLE course_simple.course ADD COLUMN metadata jsonb;
-- DONE


