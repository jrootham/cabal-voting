(ns voting-server.mail
	(:gen-class)
	(:require [postal.core :as postal])
	(:require [voting-server.stuff :as stuff])
)

; constants

(defn mail-config [from to subject body]
	{
		:to to
		:from from
		:subject subject
		:body [{:type "text/html" :content body}]
	}
)

(defn send-mail [to subject body]
	(let [from (:user stuff/mail-spec)]
		(postal/send-message stuff/mail-spec (mail-config from to subject body))
	)
)

