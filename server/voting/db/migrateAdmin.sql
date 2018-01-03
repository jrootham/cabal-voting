
ALTER TABLE users RENAME COLUMN user_admin TO admin;

ALTER TABLE users DROP COLUMN rules_admin;
ALTER TABLE users DROP COLUMN paper_admin;
