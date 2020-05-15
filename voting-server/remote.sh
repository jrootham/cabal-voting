#!/bin/bash

ln -sf /home/jrootham/dev/cabal/voting-server/src/voting_server/remotestuff.clj \
	/home/jrootham/dev/cabal/voting-server/src/voting_server/stuff.clj

lein uberjar

scp /home/jrootham/dev/cabal/voting-server/target/uberjar/voting-server.jar \
	jrootham@jrootham.ca:/home/jrootham/servers/voting/
	
