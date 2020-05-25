#!/bin/bash

PREFIX=/home/jrootham/dev/cabal/cabalVoting/voting-server

ln -sf $PREFIX/src/voting_server/demostuff.clj $PREFIX/src/voting_server/stuff.clj

lein uberjar
