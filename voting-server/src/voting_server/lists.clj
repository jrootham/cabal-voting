(ns voting-server.lists
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
	(:require [clojure.data.json :as json])
	(:require [ring.util.response :as response])
	(:require [voting-server.util :as util])
	(:require [voting-server.stuff :as stuff])
)


(defn get-user [nameValue]
	(let 
		[
			query "SELECT id,admin FROM users WHERE name =? AND valid;"
			result (jdbc/query stuff/db-spec [query nameValue])
		]
		(if (== 1 (count result))
			(first result)
			nil
		)
	)
)

(defn get-link [link-id]
	(first (jdbc/query stuff/db-spec ["SELECT link_text, link FROM links WHERE id=?;" link-id]))
)

(defn get-reference-mapper []
	(fn [reference]
		{
			"reference_index" (get reference :reference_index)
			"link" (get-link (get reference :link_id))
		}
	)
)

(defn get-references [paper-id]
	(let 
		[
			query "SELECT reference_index,link_id FROM comment_references WHERE paper_id=?;"
			result (jdbc/query stuff/db-spec [query paper-id])
		]
		(doall (map (get-reference-mapper) result))
	)
)

(defn get-votes [paper-id]
	(let
		[
			columns " votes,users.name AS name"
			from " FROM votes "
			join1 "JOIN users ON votes.user_id = users.id " 
			join2 "JOIN papers ON votes.paper_id = papers.id "
			where "WHERE votes.paper_id=? AND papers.closed_at IS NULL"
			query (str "SELECT" columns from join1 join2 where ";")
		]
		(doall (jdbc/query stuff/db-spec [query paper-id]))
	)
)

(defn make-paper-apply []
	(fn [paper]
		(let [paper-id (get paper :id)]
			{
				"paper_id" paper-id
				"title" (get paper :title)
				"submitter" (get paper :submitter)
				"paper" (get-link (get paper :link_id))
				"paper_comment" (get paper :paper_comment)
				"created_at" (get paper :created_at)
				"references" (get-references paper-id)
				"votes" (get-votes paper-id)
			}
		)
	)
)


(defn get-paper-list [] 
	(let [
			columns "id, title, link_id, paper_comment, created_at, users.name AS submitter"
			from " FROM papers JOIN users ON papers.user_id = users.id"
			where " papers.closed_at IS NULL"
			query (str "SELECT " columns from " WHERE" where	";")
			result (jdbc/query stuff/db-spec [query])
			map-fn (make-paper-apply)
		]
		(doall(map map-fn result))
	)
)

(defn reload [db]
	(json/write-str {:body {:paper_list (get-paper-list db)}})
)


(defn return-user-list []
	{:body {:user_list (jdbc/query stuff/db-spec ["SELECT id,name,valid,admin FROM users"])}}
)

(defn return-open-list []
	(let
		[
			id-column "papers.id AS paper_id,"
			title-column "papers.title AS title,"
			comment-column "papers.paper_comment AS paper_comment,"
			votes-column "coalesce(sum(votes.votes),0) AS total_votes "

			columns (str "SELECT " id-column title-column comment-column votes-column)
			
			from "FROM papers,votes "

			where "WHERE papers.closed_at IS NULL AND papers.id = votes.paper_id "

			group "GROUP BY papers.id"
		]

		{:body {:paper_list (jdbc/query stuff/db-spec [(str columns from where group ";")])}}
	)
)

(defn return-closed-list []
	(let 
		[
			columns "id, closed_at, title, paper_comment "
			where "NOT closed_at IS NULL "
			query (str "SELECT " columns " FROM papers WHERE " where ";")
		]
		{:body {:paper_list (jdbc/query stuff/db-spec [query])}}
	)
)

(defn admin-list [list-fn admin]
	(if (some? admin)
		(if admin
			(list-fn)
			(util/return-error "User not an administrator")
		)
		(util/return-error  "Session not found")
	)
)

