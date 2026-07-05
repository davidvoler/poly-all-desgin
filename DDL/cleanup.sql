
create schema if not exists course;

--- course ---
CREATE TABLE course.course (
	course_id serial4 NOT NULL PRIMARY KEY,
	lang varchar(12) NOT NULL,
	to_lang varchar(12) NOT NULL,
	user_id int8 default 0 NULL,
	school_id int8 default 0 NULL,
	title varchar(255) NOT NULL,
	description text NULL,
	level varchar(30) NULL,
    published varchar(20) DEFAULT 'draft' NULL,
	access varchar(20) DEFAULT 'private' NULL,
	copied_from int8 DEFAULT 0 NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	metadata jsonb NULL
);

