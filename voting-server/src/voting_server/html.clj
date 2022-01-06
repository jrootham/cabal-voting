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
	(format "%s/servers/voting/launch?server-token=%016x" stuff/site server-token)
)

;  The three possible headers

(defn mail-head []
	""
)

(defn browser-head []
	[:head 
		[:title stuff/site-name]
		[:link {:rel "stylesheet" :type "text/css" :href "voting.css"}]
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
			[:div {:id "title"} stuff/site-name]
			[:div {:id "container"} contents]
		]
	)
)

(defn elm-page [server-token]
	(let 
		[
			flags (format "{title: '%s', token: '%16x'}" stuff/site-name server-token)
			script-form "var app = Elm.Main.init({node: document.getElementById('voting'), flags: %s})"
			script (format script-form flags)
		]
		(hiccup/html
			[:head
				[:title stuff/site-name]
				[:link {:rel "stylesheet" :type "text/css" :href "voting.css"}]
				[:script {:src "main.js"}]
			]
			[:body [:div {:id "voting"}] [:script script]]
		)
	)
)

