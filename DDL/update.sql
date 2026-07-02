

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

ALTER TABLE course_simple.course ADD COLUMN metadata jsonb;




ALTER TABLE course_simple.course ADD COLUMN edit_stage varchar(20) default 'draft';
ALTER TABLE course_simple.course ADD COLUMN access varchar(20) default 'private';
ALTER TABLE course_simple.course ADD COLUMN share_edit varchar(20) default 'private';
ALTER TABLE course_simple.course ADD COLUMN copied_from int8 default 0;



DROP TABLE IF EXISTS school.school_users;
CREATE TABLE school.school_users (
	school_id int4 NOT NULL,
	user_id int4 NOT NULL,
    roles varchar(20)[] NULL ,
	status varchar(20) DEFAULT 'active'::character varying NOT NULL,
	signed_terms_version int8 DEFAULT NULL,
	created_at timestamp DEFAULT now(),
	CONSTRAINT school_user PRIMARY KEY (school_id, user_id)
);
DROP TABLE IF EXISTS school.schools;
CREATE TABLE school.schools (
	school_id serial4 NOT NULL,
	school_url varchar(64) NOT NULL,
	school_dashboard_url varchar(64) NOT NULL,
	"name" varchar(255) NOT NULL,
	"plan" varchar(32) DEFAULT 'free'::character varying NOT NULL,
	is_public bool DEFAULT false NOT NULL,
	school_type varchar(20) DEFAULT 'private'::character varying NOT NULL,
	streak_days int4 DEFAULT 0 NOT NULL,
	languages_taught _varchar DEFAULT '{}'::character varying[] NOT NULL,
	native_languages _varchar DEFAULT '{}'::character varying[] NOT NULL,
	logo_url varchar(500) NULL,
	primary_color varchar(8) DEFAULT '#1E88E5'::character varying NOT NULL,
	created_at timestamp DEFAULT now() NOT NULL,
	updated_at timestamp DEFAULT now() NOT NULL,
	CONSTRAINT schools_pkey PRIMARY KEY (school_id),
	CONSTRAINT schools_url_uq UNIQUE (school_url),
	CONSTRAINT schools_dashboard_url_uq UNIQUE (school_dashboard_url)
);

DROP TABLE IF EXISTS school.terms_acceptances;
CREATE TABLE school.terms_acceptances (
	terms_id int8 NOT NULL,
    terms_version int8 NOT NULL,
    language varchar(12) NOT NULL,
	school_id int8 NOT NULL,
    user_id int8 NOT NULL,
	accepted_at timestamp DEFAULT now() NOT NULL,
	CONSTRAINT terms_acceptances_pkey PRIMARY KEY (terms_id, school_id, user_id)
);

DROP TABLE IF EXISTS school.terms;
CREATE TABLE school.terms (
	terms_id  serial4 PRIMARY KEY NOT NULL,
    terms_version int8 NOT NULL DEFAULT 1,
    language varchar(12) NOT NULL,
    title varchar(255) NOT NULL,
    body text NOT NULL,
	created_at timestamp DEFAULT now() NOT NULL,
	updated_at timestamp DEFAULT now() NOT NULL
);
DROP TABLE IF EXISTS school.super_admins;






drop TABLE IF EXISTS school.school_invitations;
CREATE TABLE school.school_invitations (
	invitation_id serial4 NOT NULL,
	school int8 default 1,
    invitation_code varchar(50) NOT NULL,
    created_at timestamp DEFAULT now(),
    redeemed_at timestamp NULL,
    expiration timestamp NULL,
    max_uses int4 default 1,
    uses_count int4 default 0,
	CONSTRAINT school_invitations_pkey PRIMARY KEY (invitation_id)
);

drop TABLE IF EXISTS school.course_invitations;
CREATE TABLE school.course_invitations (
	invitation_id serial4 NOT NULL,
	school int8 default 1,
    course_id int8 default 0,
    invitation_code varchar(50) NOT NULL,
    created_at timestamp DEFAULT now(),
    redeemed_at timestamp NULL,
    expiration timestamp NULL,
    max_uses int4 default 1,
    uses_count int4 default 0,
	CONSTRAINT course_invitations_pkey PRIMARY KEY (invitation_id)
);





insert INTO school.schools (school_url, school_dashboard_url, name, plan, is_public, school_type,logo_url) VALUES
('localhost', 'localhost', 'local', 'free', true, 'public', 'polyglots_social_logo.png'),
('app.polyglots.social', 'dashboard.polyglots.social', 'polyglots.social', 'free', true, 'public', 'polyglots_social_logo.png'),
('school1.app.polyglots.social', 'school1.dashboard.polyglots.social', 'school1', 'free', true, 'public', 'school1_logo.png');

Alter table user_data.users add column school_id int8 default 1;


insert INTO school.school_users ( user_id,school_id, roles) 
VALUES
(6,1,'{super_admin,school_admin,teacher}'),
(6,2,'{super_admin,school_admin,teacher}'),
(6,3,'{super_admin,school_admin,teacher}');




CREATE TABLE user_data.preference (
	user_id int4 NOT NULL,
	school_id int8 DEFAULT 1 NULL,
	ui_lang varchar(12) NULL,
	lang varchar(12) DEFAULT ''::character varying NOT NULL,
	to_lang varchar(12) DEFAULT ''::character varying NULL,
	course_id int4 NULL,
	module_id int4 NULL,
	lesson_id int4 NULL,
	created_at date DEFAULT now() NULL,
	updated_at date DEFAULT now() NULL,
	lesson_name varchar(300) NULL,
	module_name varchar(300) NULL,
	course_name varchar(300) NULL,
	quiz_settings jsonb NULL,
	CONSTRAINT preference_pkey PRIMARY KEY (user_id,school_id, lang)
);
DROP TABLE IF EXISTS user_data.preference;

-- DONE
alter table course_simple.course add column school_id int8 default 1;