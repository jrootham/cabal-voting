(ns voting-server.core
  	(:gen-class)
	(:require [ring.adapter.jetty :as ring])
	(:require [ring.middleware.params :as params])
	(:require [ring.middleware.session :as session])
	(:require [ring.middleware.resource :as resource])
	(:require [compojure.core :as compojure])
	(:require [compojure.route :as route])
	(:require [clojure.string :as str])
;	(:require [ring-debug-logging.core :as debug])
	(:require [voting-server.register :as register])
	(:require [voting-server.login :as login])
	(:require [voting-server.config :as config])
	(:require [voting-server.html :as html])
	(:require [voting-server.vote :as vote])
	(:require [voting-server.paper :as paper])
	(:require [voting-server.lists :as lists])
)

(compojure/defroutes voting
	(compojure/GET "/servers/voting/register-prompt" [] (register/register-prompt "" "" false []))
	(compojure/POST "/servers/voting/register" [useapp name address] 
		(register/register useapp name address))

	(compojure/GET "/servers/voting/request-prompt" [] (login/request-prompt "" []))
	(compojure/POST "/servers/voting/request" [name] (login/request name))
	(compojure/GET "/servers/voting/app-request" [identifier token] 
		(login/app-request identifier token))

	(compojure/GET "/servers/voting/config-request-prompt" [] (register/config-request-prompt "" []))
	(compojure/POST "/servers/voting/config-request" [name] (register/config-request name))
	(compojure/GET "/servers/voting/config" [name] (config/config name))

	(compojure/GET "/servers/voting/launch" [server-token] (login/launch server-token))
	(compojure/GET "/servers/voting/login" [server-token] (login/login server-token))

	(compojure/GET "/servers/voting/load" [] (lists/do-load))

	(compojure/POST "/servers/voting/save" [paper user-id] (paper/edit-paper user-id paper))
	(compojure/POST "/servers/voting/close" [paper-id user-id time] 
		(paper/close user-id paper-id time))

	(compojure/POST "/servers/voting/vote" [paper-id user-id] (vote/vote user-id paper-id))
	(compojure/POST "/servers/voting/unvote" [paper-id user-id] (vote/unvote user-id paper-id))


	(compojure/GET "/favicon.ico" [] {:status 404})
	(route/resources "/servers/voting/")
	(route/not-found {:status 404 :body (html/page [:div "Page not found"])})
)

(defn wrap-session-user-id [handler]
	(fn [request]
		(let 
			[
				session (get request :session)
				params (get request :params)
				value (get session :user-id)
			]
			(if value
				(handler (assoc request :params (assoc params :user-id value)))
				(handler request)
			)
		)
	)
)

(defn make-handler [] 
	(-> voting
;		(debug/wrap-with-logger)
		(wrap-session-user-id)
		(params/wrap-params)
		(session/wrap-session)
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
