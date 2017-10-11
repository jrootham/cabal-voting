CREATE TABLE "papers" (
    "paper_id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "user_id" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "link_id" INTEGER NOT NULL,
    "paper_comment" TEXT NOT NULL,
    "created_at" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "open_paper" INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE "users" (
    "user_id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "name" TEXT NOT NULL,
    "valid" INTEGER NOT NULL DEFAULT (1),
    "user_admin" INTEGER NOT NULL DEFAULT (0),
    "rules_admin" INTEGER NOT NULL DEFAULT (0),
    "paper_admin" INTEGER NOT NULL DEFAULT (0)
);
CREATE TABLE "links" (
    "link_id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "text" TEXT NOT NULL,
    "link" TEXT NOT NULL
);
CREATE TABLE "comment_references" (
    "comment_reference_id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "paper_id" INTEGER NOT NULL,
    "reference_index" INTEGER NOT NULL,
    "link_id" INTEGER NOT NULL
);

CREATE TABLE "votes" (
    "vote_id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "paper_id" INTEGER NOT NULL,
    "user_id" INTEGER NOT NULL,
    "votes" INTEGER NOT NULL
);

CREATE TABLE "config" (
    "config_id" INTEGER PRIMARY KEY NOT NULL DEFAULT(1),
    "max_papers" INTEGER NOT NULL,
    "max_votes" INTEGER NOT NULL,
    "max_votes_per_paper" INTEGER NOT NULL
);

