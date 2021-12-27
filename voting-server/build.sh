#!/bin/bash

PREFIX=/home/jrootham/dev/cabal/cabalVoting/voting-server
UBERJAR=/target/uberjar/voting-server.jar

# local

ln -sf $PREFIX/src/voting_server/localstuff.clj $PREFIX/src/voting_server/stuff.clj

lein uberjar

mv $PREFIX$UBERJAR $PREFIX/local

