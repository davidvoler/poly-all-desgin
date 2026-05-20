

-- add school

ALTER TABLE user_data.users ADD COLUMN school VARCHAR(255) default 'pgs';
ALTER TABLE course_simple.course ADD COLUMN school VARCHAR(255) default 'pgs';


