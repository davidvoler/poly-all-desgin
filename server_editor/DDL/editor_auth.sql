-- Editor login: which school an editor site belongs to, and courses keyed by
-- the school's id. course_simple.course.school and secrets.ai_api_key.school
-- hold the school_id as text (e.g. '1').

-- The editor's hostname for each school, like school_url / school_dashboard_url.
alter table school.schools add column if not exists school_editor_url varchar(64);
create unique index if not exists schools_editor_url_uq on school.schools (school_editor_url);

-- Local development: the editor runs on localhost for school 1.
update school.schools set school_editor_url = 'localhost'
where school_id = 1 and school_editor_url is null;
-- Production, for example:
-- update school.schools set school_editor_url = 'editor.polyglots.social' where school_id = 2;
-- update school.schools set school_editor_url = 'school1.editor.polyglots.social' where school_id = 3;

-- Courses saved before the login used school names; move them to school 1.
update course_simple.course set school = '1' where school in ('local', 'pgs');
