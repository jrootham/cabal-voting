SELECT 
	user_id AS id
	,name AS name
	,'jrootham@gmail.com' AS address
	,valid AS valid 
	INTO TEMPORARY users_out
	FROM users ORDER BY id;
	
\copy users_out TO users.csv WITH CSV;

SELECT papers.paper_id AS id
	,papers.user_id AS user_id
	,papers.title AS title
	,links.link AS link
	,papers.paper_comment AS paper_comment
	,FLOOR(EXTRACT (EPOCH FROM papers.created_at)) AS created_at
	,NULL AS closed_at
	INTO TEMPORARY papers_out
	FROM papers,links WHERE papers.link_id = links.link_id
	ORDER BY id;

\copy papers_out TO papers.csv WITH CSV;

SELECT comment_references.comment_reference_id AS id
	,comment_references.paper_id AS paper_id
	,comment_references.reference_index AS reference_index
	,links.link_text AS link_text
	,links.link AS link
	INTO TEMPORARY references_out
	FROM comment_references,links WHERE comment_references.link_id=links.link_id
	ORDER BY id;

\copy references_out TO references.csv WITH CSV;
