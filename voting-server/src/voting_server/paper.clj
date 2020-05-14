(ns voting-server.paper
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
;	(:require [ring.util.json-response :as json])
	(:require [voting-server.lists :as lists])
	(:require [voting-server.util :as util])
	(:require [voting-server.stuff :as stuff])
)

(defn get-owner [db paper-id]
	(let [query "SELECT user_id FROM papers WHERE paper_id=?"]
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
		(jdbc/insert! db :comment_references
			{
				"paper_id" paper-id
				,"reference_index" (get reference "index")
				,"link_id" (get-new-id (jdbc/insert! db :links (get reference "link")))
			}
		)
	)
)

(defn add-reference-list [db paper-id reference-list]
	(doall(map (make-add-reference db paper-id) reference-list))
)

(defn add-a-paper [db user-id paper]
	(let [
			link-id (get-new-id (jdbc/insert! db :links (get paper "paper")))
			paper-record 
				{
					"user_id" user-id
					,"title" (get paper "title")
					,"link_id" link-id
					,"paper_comment" (make-empty (get paper "comment"))
				}
			references (get paper "references")
		]
			
		(add-reference-list db (get-new-id (jdbc/insert! db :papers paper-record)) references)
	)

	(lists/reload db)
)

(defn can-add-paper [db user-id]
	(let 
		[
			count-query "SELECT COUNT(*) AS paper_count FROM papers WHERE closed_at IS NULL AND user_id=?;"
			paper-count (get (first (jdbc/query db [count-query user-id])) :paper_count)
			max-query "SELECT max_papers FROM config WHERE config_id=1;"
			max (get (first (jdbc/query db [max-query])) :max_papers)
		]
		(< paper-count max)
	)
)

(defn add-paper [db user-id paper]
	(if (can-add-paper db user-id)
		(add-a-paper db user-id paper)
		(util/return-error "User cannot add any more papers")
	)
)

(defn update-a-paper [db paper-id paper]
	(let 
	[
		query "SELECT link_id FROM papers WHERE paper_id=?"
		old-link-id (get (first (jdbc/query db [query paper-id])) :link_id)
		new-link-id (get-new-id (jdbc/insert! db :links (get paper "paper")))
		paper-record 
			{
				,"title" (get paper "title")
				, "link_id" new-link-id
				, "paper_comment" (make-empty (get paper "comment"))
			}
	]

		(jdbc/update! db :papers paper-record ["paper_id = ?" paper-id])
		(jdbc/delete! db :links ["link_id = ?" old-link-id])
		(jdbc/delete! db :comment_references ["paper_id = ?" paper-id])
		(add-reference-list db paper-id (get paper "references"))

		(lists/reload db)
	)	
)

(defn update-paper [db user-id paper-id paper]
	(if (== (get-owner db paper-id) user-id)
		(update-a-paper db paper-id paper)
		(util/return-error "User did not submit paper")
	)
)

(defn edit-paper [user-id paper]
	(jdbc/with-db-transaction [db stuff/db-spec]
		(if (some? user-id)
			(let [paper-id (get paper "paper_id")]
				(if (== paper-id 0)
					(add-paper db user-id paper)
					(update-paper db user-id paper-id paper)
				)
			)
			(util/return-error  "User id not found")
		)
	)
)

(defn close-paper [paper-id]
	(jdbc/execute! stuff/db-spec ["UPDATE papers SET closed_at = NOW() WHERE paper_id = ?" paper-id])
)

(defn unclose-paper [paper-id]
	(jdbc/execute! stuff/db-spec ["UPDATE papers SET closed_at = NULL WHERE paper_id = ?" paper-id])
)

(defn user-close [paper-id]
	(close-paper paper-id)
	(lists/reload stuff/db-spec)
)

(defn close [user-id paper-id]
	(if (some? user-id)
		(if (== (get-owner stuff/db-spec paper-id) user-id)
			(user-close paper-id)
			(util/return-error  "User did not submit paper")
		)
		(util/return-error  "Session not found")
	)
)

