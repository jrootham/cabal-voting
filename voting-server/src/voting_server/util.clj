(ns voting-server.util
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
	(:require [voting-server.stuff :as stuff])
)

(defn debug [t x] 
	(println t x)
	x
)

(defn rules []
	(let 
		[
			columns "max_papers,max_votes,max_votes_per_paper"
			query (str "SELECT " columns " FROM config WHERE id=1")
		]
		(first (jdbc/query stuff/db-spec [query]))
	)
)

