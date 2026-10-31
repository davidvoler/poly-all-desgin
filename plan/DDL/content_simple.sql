-- course.course definition

-- Drop table

-- DROP TABLE course.course;

CREATE TABLE course_simple.course (
	course_id serial4 NOT NULL,
	lang varchar(12) NOT NULL,
	to_lang varchar(12) NOT NULL,
	user_id varchar(100) NULL,
	title varchar(255) NOT NULL,
	description text NULL,
	level int2 DEFAULT 0 NULL,
	lesson_count int2 DEFAULT 0 NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	CONSTRAINT course_pkey PRIMARY KEY (course_id)
);


-- "content"."module" definition

-- Drop table

-- DROP TABLE "content"."module";

CREATE TABLE course_simple."module" (
	course_id int8 NOT NULL,
	module_id serial4 NOT NULL,
	title varchar(255) NOT NULL,
	description text NULL,
	weight int2 DEFAULT 0 NULL,
	words _varchar NULL,
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

CREATE TABLE course_simple.exercise (
	course_id int8 NOT NULL,
	module_id int8 NOT NULL DEFAULT 0,
	lesson_id int8 NOT NULL,
	exercise_id serial4 NOT NULL,
	exercise_type varchar(100) ,
	sentence varchar(300) DEFAULT '' NULL,
	options jsonb DEFAULT '{}'::jsonb NULL,
	audio varchar(300) DEFAULT '' NULL,
	word1 varchar(100) DEFAULT '',
	word2 varchar(100) DEFAULT '',
	word3 varchar(100) DEFAULT '',
	sentence_id int8 NULL,
	to_sentence_id int8 NULL,
	explanation text NULL,
	weight int2 DEFAULT 0 NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	CONSTRAINT exercise_pkey PRIMARY KEY (exercise_id)
);





