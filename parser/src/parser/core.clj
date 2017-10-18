(ns parser.core
  (:gen-class)
	(:require [clojure.java.jdbc :refer :all :as jdbc])
	(:use clojure.java.jdbc)
	(:require [clojure.java.io :as io])
	(:require [org.httpkit.client :as http])
	(:require [clojure.data.json :as json])
	(:require [clojure.string :as str])
	(:require [clj-time [format :as timef] [coerce :as timec]])
)

(def url-regex #"http([0-9a-zA-Z;/?:@=&$-_.+!*',~]*)")

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
	(get-new-id (insert! db :links {:link_text text, :link link}))
)

(defn get-references [reference-index reference-list body]
	(let [link (get-link body)]
		(if (str/blank? link)
			[reference-list, body]
			(let 
				[
					reference-name (str "Reference " reference-index)
					new-index (+ 1 reference-index)
					new-list (cons [reference-index reference-name link] reference-list)
					new-body (str/replace-first body link reference-name)
				]
				(get-references new-index new-list new-body)
			)
		)
	)
)

(defn make-references [db paper-id]
	(fn [reference]
		(let 
			[
				[reference-index reference-name link] reference
				link-id (make-link db reference-name link)
				record 
					{
						:paper_id paper-id
						:reference_index reference-index
						:link_id link-id
					}
			]
			(insert! db :comment_references record)
		)
	)
)

(defn format-timestamp [raw]
	(timec/to-timestamp (timef/parse (timef/formatter :date-time-no-ms) raw))
)

(defn save-paper [db paper link body]
	(let
		[
			title (get paper "title")
			created-at (format-timestamp(get paper "createdAt"))
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

(defn cast-votes [db paper link body]
	(let 
		[
			reference-result (get-references 1 [] body)
			reference-list (first reference-result)
			new-body (second reference-result)
			paper-id (save-paper db paper link new-body)
			raw-votes (get-in paper ["reactions" "nodes"])
		]
		(doall (map (make-references db paper-id) reference-list))
		(doall (map (make-cast db paper-id) raw-votes))
	)
)

(defn make-save[db]
	(fn [paper]
		(let [
				body (get paper "body")
				link (get-link body)
			]
			(if link 
				(cast-votes db paper link (str/replace-first body link ""))
			)
		)
	)
)

(defn fill-data [db]
	(update! db :users {:user_admin true} ["name=?" "jrootham"])
	(insert! db :config {:max_papers 5, :max_votes 15, :max_votes_per_paper 5})
)

(defn update-db [db-uri body]
	(with-db-connection [db {:connection-uri db-uri}]
		(let 
			[
				parsed (json/read-str body)
				paper-list (get-in parsed ["data" "repository" "issues" "nodes"])
			]
			(doall (map (make-save db) paper-list))
			(fill-data db)
			(println "Done")
		)
	)
)

(defn update-data [db-spec user github-password query-string]
	(let [
			payload {:query query-string :variables {:owner "CompSciCabal" :name "SMRTYPRTY"}}
			options 
				{
	              :basic-auth [user github-password]
	              :user-agent "Cabal Voting System"
	              :body (json/write-str payload)
              	}
         ]


	(http/post "https://api.github.com/graphql" options
          	(fn [{:keys [status headers body error]}] ;; asynchronous response handling
            	(if error
              		(println "Failed, exception is " error)
              		(update-db db-spec body)
    			)
    		)
    	)
	)
)

(defn get-uri [user db-name]
	(let
		[
	 		_ (println "database password:")
	  		password (read-line)
	  		db-password (str/replace password " " "+")
		]
		(str "jdbc:postgresql://localhost:5432/" db-name "?user=" user "&password=" db-password)
	)
)

(defn -main
  "Convert github issues to voting database"
  [& args]
  (if (== 1 (count args))
	  (let 
	  	[
	  		db-name (first args)
	  		db-password (second args)
	  		graphql-query (slurp(io/input-stream "graphql.query"))
	  		_ (println "User name:")
	  		user (read-line)
	 		_ (println "github password:")
	  		github-password (read-line)
	   	]
	   	(update-data (get-uri user db-name) user github-password graphql-query)
	   	(read-line)
	  )
	  (println "Usage: lein run db-name")
	)
)
