(ns voting.core
  (:gen-class)
	(:require [ring.middleware.cors :refer [wrap-cors]])
	(:use ring.adapter.jetty)
	(:require [ring.middleware.json :refer [wrap-json-response wrap-json-body]]
         [ring.util.response :refer [response]])
	(:require [clojure.java.jdbc :refer :all :as jdbc])
	(:use clojure.java.jdbc)
)

(defn make-empty [text]
	(if text text "")
)

(defn login [request]
	(let [
		body (get request :body)		
		db (get request :connection)
		nameValue (get body "user")
		result (query db ["SELECT user_id FROM users WHERE name =?" nameValue])
		]

		(if (= 1 (count result))
			(let [row (first result)] (assoc request :user_id (get row :user_id)))
			(assoc (assoc request :user_id nil) :error "User invalid")
		)
	)
)

(defn get-link [db link-id]
	(first (query db ["SELECT text, link FROM links WHERE link_id=?;" link-id]))
)

(defn get-reference-mapper [db]
	(fn [reference]
		{
			"reference_index" (get reference :reference_index)
			"link" (get-link db (get reference :link_id))
		}
	)
)

(defn get-references [db paper-id]
	(let 
		[
			query-string "SELECT reference_index,link_id FROM comment_references WHERE paper_id=?;"
			result (query db [query-string paper-id])
		]
			(doall (map (get-reference-mapper db) result))
	)
)

(defn get-votes [db paper-id]
	(let
		[
			columns " votes,users.name AS name"
			from " FROM votes JOIN users ON votes.user_id = users.user_id"
			where " WHERE votes.paper_id=?"
			query-string (str "SELECT" columns from where ";")
		]
			(doall (query db [query-string paper-id]))
	)
)

(defn make-paper-apply [db]
	(fn [paper]
		(let [paper-id (get paper :paper_id)]
			{
				"paper_id" paper-id
				"title" (get paper :title)
				"submitter" (get paper :submitter)
				"paper" (get-link db (get paper :link_id))
				"paper_comment" (get paper :paper_comment)
				"created_at" (get paper :created_at)
				"references" (get-references db paper-id)
				"votes" (get-votes db paper-id)
			}
		)
	)
)

(defn get-paper-list [request] 
	(let [
		body (get request :body)		
		db (get request :connection)
		columns "paper_id, title, link_id, paper_comment, created_at, users.name AS submitter"
		from " FROM papers JOIN users ON papers.user_id = users.user_id"
		query-string (str "SELECT " columns from " WHERE open_paper = 1;")
		result (query db [query-string])
		map-fn (make-paper-apply db)
		]
		(doall(map map-fn result))
	)
)

(defn make-body [request]
	(if (contains? request :error) 
		{:error (get request :error), :paper_list (list)} 
		{:error "", :paper_list (get-paper-list request)}
	)
)

(defn output [request]
	{
		:status 200
		:headers {"Content-Type" "application/json"}
		:body (make-body request)
	}
)

(defn vote [request]
	(let [
		body (get request :body)
		db (get request :connection)
	]
		(if (contains? body "increment")
			(let
				[
					user-id (get request :user_id)
					paper-id (get body "paper_id")
					increment (get body "increment")
					where "user_id=? AND paper_id=?"
					result (query db [(str "SELECT votes FROM votes WHERE " where ";") user-id paper-id])
				]
				(if (== 0 (count result))
					(insert! db :votes {:paper_id paper-id, :user_id user-id, :votes 1})
					(update! db :votes {:votes (+ increment (get (first result) :votes))} [where user-id paper-id])
				)
			)
		)
	)	
	request
)

(defn get-new-id[result]
	(second (first (first result)))
)

(defn make-add-reference [db paper-id]
	(fn [reference]
		(insert! db :comment_references
			{
				"paper_id" paper-id
				,"reference_index" (get reference "index")
				,"link_id" (get-new-id (insert! db :links (get reference "link")))
			}
		)
	)
)

(defn add_reference-list [db paper-id reference-list]
	(doall(map (make-add-reference db paper-id) reference-list))
)

(defn add-paper [db user-id paper]
	(let [
			link-id (get-new-id (insert! db :links (get paper "paper")))
			paper-record 
				{
					"user_id" user-id
					,"title" (get paper "title")
					, "link_id" link-id
					, "paper_comment" (make-empty (get paper "comment"))
				}
		]
			
		(add_reference-list db (get-new-id (insert! db :papers paper-record)) (get paper "references"))
	)	
)

(defn update-paper [db user-id paper]
	(let [
			paper-id (get paper "paper_id")
			query-string "SELECT link_id FROM papers WHERE paper_id=?"
			old-link-id (get (first (query db [query-string paper-id])) :link_id)
			new-link-id (get-new-id (insert! db :links (get paper "paper")))
			paper-record 
				{
					,"title" (get paper "title")
					, "link_id" new-link-id
					, "paper_comment" (make-empty (get paper "comment"))
				}
		]

		(update! db :papers paper-record ["paper_id = ?" paper-id])
		(delete! db :links ["link_id = ?" old-link-id])
		(delete! db :comment_references ["paper_id = ?" paper-id])
		(add_reference-list db paper-id (get paper "references"))
	)	
)

(defn paper [request]
	(let [
		body (get request :body)
		db (get request :connection)
	]
		(if (contains? body "paper")
			(let [paper (get body "paper") ]
				(if (== (get paper "paper_id") 0)
					(add-paper db (get request :user_id) paper)
					(update-paper db (get request :user_id) paper)
				)
			)
		)
	)
	
	request
)

(defn close [request]
	(let [
		body (get request :body)
		db (get request :connection)
	]
		(if (contains? body "close")
			(let
				[
					user-id (get request :user_id)
					paper-id (get body "paper_id")
				]
				(update! db :papers {:open_paper 0} ["paper_id = ?" paper-id])
			)
		)
	)
	request
)

(defn pipeline [request]
	(output (close (vote (paper (login request)))))
)

(defn make-wrap-db [db-file]
	(fn [handler]  
		(fn [req]    
			(with-db-connection [db {:dbtype "sqlite" :dbname db-file}]      
				(handler (assoc req :connection db))
			)
		)
	)
)

(defn cors [handler]
  (wrap-cors handler :access-control-allow-origin [#".*"]
                     :access-control-allow-methods [:post]))

(defn make-handler [db-file] 
	(let [wrap-db (make-wrap-db db-file)] 
		(cors (wrap-json-response (wrap-json-body (wrap-db pipeline))))
	)
)

(defn -main
  	"Cabal voting server"
  	[& args]
  	(if (= 2 (count args))
	  	(let 
	  		[
	  			port (Integer/parseInt (first args)) 
	  			db-file (second args)
	  		]
			(run-jetty (make-handler db-file) {:port port})  	
	  	)
	  (println "Usage: java -jar uberjar port dbfile")
	)
 )
