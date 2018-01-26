CREATE TABLE closed (
    closed_id SERIAL PRIMARY KEY,
    paper_id INTEGER NOT NULL REFERENCES papers,
    closed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO closed (paper_id) SELECT paper_id FROM papers WHERE NOT open_paper;
