
ALTER TABLE users ADD COLUMN address text DEFAULT 'jrootham@gmail.com' NOT NULL;

CREATE TABLE tokens
(
	server_token BIGINT PRIMARY KEY,
	user_id INT REFERENCES users(id)
);
