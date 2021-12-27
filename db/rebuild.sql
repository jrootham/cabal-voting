DROP DATABASE IF EXISTS friday;
CREATE DATABASE friday;

\c friday
\i newvoting.sql

\copy users FROM users.csv CSV
\copy papers FROM papers.csv CSV
\copy paper_references FROM references.csv CSV

ALTER SEQUENCE users_id_seq RESTART WITH 13;
ALTER SEQUENCE papers_id_seq RESTART WITH 37;
ALTER SEQUENCE paper_references_id_seq RESTART WITH 13;
