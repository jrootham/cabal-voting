(defproject voting "0.1.0-SNAPSHOT"
  :description "Cabal voting back end"
  :url "http://example.com/FIXME"
  :dependencies 
    [
				[org.clojure/clojure "1.8.0"]
				[ring/ring-core "1.6.2"]
				[ring/ring-jetty-adapter "1.6.2"]
				[ring-cors "0.1.11"]
				[ring/ring-json "0.4.0"]
				[org.clojure/clojure "1.8.0"]
				[org.xerial/sqlite-jdbc "3.20.0"]
				[org.clojure/java.jdbc "0.7.1"]
				[org.clojure/data.json "0.2.6"]
     ]
  :main ^:skip-aot voting.core
  :aot [voting.core]
  :target-path "target/%s"
  :profiles 
    {
      :uberjar {:aot :all}
      :test-jar {:uberjar-name "cabal-voting-test.jar"}
      :prod-jar {:uberjar-name "cabal-voting.jar"}
    }
)
