(ns voting-server.paper
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
	(:require [cheshire.core :as json])
	(:require [voting-server.lists :as lists])
	(:require [voting-server.util :as util])
	(:require [voting-server.stuff :as stuff])
)

(defn get-owner [db paper-id]
	(let [query "SELECT user_id FROM papers WHERE id = ?;"]
		(get (first (jdbc/query db [query paper-id])) :user_id)
	)
)

(defn get-new-id[result]
	(second (first (first result)))
)

(defn make-empty [text]
	(if text text "")
)

(defn make-add-reference [db paper-id]
	(fn [reference]
		(jdbc/insert! db :paper_references
			{
				"paper_id" paper-id
				,"reference_index" (get reference "index")
				,"link_text" (get reference "link_text")
				,"link" (get reference "link")
			}
		)
	)
)

(defn add-reference-list [db paper-id reference-list]
	(doall(map (make-add-reference db paper-id) reference-list))
)

(defn add-a-paper [db user-id paper]
	(let [
			paper-record 
				{
					"user_id" user-id
					,"title" (get paper "title")
					,"link" (get paper "link")
					,"paper_comment" (make-empty (get paper "comment"))
					,"created_at" (get paper "created_at")
				}
			reference-list (get paper "reference_list")
			id (get-new-id (jdbc/insert! db :papers paper-record))
		]
			
		(add-reference-list db id reference-list)
		nil
	)
)

(defn can-add-paper [db user-id]
	(let 
		[
			count-query "SELECT COUNT(*) AS paper_count FROM papers WHERE closed_at IS NULL AND user_id=?;"
			paper-count (get (first (jdbc/query db [count-query user-id])) :paper_count)
			max (get (util/rules) :max_papers)
		]
		(< paper-count max)
	)
)

(defn add-paper [db user-id paper]
	(if (can-add-paper db user-id)
		(add-a-paper db user-id paper)
		"User cannot add any more papers"
	)
)

(defn update-a-paper [db paper-id paper]
	(let 
	[
		paper-record 
			{
				,"title" (get paper "title")
				, "link" (get paper "link")
				, "paper_comment" (make-empty (get paper "comment"))
			}
	]

		(jdbc/update! db :papers paper-record ["id = ?" paper-id])
		(jdbc/delete! db :paper_references ["paper_id = ?" paper-id])
		(add-reference-list db paper-id (get paper "reference_list"))
		nil
	)	
)

(defn update-paper [db user-id paper-id paper]
	(if (== (get-owner db paper-id) user-id)
		(update-a-paper db paper-id paper)
		"User did not submit paper"
	)
)

(defn edit-paper [user-id raw-paper]
	(lists/reload 
		(jdbc/with-db-transaction [db stuff/db-spec]
			(if (some? user-id)
				(let 
					[
						paper (json/parse-string raw-paper)
						paper-id (get paper "id")
					]
					(if (== paper-id 0)
						(add-paper db user-id paper)
						(update-paper db user-id paper-id paper)
					)
					nil 
				)
				"User id not found"
			)
		)
	)
)

(defn close-paper [paper-id time]
	(jdbc/execute! stuff/db-spec ["UPDATE papers SET closed_at = ? WHERE id = ?;" time paper-id])
	nil
)

(defn close [user-id paper-id-string time-string]
	(let
		[
			paper-id (Integer/parseInt paper-id-string)
			time (Integer/parseInt time-string)
		]
		(lists/reload 
			(if (some? user-id)
				(if (== (get-owner stuff/db-spec paper-id) user-id)
					(close-paper paper-id time)
					"User did not submit paper"
				)
				"Session not found"
			)
		)
	)
)

