create schema if not exists users;
create table if not exists users.user (
    user_id serial primary key,
    school varchar(255) not null,
    username varchar(255) not null,
    email varchar(255) not null,
    password varchar(255) not null,
    permissions jsonb,
    preferences jsonb,
    created_at timestamp default current_timestamp,
    updated_at timestamp default current_timestamp
);
