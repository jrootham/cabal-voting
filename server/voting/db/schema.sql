CREATE TABLE config (
    config_id INTEGER PRIMARY KEY DEFAULT 1,
    max_papers INTEGER NOT NULL,
    max_votes INTEGER NOT NULL,
    max_votes_per_paper INTEGER NOT NULL
);

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    valid BOOLEAN NOT NULL DEFAULT TRUE,
    admin BOOLEAN NOT NULL DEFAULT FALSE,
);

CREATE TABLE links (
    link_id SERIAL PRIMARY KEY,
    link_text TEXT NOT NULL,
    link TEXT NOT NULL
);

CREATE TABLE papers (
    paper_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users,
    title TEXT NOT NULL,
    link_id INTEGER NOT NULL REFERENCES links,
    paper_comment TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE closed (
    closed_id SERIAL PRIMARY KEY,
    paper_id INTEGER NOT NULL REFERENCES papers,
    closed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE comment_references (
    comment_reference_id SERIAL PRIMARY KEY,
    paper_id INTEGER NOT NULL REFERENCES papers,
    reference_index INTEGER NOT NULL,
    link_id INTEGER NOT NULL REFERENCES links
);

CREATE TABLE votes (
    vote_id SERIAL PRIMARY KEY,
    paper_id INTEGER NOT NULL REFERENCES papers,
    user_id INTEGER NOT NULL REFERENCES users,
    votes INTEGER NOT NULL CHECK (votes >= 0)
);


