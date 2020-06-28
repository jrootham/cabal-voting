(ns voting-server.lists
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
	(:require [clojure.data.json :as json])
	(:require [ring.util.response :as response])
	(:require [voting-server.util :as util])
	(:require [voting-server.stuff :as stuff])
)

(defn get-reference-list [paper-id]
	(let [ query "SELECT reference_index,link,link_text FROM paper_references WHERE paper_id=?;"]
		(jdbc/query stuff/db-spec [query paper-id])
	)
)

(defn get-vote-list [paper-id]
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
				"link" (get paper :link)
				"paper_comment" (get paper :paper_comment)
				"created_at" (get paper :created_at)
				"reference_list" (get-reference-list paper-id)
				"vote_list" (get-vote-list paper-id)
			}
		)
	)
)

(defn get-paper-list [db] 
	(let [
			columns "papers.id AS id, title, link, paper_comment, created_at, users.name AS submitter"
			from " FROM papers JOIN users ON papers.user_id = users.id"
			where " papers.closed_at IS NULL"
			query (str "SELECT " columns from " WHERE" where ";")
			result (jdbc/query db [query])
			map-fn (make-paper-apply)
		]
		(doall(map map-fn result))
	)
)

(defn reload [error]
	(if error
		(json/write-str {:error error :data nil})
		(let [paper-list (get-paper-list stuff/db-spec)]
			(json/write-str {:error nil :data {:data {:rules (util/rules) :paper_list paper-list}}})
		)
	)
)

(defn do-load []
	(reload nil)
)

