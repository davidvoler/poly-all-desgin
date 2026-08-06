

drop TABLE IF EXISTS user_data.roles;
CREATE TABLE user_data.roles (
	user_id serial4 NOT NULL,
	school int8 default 1,
    role varchar(50) NOT NULL,
	CONSTRAINT roles_pkey PRIMARY KEY (user_id, school, role)
);

drop TABLE IF EXISTS user_data.school_invitations;
CREATE TABLE user_data.school_invitations (
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

drop TABLE IF EXISTS user_data.course_invitations;
CREATE TABLE user_data.course_invitations (
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

