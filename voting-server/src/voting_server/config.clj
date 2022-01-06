(ns voting-server.config
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
	(:require [clojure.data.json :as json])
	(:require [ring.util.response :as response])
	(:require [voting-server.stuff :as stuff])
)

(defn config-link [name]
	(let [href (str stuff/site "/servers/voting/config?name=" name)]
		[:div [:a {:href href} "Configuration"]]
	)
)

(defn config-response [result]
	(let 
		[
			record (first result)
			{name :name address :address} record
			endpoint (str stuff/site "/servers/voting/app-request")
		]
		(json/write-str
			{
				:found true
				:name stuff/site-name 
				:endpoint endpoint 
				:identifier name 
				:address address
			}
		)
	)
)

(defn config [name]
	(let 
		[
			query "SELECT name, address FROM users WHERE valid AND name=?"
			result (jdbc/query stuff/db-spec [query name])
		]
		(if (== 1 (count result))
			(config-response result)
			(json/write-str {:found "false"})
		)
	)
)

