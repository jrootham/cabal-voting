(ns voting-server.register
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
	(:require [clojure.string :as str])
	(:require [hiccup.util :as hiccup])
	(:require [hiccup.form :as form])
	(:require [valip.core :as valip])
	(:require [valip.predicates :as pred])
	(:require [voting-server.config :as config])
	(:require [voting-server.stuff :as stuff])
	(:require [voting-server.html :as html])
	(:require [voting-server.styles :as styles])
	(:require [voting-server.login :as login])
)

(defn register-prompt-form [name address error-list]
	[:div
		[:h2 {:style styles/h2} "Request Registration"]
		(form/form-to [:post "register"]
			[:div
				(html/show-errors error-list)
				(html/group [:div {:style styles/register-group}]
					[
						(html/label-text-field :name "User name" name) 
						(html/label-text-field :address "Email address" address)
					]
				)

				(form/submit-button "Request Registration")
			]
		)
	]
)

(defn register-prompt-contents [name address error-list]
	[:body [:div (register-prompt-form name address error-list)]]
)

(defn register-prompt [name address error-list]
	(html/page (register-prompt-contents name address error-list))
)

;  registration actions, mail, page

(defn is-name [db name]
	(let
		[
			query "SELECT COUNT(*) AS count FROM users WHERE valid AND users.name=?;"
			result (jdbc/query db [query name])
		]
		(== 1 (get (first result) :count))
	)
)

(defn validate-name [db name]
	(if (is-name db name)
		[]
		[(str name " does not exist")]
	)
)

(defn validate-name-new [db name]
	(if (is-name db name)
		[(str name " already exists")]
		[]
	)
)

(defn unique-address [db address]
	(let
		[
			query "SELECT COUNT(*) AS count FROM users WHERE valid AND users.address=?;"
			result (jdbc/query db [query address])
		]
		(if (= 0 (get (first result) :count))
			[]
			[(str address " already exists")]
		)
	)
)

(defn validate-address [db address]
	(let [unique (unique-address db address)]
		(if (== 0 (count unique))
			(let
				[
					package {:address address}
					message (str address " is not a valid email address")
					errors (valip/validate package [:address pred/email-address? message])
				]
				(get errors :address)
			)
			unique
		)
	)
)

(defn insert-user [db name address]
	(let [result (jdbc/insert! db :users {:name name :address address})]
		(get (first result) :id)
	)
)

(defn register-contents [name address]
	[:div
		[:h2 {:style styles/h2} "Request Registration"]
		[:div {:style styles/para} (str (hiccup/escape-html name) " has been registered at " (hiccup/escape-html address))]
		[:div {:style styles/para} "An email will be sent to the email address you entered with a link to log in to the site with."]	
	]
)

(defn register-app-contents [name address]
	[:div
		[:h2 {:style styles/h2} "Request Registration"]
		[:div {:style styles/para} (str (hiccup/escape-html name) " has been registered at " (hiccup/escape-html address))]
		(config/config-link name)
	]
)

(defn register-page [name address]
	(html/page (register-contents name address))
)

(defn register-app-page [name address]
	(html/page (register-app-contents name address))
)

(defn config-request-prompt-contents [name error-list]
	[:div
		[:h2 {:style styles/h2} "Request Registration"]
		[:div {:style styles/para} (str "Please enter your desired user name for the site " stuff/site-name ".")]
		(form/form-to [:post "config-request"]
			(html/show-errors error-list)
			(html/group [:div {:style styles/login-group}] [(html/label-text-field :name "User name " name)])
			(form/submit-button "Request Registration")
		)
	]
)

(defn config-request-prompt [name error-list]
	(html/page (config-request-prompt-contents name error-list))
)

(defn config-contents [name]
	[:div (config/config-link name)]	
)

(defn config-request [name]
	(let [error-list (validate-name stuff/db-spec name)]
		(if (== 0 (count error-list))
			(html/page (config-contents name))
			(config-request-prompt name error-list)
		)
	)
)

(defn register [name address]
	(jdbc/with-db-transaction [db stuff/db-spec]
		(let [error-list (concat (validate-address db address) (validate-name-new db name))]
			(if (== 0 (count error-list))
				(let [user-id (insert-user db name address)]
					(if false
						(register-app-page name address)
						(do
							(login/login-email db user-id name address)
							(register-page name address)
						)
					)
				)
				(register-prompt name address error-list) 
			)
		)
	)
)

