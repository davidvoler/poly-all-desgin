-- users_data.results definition

-- Drop table

-- DROP TABLE users_data.results;

CREATE TABLE users_data.results (
    id SERIAL4 PRIMARY KEY NOT NULL,
	user_id varchar(100),
	lang varchar(12) NOT NULL,
	to_lang varchar(12) NULL,
	course_id int8 DEFAULT 0 NULL,
	module_id int8 DEFAULT 0 NULL,
	lesson_id int8 DEFAULT 0 NULL,
	exercise_id int8 DEFAULT 0 NULL,
	exercise_type varchar(100) DEFAULT ''::character varying NULL,
	mark SMALLINT DEFAULT 0,
	attempts SMALLINT DEFAULT 0 NULL,
	answer_delay_ms int4 DEFAULT 0 NULL,
    word1 varchar(255) NULL,
    word2 varchar(255) NULL,
    word3 varchar(255) NULL,
    sentence varchar(255) NULL,
	created_at timestamp DEFAULT now(),
	CONSTRAINT results_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_results_user_lang_course ON users_data.results (user_id, lang, course_id, lesson_id);