(ns voting-server.login
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
	(:require [clojure.string :as str])
	(:require [hiccup.core :as hiccup])
	(:require [hiccup.page :as page])
	(:require [hiccup.form :as form])
	(:require [clojure.data.json :as json])
	(:require [crypto.random :as random])
	(:require [voting-server.mail :as mail])
	(:require [voting-server.html :as html])
	(:require [voting-server.styles :as styles])
	(:require [voting-server.stuff :as stuff])
)


(defn make-token []
	(Long/parseUnsignedLong (random/hex 8) 16)
)

(defn request-prompt-contents [name error-list]
	[:div
		[:h2 {:style styles/h2} "Request Signon"]
		[:div {:style styles/para} (str "Please enter your user name for the site " stuff/site-name ".")]
		[:div {:style styles/para} "An email will be sent to the email address we have on file with a link to sign on to the site with."]
		(form/form-to [:post "request"]
			(html/show-errors error-list)
			(html/group [:div {:style styles/login-group}] [(html/label-text-field :name "User name " name)])
			(form/submit-button "Request Signon")
		)
	]
)

(defn request-prompt [name error-list]
	(html/page (request-prompt-contents name error-list))
)

(defn mail-contents [server-token name]
	[:body
		[:div
			[:h1 (str  stuff/site-name " Sign on")]
			[:div (str "Voting System sign on for " name)]
			[:div [:a {:href (html/href server-token)} "Sign on"]]
		]
	]
)

(defn body [head server-token name]
	(page/html5 head (mail-contents server-token name))
)

(defn mail [db user-id server-token subject head name address]
	(jdbc/insert! db :tokens {:server_token server-token :user_id user-id})
	(mail/send-mail address subject (body head server-token name))
)

(defn request-body [name address]
	[:div 
		[:h2 {:style styles/h2} "Signon Requested"]
		[:div {:style styles/para} (str "User " name " at " address " has requested a sign on")]
		[:div {:style styles/para} "An email will be sent to the email address we have on file with a link to sign on to the site with."]	
	]
)

(defn request-page [name address]
	(html/page (request-body name address))
)

(defn get-user [db name]
	(jdbc/query db ["SELECT id, name, address FROM users WHERE valid AND name=?;" name])
)

(defn make-request [name server-token subject headers found not-found]
	(jdbc/with-db-transaction [db stuff/db-spec]
		(let [result (get-user db name)]
			(if (== 1 (count result))
				(let [{user-id :id address :address} (first result)]
					(mail db user-id server-token subject headers name address)
					(found name address)
				)
				(not-found name)
			)
		)
	)	
)

(defn app-subject [app-token]
	(format "[#! emsignon %s] Voting Login" app-token)
)

(defn app-found [name address]
	{:status 200 :body ""}
)
					
(defn app-not-found [name]
	{:status 404 :body (str name " not found")}
)

(defn app-request [name app-token]
	(let 
		[
			server-token (make-token)
			subject (app-subject app-token)
			head (html/app-head server-token)
		]
		(make-request name server-token subject head app-found app-not-found)
	)
)

(def simple-subject "Voting Login")

(defn found [name address]
	(request-page name address)
)

(defn not-found [name]
	(request-prompt name [(str "Name " name " not found")])
)

(defn request [name]
	(make-request name (make-token) simple-subject (html/mail-head) found not-found)
)

(defn login-email [db user-id name address]	
	(mail db user-id (make-token) simple-subject (html/mail-head) name address)
)

(defn fetch-token-user [db server-token]
	(let
		[
			query "SELECT user_id FROM tokens WHERE server_token=?;"
			result (jdbc/query db [query server-token])
		]
		(if (== 1 (count result))
			(let [user-id (get (first result) :user_id)]
				(jdbc/delete! db :tokens ["server_token=?" server-token])
				user-id
			)
			nil
		)
	)
)

(defn start-session [body user-id]
	{:body (json/write-str body) :session {:user-id user-id}}
)

(defn user-error []
	{:status 400 :body (json/write-str {:error "User name not found"})}
)

(defn name-response [user-id]
	(if user-id
		(let 
			[
				query "SELECT name FROM users WHERE id=?;"
				result (jdbc/query stuff/db-spec [query user-id])
			]
			(if (== 1 (count result))
				(let [name (get (first result) :name)]
					(start-session name user-id)
				)
				(user-error)
			)
		)
		(user-error)
	)
)

(defn parse-token-string [server-token-string]
	(let [trimmed (str/trim server-token-string)]
		(Long/parseUnsignedLong trimmed 16)
	)
)

(defn launch [server-token-string]
	(html/elm-page (parse-token-string server-token-string))
)

(defn login [server-token-string]
	(jdbc/with-db-transaction [db stuff/db-spec]
		(let [server-token (parse-token-string server-token-string)]
			(if (== 0 server-token)
				(start-session nil 0)
				(name-response (fetch-token-user db server-token))
			)
		)
	)
)
