(ns voting-server.core
  	(:gen-class)
	(:require [ring.adapter.jetty :as ring])
	(:require [ring.middleware.params :as params])
	(:require [ring.middleware.session :as session])
	(:require [compojure.core :as compojure])
	(:require [compojure.route :as route])
	(:require [clojure.string :as str])
	(:require [ring-debug-logging.core :as debug])
	(:require [voting-server.stuff :as stuff])
	(:require [voting-server.register :as register])
	(:require [voting-server.login :as login])
	(:require [voting-server.config :as config])
	(:require [voting-server.html :as html])
	(:require [voting-server.admin :as admin])
	(:require [voting-server.vote :as vote])
	(:require [voting-server.paper :as paper])
	(:require [voting-server.rules :as rules])
	(:require [voting-server.lists :as lists])
)

(compojure/defroutes voting
	(compojure/GET "/servers/voting/register-prompt" [] (register/register-prompt "" "" false []))
	(compojure/POST "/servers/voting/register" [useapp name address] 
		(register/register useapp name address))

	(compojure/GET "/servers/voting/request-prompt" [] (login/request-prompt "" []))
	(compojure/POST "/servers/voting/request" [name] (login/request name))
	(compojure/GET "/servers/voting/app-request" [identifier token] (login/app-request identifier token))

	(compojure/GET "/servers/voting/config-request-prompt" [] (register/config-request-prompt "" []))
	(compojure/POST "/servers/voting/config-request" [name] (register/config-request name))
	(compojure/GET "/servers/voting/config" [name] (config/config name))

	(compojure/GET "/servers/voting/launch" [server-token] (login/launch server-token))
	(compojure/GET "/servers/voting/login" [server-token] (login/login server-token))

	(compojure/POST "/servers/voting/rules" [] (rules/rules))
	(compojure/POST "/servers/voting/reload" [] (lists/reload))

	(compojure/POST "/servers/voting/save" [paper user-id]
		(paper/edit-paper user-id paper))
	; (compojure/POST "/servers/voting/close" [paper-id {{user-id :user_id} :session}] 
	; 	(paper/close user-id paper-id))

	; (compojure/POST "/servers/voting/vote" [paper-id {{user-id :user_id} :session}] 
	; 	(vote/vote user-id paper-id))
	; (compojure/POST "/servers/voting/unvote" [paper-id {{user-id :user_id} :session}] 
	; 	(vote/unvote user-id paper-id))

	; (compojure/POST "/servers/voting/userList" [{{admin :admin} :session}] 
	; 	(list/admin-list lists/return-user-list admin))
	; (compojure/POST "/servers/voting/updateUser" [user {{admin :admin} :session}] 
	; 	(admin/update-user admin user))
	; (compojure/POST "/servers/voting/openList" [{{admin :admin} :session}] 
	; 	(lists/admin-list lists/return-open-list admin))
	; (compojure/POST "/servers/voting/adminClose" [paper-id {{admin :admin} :session}] 
	; 	(admin/admin-paper admin/admin-close admin paper-id))
	; (compojure/POST "/servers/voting/closedList" [{{admin :admin} :session}] 
	; 	(lists/admin-list lists/return-closed-list admin))
	; (compojure/POST "/servers/voting/adminUnclose" [paper-id {{admin :admin} :session}] 
	; 	(admin/admin-paper admin/admin-unclose admin paper-id))
	; (compojure/POST "/servers/voting/updateRules" [rules {{admin :admin} :session}]
	; 	(rules/update-rules rules admin))

	(compojure/GET "/favicon.ico" [] {:status 404})
	(route/resources "/servers/voting/")
	(route/not-found {:status 404 :body (html/page [:div "Page not found"])})
)

(defn make-wrap-session-param [param]
	(let [key (keyword param)]
		(fn [handler]
			(fn [request]
				(handler request)
			)
		)
	)
)

(def wrap-session-user-id (make-wrap-session-param "user"))

(defn make-handler [] 
	(-> voting
		(wrap-session-user-id)
		(params/wrap-params)
		(session/wrap-session)
;		(debug/wrap-with-logger)
	)
)

(defn -main
  	"Cabal voting server"
  	[& args]
  	(if (== 1 (count args))
			(let [portString (first args)]
				(try
					(let [port (Integer/parseInt portString)]
						(ring/run-jetty (make-handler) {:port port})
					)
					(catch NumberFormatException exception 
						(println (str portString " is not an int"))
					)
				)
			)  	
			(println "voting-server port")
	)
)
