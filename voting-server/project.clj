(defproject voting "0.1.0-SNAPSHOT"
	:description "Cabal voting back end"
	:url "http://example.com/FIXME"
	:dependencies 
	[
		[org.clojure/clojure "1.10.1"]
		[ring/ring-core "1.8.1"]
		[ring/ring-jetty-adapter "1.8.1"]
;		[ring/ring-json "0.5.0"]
		[org.postgresql/postgresql "42.2.12"]
		[org.clojure/java.jdbc "0.7.11"]
		[org.clojure/data.json "1.0.0"]
		[compojure "1.6.1"]
		[hiccup "2.0.0-alpha2"]
		[clj-http "3.10.0"]
		[valip "0.2.0"]
		[crypto-random "1.2.0"]
		[clj-time "0.15.2"]
		[bananaoomarang/ring-debug-logging "1.1.0"]
	]
	:min-lein-version "2.0.0"
	:main ^:skip-aot voting-server.core
	:aot [voting-server.core]
	:target-path "target/%s"
	:uberjar-name "voting-server.jar"
)
