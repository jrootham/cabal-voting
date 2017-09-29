(ns parser.core
  (:gen-class)
	(:require [clojure.java.jdbc :refer :all :as jdbc])
	(:use clojure.java.jdbc)
	(:require [clojure.java.io :as io])
	(:require [org.httpkit.client :as http])
	(:require [clojure.data.json :as json])
)



(def url-regex #"http([0-9a-zA-Z;/?:@=&$-_.+!*'(),]*)")

(defn get-link[body]
	(first (re-find url-regex body))
)

(defn get-new-id[result]
	(second (first (first result)))
)

(defn get-name-id [db name]
	(let [name-record (query db ["SELECT user_id FROM users WHERE name=?" name])]
		(if (== 1 (count name-record))
			(get (first name-record) :user_id)
			(get-new-id (insert! db :users {:name name}))
		)
	)
)

(defn make-link [db text link]
	(get-new-id (insert! db :links {:text text, :link link}))
)

(defn save-paper [db paper link]
	(let
		[
			title (get paper "title")
			created-at (get paper "createdAt")
			body (get paper "body")
			submitter-name (get-in paper ["author" "login"])
			submitter (get-name-id db submitter-name)
			record 
				{
					:user_id submitter
					:title title
					:link_id (make-link db "Paper" link)
					:paper_comment body
					:created_at created-at
				}
		]
		(get-new-id (insert! db :papers record))
	)
)

(defn make-cast [db paper-id]
	(fn [raw]
		(let [user-id (get-name-id db (get-in raw ["user" "login"]))]
			(insert! db :votes {:paper_id paper-id, :user_id user-id, :votes 3})
		)
	)
)

(defn cast-votes [db paper link]
	(let [
		paper-id (save-paper db paper link)
		raw-votes (get-in paper ["reactions" "nodes"])
		]
		(doall(map (make-cast db paper-id) raw-votes))
	)
)

(defn make-save[db]
	(fn [paper]
		(let [link (get-link (get paper "body"))]
			(if link (cast-votes db paper link))
		)
	)
)

(defn update-db [db-file body]
	(with-db-connection [db {:dbtype "sqlite" :dbname db-file}]
		(let 
			[
				parsed (json/read-str body)
				paper-list (get-in parsed ["data" "repository" "issues" "nodes"])
			]
			(doall (map (make-save db) paper-list))
			(println "Done")
		)
	)
)

(defn update-data [db-file user password query-string]
	(let [
			payload {:query query-string :variables {:owner "CompSciCabal" :name "SMRTYPRTY"}}
			options 
				{
	              :basic-auth [user password]
	              :user-agent "Cabal Voting System"
	              :body (json/write-str payload)
              	}
         ]


	(http/post "https://api.github.com/graphql" options
          	(fn [{:keys [status headers body error]}] ;; asynchronous response handling
            	(if error
              		(println "Failed, exception is " error)
              		(update-db db-file body)
    			)
    		)
    	)
	)
)

(defn -main
  "Convert github issues to voting database"
  [& args]
  (if (== 1 (count args))
	  (let 
	  	[
	  		db-file (first args)
	  		graphql-query (slurp(io/input-stream "graphql.query"))
	  		_ (println "User name:")
	  		user (read-line)
	 		_ (println "password:")
	  		password (read-line)
	   	]
	   	(update-data db-file user password graphql-query)
	   	(read-line)
	  )
	  (println "Usage: lein run db-file")
	)
)
