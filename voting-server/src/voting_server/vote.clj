(ns voting-server.vote
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
;	(:require [ring.util.json-response :as json])
	(:require [voting-server.lists :as lists])
	(:require [voting-server.util :as util])
	(:require [voting-server.stuff :as stuff])
)

(defn total-votes [db user-id]
	(let
		[
			column "SUM(votes.votes) AS total_votes "
			tables "papers JOIN votes ON papers.id=votes.paper_id "
			where "papers.closed_at IS NULL AND votes.user_id=?;"
			query (str "SELECT " column "FROM " tables "WHERE " where)
			count-list (jdbc/query db [query user-id])
			vote-count (get (first count-list) :total_votes)
		]

		(if (some? vote-count)
			vote-count
			0
		)
	)
)

(defn cast-new-vote [db user-id paper-id]
	(jdbc/insert! db :votes {:paper_id paper-id, :user_id user-id, :votes 1})
	nil
)

(defn cast-vote [db user-id paper-id votes]
	(let [where "user_id=? AND paper_id=?"]
		(jdbc/update! db :votes {:votes (+ votes 1)} [where user-id paper-id])
		nil
	)
)

(defn uncast-vote [db user-id paper-id votes]
	(let [where "user_id=? AND paper_id=?"]
		(jdbc/update! db :votes {:votes (- votes 1)} [where user-id paper-id])
		nil
	)
)

(defn get-vote-entry [db user-id paper-id]
	(let
		[
			where "user_id=? AND paper_id=?"
			query (str "SELECT votes FROM votes WHERE " where ";")
		]
		(jdbc/query db [query user-id paper-id])
	)
)

(defn vote-for-paper [db user-id paper-id]
	(let
		[
			max-per-paper (get (util/rules) :max_votes_per_paper)
			vote-entry (get-vote-entry db user-id paper-id)
		]
		(if (== (count vote-entry) 0)
			(cast-new-vote db user-id paper-id)
			(let [votes (get (first vote-entry) :votes)]
				(if (< votes max-per-paper)
					(cast-vote db user-id paper-id votes)
					"User has no votes left for this paper"
				)
			)
		)
	)
)

(defn unvote [user-id paper-id-string]
	(lists/reload
		(jdbc/with-db-transaction [db stuff/db-spec]
			(if (some? user-id)
				(let 
					[
						paper-id (Integer/parseInt paper-id-string)
						vote-entry (get-vote-entry db user-id paper-id)
					]
					(if (> (count vote-entry) 0)
						(let [votes (get (first vote-entry) :votes)]
							(if (> votes 0)
								(uncast-vote db user-id paper-id votes)
								"Cannot reduce votes to less than 0"
							)
						)
						"Cannot reduce votes to less than 0"
					)
				)
				"User id not found"
			)
		)
	)
)

(defn vote [user-id paper-id-string]
	(lists/reload
		(jdbc/with-db-transaction [db stuff/db-spec]
			(if (some? user-id)
				(let 
					[
						paper-id (Integer/parseInt paper-id-string)
						max-query "SELECT max_votes FROM config WHERE id=1;"
						max (get (first (jdbc/query db [max-query])) :max_votes)
					]

					(if (> max (total-votes db user-id))
						(vote-for-paper db user-id paper-id)
						"User has used up his total votes"
					)
				)
				"User id not found"
			)
		)
	)
)
