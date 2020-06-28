(ns voting-server.rules
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
;	(:require [ring.util.json-response :as json])
;	(:require [voting-server.lists :as lists])
	(:require [voting-server.util :as util])
	(:require [voting-server.stuff :as stuff])
)

(defn rules []
	(let 
		[
			columns "max_papers,max_votes,max_votes_per_paper"
			query (str "SELECT " columns " FROM config WHERE id=1")
			record (first (jdbc/query stuff/db-spec [query]))
		]
		{:body record}
	)
)

(defn make-rules-record [rules]
	{
		:max_papers (get rules "max_papers")
		:max_votes (get rules "max_votes")
		:max_votes_per_paper (get rules "max_per_paper")
	}
)

(defn good-rules [record]
	(jdbc/update! stuff/db-spec :config record ["config_id=1"])
	{:body record}
)

(defn replace-rules [rules]
	(let [record (make-rules-record rules)]
		(if ( >= (get record :max_votes) (get record :max_votes_per_paper))
			(good-rules record)
			(util/return-error "Max votes cannot be less than max votes per paper")
		)
	)
)

(defn update-rules [rules admin]
	(if (some? admin)
		(if admin
			(replace-rules rules)
			(util/return-error "User not an administrator")
		)
		(util/return-error  "Session not found")
	)
)

