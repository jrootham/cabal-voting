(defproject voting "0.1.0-SNAPSHOT"
  :description "Cabal voting back end"
  :url "http://example.com/FIXME"
  :dependencies [
  					[org.clojure/clojure "1.8.0"]
  					[ring/ring-core "1.5.0"]
                 	[ring/ring-jetty-adapter "1.5.0"]
                 ]
  :main ^:skip-aot voting.core
  :aot [voting.core]
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
