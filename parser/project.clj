(defproject parser "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :dependencies [
  					[org.clojure/clojure "1.8.0"]
  					[clj-http "3.7.0"]
  					[org.xerial/sqlite-jdbc "3.20.0"]
            [org.clojure/java.jdbc "0.7.1"]
            [org.clojure/data.json "0.2.6"]
            [http-kit "2.2.0"]
  				]
  :main ^:skip-aot parser.core
  :aot [parser.core]
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
