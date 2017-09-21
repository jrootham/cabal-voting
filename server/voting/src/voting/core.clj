(ns voting.core
  (:gen-class)
	(:require [ring.middleware.cors :refer [wrap-cors]])
	(:use ring.adapter.jetty)
	(:require [ring.middleware.json :refer [wrap-json-response wrap-json-body]]
         [ring.util.response :refer [response]])
	(:require [clojure.java.jdbc :refer :all :as jdbc])
	(:use voting.config)
)

(defn login [request]
	(assoc request :user-id nil))

(def not-logged-in {:error "User invalid"})

(defn get-paper-list [request] 
	{:paper-list {}}
)

(defn output [request]
	{
		:status 200
		:headers {"Content-Type" "application/json"}
		:body (if (get request :user-id) (get-paper-list request) not-logged-in)
	}
)

(defn vote [request]
	request
)

(defn paper [request]
	request
)

(defn pipeline [request]
	(output (vote (paper (login request))))
)

(defn cors [handler]
  (wrap-cors handler :access-control-allow-origin [#".*"]
                     :access-control-allow-methods [:post]))

(def handler (cors (wrap-json-response (wrap-json-body pipeline))))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!"))
