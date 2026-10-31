CREATE TABLE draft.prompt (
	prompt_id SERIAL PRIMARY KEY,
    course_id INT NOT NULL,
    provider VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    prompt_text TEXT NOT NULL,
    enriched_prompt TEXT,
    detected_language VARCHAR(10),
    lang VARCHAR(10),
    to_lang VARCHAR(10),
    estimated_cost DECIMAL(10, 2),
    estimated_tokens INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	);

CREATE TABLE draft.model_response (
    response_id SERIAL PRIMARY KEY,
    prompt_id INT NOT NULL REFERENCES draft.prompt(prompt_id),
    provider VARCHAR(50),
    model VARCHAR(50), 
    response_text JSONB ,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE draft.sentences(
    lang VARCHAR(10) NOT NULL,
    sentence VARCHAR(300) NOT NULL,
    words VARCHAR(100)[],
    PRIMARY KEY (lang, sentence)
)

CREATE TABLE draft.words(
    lang VARCHAR(10) NOT NULL,
    word VARCHAR(100) NOT NULL,
    PRIMARY KEY (lang, word)
)