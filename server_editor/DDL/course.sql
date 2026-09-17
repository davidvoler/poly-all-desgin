create schema if not exists course;

drop table if exists course.course;
create table course.course (
    course_id serial primary key,
    school varchar(255) not null,
    user_id int8 not null,
    lang varchar(12) not null,
    to_lang varchar(12) not null,
    level varchar(30) not null,
    title varchar(255) not null,
    description text,
    deleted boolean default false,
    status varchar(50), -- draft, reviewed, published, archived
    course_options jsonb,
    created_at timestamp default current_timestamp,
    updated_at timestamp default current_timestamp
);
drop table if exists course.course_words;   
-- do we need course words
create table course_words (
    lang varchar(12) not null,
    course_id int, 
    module_id int,
    lesson_id int,
    word varchar(255) not null,
    translation text,
    deleted boolean default false
);

drop table if exists course.sentences;
create table course.sentences(
    lang varchar(12) not null,
    sentence_id serial primary key,
    course_id int,
    module_id int,
    lesson_id int,
    word1 varchar(100),
    word2 varchar(100),
    word3 varchar(100),
    word4 varchar(100),
    sentence varchar(355) not null,
    translation text
);
drop table if exists course.module;
create table course.module (
    module_id serial primary key,
    course_id int not null,
    title varchar(255) not null,
    description text,
    deleted boolean default false,
    weight int2 DEFAULT 0 NULL
);

drop table if exists course.lesson;
create table course.lesson (
    lesson_id serial primary key,
    module_id int not null,
    course_id int not null,
    title varchar(255) not null,
    description text,
    words varchar(100)[],
    deleted boolean default false,
    weight int2 DEFAULT 0 NULL
);

drop table if exists course.exercise;
create table course.exercise (
    exercise_id serial primary key,
    course_id int,
    module_id int,
    lesson_id int ,
    exercise_type varchar(100),
    question varchar(255),
    options jsonb,
    explanation text,
	sentence_alt1 varchar(300) NULL,
	sentence_alt2 varchar(300) NULL,
    sentence_alt3 varchar(300) NULL,
	ruby_text jsonb NULL,
	annotations jsonb NULL,
	answer varchar(300) NULL,
    weight int2 DEFAULT 0 NULL
);


drop table if exists course.video;
create table course.video (
    video_id serial primary key,
    course_id int,
    module_id int,
    lang varchar(12) not null,
    url varchar(500) not null,
    raw_subtitles text,
    deleted boolean default false,
    weight int2 DEFAULT 0 NULL
);
drop table if exists course.subtitles;
create table course.subtitles(
    subtitles_id serial primary key,
    video_id varchar(255) ,
    lang varchar(12) ,
    start_time int ,
    duration int ,
    text varchar(355),
    weight int  default 0
);




