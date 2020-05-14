(ns voting-server.register
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
	(:require [clojure.string :as str])
;	(:require [hiccup.core :as hiccup])
	(:require [hiccup.util :as util])
	(:require [hiccup.form :as form])
	(:require [valip.core :as valip])
	(:require [valip.predicates :as pred])
	(:require [voting-server.config :as config])
	(:require [voting-server.stuff :as stuff])
	(:require [voting-server.html :as html])
	(:require [voting-server.login :as login])
;	(:require [voting-server.app :as app])
)

(defn register-prompt-form [name address useapp error-list]
	[:div
		(form/form-to [:post "/servers/voting/register"]
			[:div
				(html/show-errors error-list)
				(html/group [:div {:id "register-group"}]
					[
						(html/label-text-field :name "User name" name) 
						(html/label-text-field :address "Email address" address)
						(html/label-checkbox :useapp "Use EMLogin application" useapp)
					]
				)

				(form/submit-button "Register")
			]
		)
	]
)

(defn register-prompt-contents [name address useapp error-list]
	[:body [:div (register-prompt-form name address useapp error-list)]]
)

(defn register-prompt [name address useapp error-list]
	(html/page (register-prompt-contents name address useapp error-list))
)

;  registration actions, mail, page

(defn validate-name [db name]
	(let
		[
			query "SELECT COUNT(*) AS count FROM users WHERE valid AND users.name=?;"
			result (jdbc/query db [query name])
		]
		(if (= 0 (get (first result) :count))
			[]
			[(str name " already exists")]
		)
	)
)

(defn validate-address [address]
	(let
		[
			package {:address address}
			message (str address " is not a valid email address")
			errors (valip/validate package [:address pred/email-address? message])
		]
		(get errors :address)
	)
)

(defn insert-user [db name address]
	(let [result (jdbc/insert! db :users {:name name :address address})]
		(get (first result) :id)
	)
)

(defn register-contents [name address]
	[:div
		[:div (str (util/escape-html name) " has been registered at " (util/escape-html address))]
		[:div "An email will be sent to the email address you entered with a link to log in to the site with."]	
	]
)

(defn register-app-contents [name address]
	[:div
		[:div (str (util/escape-html name) " has been registered at " (util/escape-html address))]
		(config/config-link name)
	]
)

(defn register-page [name address]
	(html/page (register-contents name address))
)

(defn register-app-page [name address]
	(html/page (register-app-contents name address))
)

(defn register [useapp name address]
	(jdbc/with-db-transaction [db stuff/db-spec]
		(let [error-list (concat (validate-address address) (validate-name db name))]
			(if (= 0 (count error-list))
				(let [user-id (insert-user db name address)]
					(if useapp
						(register-app-page name address)
						(do
							(login/login-email db user-id name address)
							(register-page name address)
						)
					)
				)
				(register-prompt name address useapp error-list) 
			)
		)
	)
)

