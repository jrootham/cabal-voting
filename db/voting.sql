--
-- PostgreSQL database dump
--
-- Modified to only do the required things
--

--
-- Name: comment_references; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE comment_references (
    comment_reference_id SERIAL PRIMARY KEY,
    paper_id integer NOT NULL REFERENCES papers(paper_id),
    reference_index integer NOT NULL,
    link_id integer NOT NULL REFERENCES links(link_id)
);

--
-- Name: config; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE config (
    config_id integer DEFAULT 1 NOT NULL,
    max_papers integer NOT NULL,
    max_votes integer NOT NULL,
    max_votes_per_paper integer NOT NULL
);


--
-- Name: links; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE links (
    link_id SERIAL PRIMARY KEY,
    link_text text NOT NULL,
    link text NOT NULL
);


--
-- Name: papers; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE papers (
    paper_id SERIAL PRIMARY KEY,
    user_id integer NOT NULL REFERENCES users(user_id),
    title text NOT NULL,
    link_id integer NOT NULL REFERENCES links(link_id),
    paper_comment text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    open_paper boolean DEFAULT true NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name text NOT NULL,
    valid boolean DEFAULT true NOT NULL,
    user_admin boolean DEFAULT false NOT NULL,
    rules_admin boolean DEFAULT false NOT NULL,
    paper_admin boolean DEFAULT false NOT NULL
);

--
-- Name: votes; Type: TABLE; Schema: public; Owner: jrootham; Tablespace: 
--

CREATE TABLE votes (
    vote_id SERIAL PRIMARY KEY,
    paper_id integer NOT NULL REFERENCES papers(paper_id),
    user_id integer NOT NULL REFERENCES users(user_id),
    votes integer NOT NULL,
    CONSTRAINT votes_votes_check CHECK ((votes >= 0))
);

