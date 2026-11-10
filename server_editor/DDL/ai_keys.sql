-- AI provider API keys, encrypted by the editor server (utils/secret_box.py).
-- A school key has user_id NULL; a user key has both school and user_id.
-- Only the editor server's database role should be granted this schema.
create schema if not exists secrets;

create table if not exists secrets.ai_api_key (
    api_key_id  serial primary key,
    school      varchar(255) not null,
    user_id     int,
    provider    varchar(32)  not null,  -- gemini | claude | openai
    ciphertext  bytea        not null,  -- nonce + AES-GCM ciphertext
    key_version int          not null,  -- the master key that encrypted it
    last4       varchar(8)   not null,  -- shown in the UI instead of the key
    created_at  timestamptz  not null default now(),
    updated_at  timestamptz  not null default now(),
    -- One key per provider for the school, and one per provider for each user.
    constraint ai_api_key_owner_provider unique nulls not distinct (school, user_id, provider)
);
