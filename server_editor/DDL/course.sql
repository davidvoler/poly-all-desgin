create table course.course (
    course_id serial primary key,
    school varchar(255) not null,
    user int8 not null,
    lang varchar(12) not null,
    to_lang varchar(12) not null,
    level varchar(30) not null,
    title varchar(255) not null,
    deleted boolean default false,
    status varchar(50), -- draft, reviewed, published, archived
    description text,
    course_options jsonb,
    created_at timestamp default current_timestamp,
    updated_at timestamp default current_timestamp
);

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

create table course.module (
    module_id serial primary key,
    course_id int not null,
    title varchar(255) not null,
    description text
);

create table course.lesson (
    lesson_id serial primary key,
    module_id int not null,
    course_id int not null,
    title varchar(255) not null
);

create table course.exercise (
    exercise_id serial primary key,
    course_id int,
    module_id int,
    lesson_id int ,
    exercise_type varchar(30),
    question varchar(255),
    options jsonb,
    explanation text
);




