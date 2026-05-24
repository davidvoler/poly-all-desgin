

-- add school

ALTER TABLE user_data.users ADD COLUMN school VARCHAR(255) default 'pgs';
ALTER TABLE course_simple.course ADD COLUMN school VARCHAR(255) default 'pgs';


alter table user_data.results RENAME COLUMN mark TO score;
ALTER TABLE course_simple.course ADD COLUMN lesson_count int2 default 0;

-- Password support for the learner app's local-test login flow.
-- bcrypt hashes are 60 chars; the column is intentionally NULLABLE so
-- Auth0-issued accounts (which carry no local password) keep working.
ALTER TABLE user_data.users ADD COLUMN password_hash VARCHAR(100);
