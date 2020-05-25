CREATE TABLE tokens
(
    server_token BIGINT PRIMARY KEY,
    user_id INT REFERENCES users(id)
);

