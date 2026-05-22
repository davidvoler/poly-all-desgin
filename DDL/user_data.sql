drop TABLE IF EXISTS user_data.users;
CREATE TABLE user_data.users (
	user_id serial4 NOT NULL,
	school VARCHAR(255) default 'pgs',
	email_hash varchar(100) NOT NULL,
	email varchar(200) NOT NULL,
	last_login timestamp DEFAULT now() NULL,
	first_login timestamp DEFAULT now() NULL,
	CONSTRAINT users_pkey PRIMARY KEY (email, user_id)
);


drop table user_data.preference;
CREATE TABLE IF NOT EXISTS user_data.preference (
    user_id   int4 NOT NULL,
	school VARCHAR(255) default 'pgs',
    ui_lang   VARCHAR(12),
    lang   VARCHAR(12)  NULL DEFAULT '',
    to_lang   VARCHAR(12) NULL DEFAULT '',
    course_id int4 null ,
    module_id int4 null, 
    lesson_id int4 null, 
    created_at   date  DEFAULT now(),
    updated_at   date  DEFAULT now(),
    CONSTRAINT preference_pkey PRIMARY KEY (user_id, lang)
);

-- users_data.results definition

-- Drop table

DROP TABLE IF EXISTS user_data.results;

CREATE TABLE user_data.results (
    id SERIAL4 PRIMARY KEY NOT NULL,
	user_id int4 NOT NULL,
	lang varchar(12) NOT NULL,
	to_lang varchar(12) NULL,
	course_id int8 DEFAULT 0 NULL,
	module_id int8 DEFAULT 0 NULL,
	lesson_id int8 DEFAULT 0 NULL,
	exercise_id int8 DEFAULT 0 NULL,
	exercise_type varchar(100) DEFAULT ''::character varying NULL,
	score REAL DEFAULT 0.0 NULL,
	attempts SMALLINT DEFAULT 0 NULL,
	answer_delay_ms int4 DEFAULT 0 NULL,
    word varchar(255) NULL,
    word1 varchar(255) NULL,
    word2 varchar(255) NULL,
    word3 varchar(255) NULL,
    sentence_id varchar(255) NULL,
	created_at timestamp DEFAULT now()
);

CREATE INDEX idx_results_user_lang_course ON users_data.results (user_id, lang, course_id, lesson_id); 

drop table if exests user_data.lesson_status;
create table if not exists user_data.lesson_status (
	user_id int4 NOT NULL,
	lang varchar(12) NOT NULL,
	course_id int8 DEFAULT 0 NULL,
	module_id int8 DEFAULT 0 NULL,
	lesson_id int8 DEFAULT 0 NULL,
	score REAL DEFAULT 0.0 NULL,
	skipped_count int2 DEFAULT 0,
	correct_count int2 DEFAULT 0,
	wrong_count int2 DEFAULT 0,	
	created_at timestamp DEFAULT now(),
	CONSTRAINT lesson_status_pkey PRIMARY KEY (user_id, lesson_id)
);


drop TABLE IF EXISTS user_data.achievements;
create table if not exists user_data.achievements (
	achievement_id SERIAL4 PRIMARY KEY NOT NULL,
	user_id int4 NOT NULL,
	course_id int8 DEFAULT 0 NULL,
	lang varchar(12) NOT NULL,
	achievement_type varchar(50) NOT NULL,
	count_elements int2 DEFAULT 0 NULL,
	created_at timestamp DEFAULT now()
);


drop table if exists user_data.practice_status;
create table if not exists user_data.practice_status (
	id SERIAL4 PRIMARY KEY NOT NULL,
	user_id int4 NOT NULL,
	lang varchar(12) NOT NULL,
	course_id int8 DEFAULT 0 NULL,
	words_count int2 DEFAULT 0 NULL,
	score REAL DEFAULT 0.0 NULL,
	skipped_count int2 DEFAULT 0,
	correct_count int2 DEFAULT 0,
	wrong_count int2 DEFAULT 0,	
	created_at timestamp DEFAULT now()
);


