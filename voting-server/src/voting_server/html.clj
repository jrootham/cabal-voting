(ns voting-server.html
	(:gen-class)
	(:require [hiccup.core :as hiccup])
	(:require [hiccup.form :as form])
	(:require [hiccup.util :as util])
	(:require [voting-server.stuff :as stuff])
)

;  General html functions


(defn custom-meta [name content]
	[:meta {:name name :content content}]	
)
(defn label-text-field [text-name label-text value]
	[(form/label text-name label-text) (form/text-field text-name value)]
)

(defn label-checkbox [checkbox-name label-text checked]
	[(form/label checkbox-name label-text) (form/check-box checkbox-name checked)]
)

(defn group [group-head contents]
	(reduce (fn [rest next] (let [[a b] next] (conj (conj rest a) b))) group-head contents)
)

(defn show-errors [error-list]
	[:div (map (fn [line] [:div (util/escape-html line)]) error-list)]
)

(defn href [server-token]
	(format "%sservers/emlogin/login?server-token=%016x" stuff/site server-token)
)

;  The three possible headers

(defn mail-head []
	""
)

(defn browser-head []
	[:head 
		[:title "EMail Login"]
		[:link {:rel "stylesheet" :type "text/css" :href "emlogin.css"}]
	]
)

(defn app-head [server-token]
	[:head (custom-meta "eml-target" (href server-token))]
)

; The standard browser page

(defn page [contents]
	(hiccup/html
		(browser-head)
		[:div {:id "outer"}
			[:div {:id "title"} "EMail Login"]
			[:div {:id "container"} contents]
			[:div 
				[:div [:a {:href (str stuff/site "servers/emlogin/register-prompt")} "Register"]] 
				[:div [:a {:href (str stuff/site "servers/emlogin/request-prompt")} "Login"]] 
				[:div [:a {:href (str stuff/site "emlogin/index.html")} "Home"]]
			]
		]
	)
)
