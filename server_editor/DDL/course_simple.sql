CREATE TABLE course_simple.course (
	course_id serial4 NOT NULL,
	lang varchar(12) NOT NULL,
	to_lang varchar(12) NOT NULL,
	user_id varchar(100) NULL,
	title varchar(255) NOT NULL,
	description text NULL,
	"level" varchar(4) DEFAULT ''::character varying NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	school varchar(255) DEFAULT 'pgs'::character varying NULL,
	lesson_count int2 DEFAULT 0 NULL,
	status varchar(20) DEFAULT 'draft'::character varying NOT NULL,
	owner_user_id int4 NULL,
	metadata jsonb NULL,
	share_edit varchar(20) DEFAULT 'private'::character varying NULL,
	"access" varchar(20) DEFAULT 'private'::character varying NULL,
	edit_stage varchar(20) DEFAULT 'draft'::character varying NULL,
	copied_from int8 DEFAULT 0 NULL,
	school_id int8 DEFAULT 1 NULL,
	active_revision int8 DEFAULT 0 NULL,
	words jsonb DEFAULT '[]'::jsonb NOT NULL,
	kind varchar(20) DEFAULT 'ai'::character varying NOT NULL,
	videos jsonb DEFAULT '[]'::jsonb NOT NULL,
	modules jsonb DEFAULT '[]'::jsonb NOT NULL,
	CONSTRAINT course_kind_chk CHECK (((kind)::text = ANY ((ARRAY['ai'::character varying, 'video'::character varying])::text[]))),
	CONSTRAINT course_pkey PRIMARY KEY (course_id),
	CONSTRAINT course_status_chk CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'review'::character varying, 'published'::character varying, 'archived'::character varying])::text[])))
);

-- %%
-- course_simple.course_sentences definition

-- Drop table

-- DROP TABLE course_simple.course_sentences;

CREATE TABLE course_simple.course_sentences (
	id_hash int8 NOT NULL,
	lang varchar(12) NOT NULL,
	provider varchar(100) NULL,
	model varchar(100) NULL,
	corpus varchar(12) NULL,
	corpus_id varchar(30) NULL,
	"text" varchar(300) NOT NULL,
	gen bool DEFAULT false NULL,
	"options" _varchar DEFAULT ARRAY[]::character varying[] NULL,
	word1 varchar(100) DEFAULT ''::character varying NULL,
	word2 varchar(100) DEFAULT ''::character varying NULL,
	word3 varchar(100) DEFAULT ''::character varying NULL,
	word4 varchar(100) DEFAULT ''::character varying NULL,
	CONSTRAINT sentences_pkey PRIMARY KEY (lang, id_hash)
);

-- %%
-- course_simple.exercise definition

-- Drop table

-- DROP TABLE course_simple.exercise;

CREATE TABLE course_simple.exercise (
	course_id int8 NOT NULL,
	module_id int8 DEFAULT 0 NOT NULL,
	lesson_id int8 NOT NULL,
	exercise_id serial4 NOT NULL,
	exercise_type varchar(100) NULL,
	sentence varchar(300) DEFAULT ''::character varying NULL,
	"options" jsonb DEFAULT '{}'::jsonb NULL,
	audio varchar(300) DEFAULT ''::character varying NULL,
	word1 varchar(100) DEFAULT ''::character varying NULL,
	word2 varchar(100) DEFAULT ''::character varying NULL,
	word3 varchar(100) DEFAULT ''::character varying NULL,
	sentence_id int8 NULL,
	to_sentence_id int8 NULL,
	explanation text NULL,
	weight int2 DEFAULT 0 NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	sentence_alt3 varchar(300) NULL,
	sentence_alt1 varchar(300) NULL,
	sentence_alt2 varchar(300) NULL,
	ruby_text jsonb NULL,
	annotations jsonb NULL,
	answer varchar(200) NULL,
	CONSTRAINT exercise_pkey PRIMARY KEY (exercise_id)
);

-- %%

-- %%
CREATE TABLE course_simple.lesson (
	lesson_id serial4 NOT NULL,
	course_id int8 NOT NULL,
	module_id int8 DEFAULT 0 NOT NULL,
	title varchar(255) NOT NULL,
	description text NULL,
	words _varchar NULL,
	weight int2 DEFAULT 0 NULL,
	annotations jsonb NULL,
	ruby_text1 jsonb NULL,
	ruby_text2 jsonb NULL,
	ruby_text3 jsonb NULL,
	status varchar(20) DEFAULT 'draft'::character varying NOT NULL,
	sentences jsonb DEFAULT '[]'::jsonb NOT NULL,
	CONSTRAINT lesson_pkey PRIMARY KEY (lesson_id),
	CONSTRAINT lesson_status_chk CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'ready'::character varying])::text[])))
);



-- course_simple."module" definition

-- Drop table

-- DROP TABLE course_simple."module";

CREATE TABLE course_simple."module" (
	course_id int8 NOT NULL,
	module_id serial4 NOT NULL,
	title varchar(255) NOT NULL,
	description text NULL,
	weight int2 DEFAULT 0 NULL,
	words _varchar NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	module_type varchar(20) NULL,
	subtitles jsonb NULL,
	sentences _varchar NULL,
	video_url varchar NULL,
	phrases _varchar NULL,
	CONSTRAINT module_pkey PRIMARY KEY (module_id)
);


-- course_simple.sentence definition

-- Drop table

-- DROP TABLE course_simple.sentence;

CREATE TABLE course_simple.sentence (
	sentence_id int8 NOT NULL,
	lang varchar(12) NOT NULL,
	"text" varchar(300) NOT NULL,
	gloss varchar(300) DEFAULT ''::character varying NULL,
	created_at timestamp DEFAULT now() NULL,
	CONSTRAINT sentence_pkey PRIMARY KEY (sentence_id)
);