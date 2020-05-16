(ns voting-server.util
	(:gen-class)
	(:require [clojure.data.json :as json])
	(:require [ring.util.response :as response])
)

(defn debug [x] 
	(println x)
	x
)

(defn return-error [message]
	(response/bad-request (json/write-str {:message message}))
)

