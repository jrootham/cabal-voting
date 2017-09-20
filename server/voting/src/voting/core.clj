(ns voting.core
  (:gen-class))

(defn handler [request]
  (let [_ (println request)] 
  	{:status 200
   :headers {"Content-Type" "application/json"}
   :body "{\"error\":\"User invalid\"}"
   }
  )
)


(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!"))
