-- course.course definition

-- Drop table

-- DROP TABLE course.course;

CREATE TABLE course.course (
	course_id serial4 NOT NULL,
	lang varchar(12) NOT NULL,
	to_lang varchar(12) NOT NULL,
	user_id varchar(100) NULL,
	title varchar(255) NOT NULL,
	description text NULL,
	level int2 DEFAULT 0 NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	CONSTRAINT course_pkey PRIMARY KEY (courseid)
);


-- "content"."module" definition

-- Drop table

-- DROP TABLE "content"."module";

CREATE TABLE "content"."module" (
	module_id serial4 NOT NULL,
	course_id int8 NOT NULL,
	title varchar(255) NOT NULL,
	description text NULL,
	weight int2 DEFAULT 0 NULL,
	words _varchar NULL,
	words_in_sentences _varchar NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	CONSTRAINT module_pkey PRIMARY KEY (module_id)
);


-- course.lesson definition

-- Drop table

-- DROP TABLE course.lesson;

CREATE TABLE course_simple.lesson (
	lesson_id serial4 NOT NULL,
	course_id int8 NOT NULL,
	module_id int8 DEFAULT 0 NOT NULL ,
	title varchar(255) NOT NULL,
	description text NULL,
	words _varchar NULL,
	CONSTRAINT lesson_pkey PRIMARY KEY (lesson_id)
);

-- "content".exercise definition

-- Drop table

-- DROP TABLE "content".exercise;

CREATE TABLE "content".exercise (
	exercise_id serial4 NOT NULL,
	course_id int8 NOT NULL,
	module_id int8 NOT NULL DEFAULT 0,
	lesson_id int8 NOT NULL,
	weight int2 DEFAULT 0 NULL,
	exercise_type varchar(100) ,
	title varchar(300) NULL,
	instruction varchar(300) NULL,
	sentence varchar(300) DEFAULT ''::character varying NULL,
	correct_options _varchar NULL,
	wrong_options _varchar NULL,
	annotated_sentence jsonb DEFAULT '{}'::jsonb NULL,
	extra_data jsonb DEFAULT '{}'::jsonb NULL,
	explanation text NULL,
	audio_link varchar(300) DEFAULT ''::character varying NULL,
	word1 varchar(100) DEFAULT ,
	word2 varchar(100) DEFAULT ,
	word3 varchar(100) DEFAULT ,
	sentence_id int8 NULL,
	to_sentence_id int8 NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	CONSTRAINT exercise_pkey PRIMARY KEY (exercise_id)
);






drop table if exists course_simple.sentences_per_lesson ;
CREATE TABLE course_simple.sentences_per_lesson (
	exercise_id serial4 NOT NULL,
	sentence_id int8 NOT NULL, 
    to_sentence_id int8 NULL,    
    word varchar(100) NULL,
    words _varchar NULL,
    options _varchar NULL,
    to_options _varchar NULL,
    audio_link varchar(300) NULL,
    words_so_far _varchar NULL,
	CONSTRAINT sentences_per_lesson_pkey PRIMARY KEY (exercise_id)
);