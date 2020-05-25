--
-- PostgreSQL database dump
--
-- Modified to only do the required things

--
--
-- Name: config; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE config (
    id integer DEFAULT 1 NOT NULL,
    max_papers integer NOT NULL,
    max_votes integer NOT NULL,
    max_votes_per_paper integer NOT NULL
);

--
-- Name: users; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name text NOT NULL,
    address text DEFAULT 'jrootham@gmail.com' NOT NULL,
    valid boolean DEFAULT true NOT NULL,
    admin boolean DEFAULT false NOT NULL
);

CREATE TABLE tokens
(
    server_token BIGINT PRIMARY KEY,
    user_id INT REFERENCES users(id)
);

--
-- Name: links; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE links (
    id SERIAL PRIMARY KEY,
    link_text text NOT NULL,
    link text NOT NULL
);


--
-- Name: papers; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE papers (
    id SERIAL PRIMARY KEY,
    user_id integer NOT NULL REFERENCES users(id),
    title text NOT NULL,
    link_id integer NOT NULL REFERENCES links(id),
    paper_comment text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    closed_at timestamp without time zone DEFAULT NULL
);

--
-- Name: comment_references; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE comment_references (
    id SERIAL PRIMARY KEY,
    paper_id integer NOT NULL REFERENCES papers(id),
    reference_index integer NOT NULL,
    link_id integer NOT NULL REFERENCES links(id)
);


--
-- Name: votes; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    paper_id integer NOT NULL REFERENCES papers(id),
    user_id integer NOT NULL REFERENCES users(id),
    votes integer NOT NULL,
    CONSTRAINT votes_votes_check CHECK ((votes >= 0))
);


INSERT INTO config (max_papers, max_votes, max_votes_per_paper) VALUES (5, 15, 5);
INSERT INTO users (name, address, admin) VALUES ('Jim', 'jrootham@gmail.com', TRUE);
