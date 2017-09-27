(ns voting.core-test
  (:require [clojure.test :refer :all]
            [voting.core :refer :all])
  (:use [clojure.java.shell :only [sh]])
  (:require [clojure.data.json :as json])
  (:use voting.core)
  )
(def test-db "db/test.db")

(use-fixtures :each (fn [f] (sh "test/voting/setup.sh") (f) ) )

(defn test-body [matching from]
	(println "Starting test_body" matching from)
	(let 
		[body (get from :body)]
		(println "Starting every" matching body)
			(every? (fn [key] (println "key" key)(= (get body key) (get matching key))) (keys matching))
	)
)

(def bad-login {:body (json/write-str {:user "other"})})

; (deftest test-test
; 	(testing "test-body"
; 		(is (= true (test-body {:bar (list {:a 1})} {:body {:foo 1 :bar (list {:a 1})}})))
; 	)
; )

(deftest logon
  (testing "Bad logon"
    (is (= true (test-body {:error ""} (json/read-str ((make-handler test-db) bad-login))))) 
  )
)
