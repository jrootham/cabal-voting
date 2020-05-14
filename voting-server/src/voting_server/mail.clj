(ns voting-server.mail
	(:gen-class)
	(:require [clj-http.client :as client])
	(:require [voting-server.stuff :as stuff])
)

; constants

(def std-from "jim.rootham@utoronto.ca")

;  general mail functions

(defn mail-config [from to subject body]
	{
		:oauth-token stuff/mail-key
		:content-type :applicaton/json
		:form-params
		{
			:personalizations[{:to [{:email to}]}]
			:from {:email from}
			:subject subject
			:content [{:type "text/html" :value body}]
		}
	}
)

(defn send-mail [from to subject body]
	(client/post "https://api.sendgrid.com/v3/mail/send" (mail-config from to subject body))
)

