(ns voting-server.admin
	(:gen-class)
	(:require [clojure.java.jdbc :as jdbc])
	(:require [voting-server.lists :as lists])
	(:require [voting-server.paper :as paper])
	(:require [voting-server.util :as util])
	(:require [voting-server.stuff :as stuff])
)

(defn add-user [db user-record]
	(jdbc/insert! stuff/db-spec :users user-record)
	(lists/return-user-list)
)

(defn change-user [user-id user-record]
	(jdbc/update! stuff/db-spec :users user-record ["id=?" user-id])
	(lists/return-user-list)
)

(defn make-user-record [user]
	{
		:name (get user "name")
		:admin (get user "admin")
		:valid (get user "valid")
	}
)

(defn edit-user [user]
	(let [user-id (get user "user_id")]
		(if (= user-id 0)
			(add-user (make-user-record user))
			(change-user user-id (make-user-record user))
		)
	)
)

(defn update-user [admin user]
	(if (some? admin)
		(if admin
			(edit-user user)
			(util/return-error "User not an administrator")
		)
		(util/return-error  "Session not found")
	)
)

(defn admin-close [paper-id]
	(paper/close-paper paper-id)
	(lists/return-open-list)
)

(defn admin-unclose [paper-id]
	(paper/unclose-paper paper-id)
	(lists/return-closed-list)
)

(defn admin-paper [action-fn admin paper-id]
	(if (some? admin)
		(if admin
			(action-fn paper-id)
			(util/return-error "User not an administrator")
		)
		(util/return-error  "Session not found")
	)
)

