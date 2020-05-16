#!/bin/bash

ln -sf /home/jrootham/dev/cabal/voting-server/src/voting_server/demostuff.clj \
	/home/jrootham/dev/cabal/voting-server/src/voting_server/stuff.clj


lein uberjar
