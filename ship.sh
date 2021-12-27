#!/bin/bash

LOCAL=voting-server/resources/public/main.js
REMOTE=jrootham@jrootham.ca:
BASE=/var/www/vhosts/jrootham.ca
SUFFIX=resources/public/

PREFIX=/home/jrootham/dev/cabal/cabalVoting/voting-server
UBERJAR=/target/uberjar/voting-server.jar
DOCROOT=/home/jrootham/dev/cabal/cabalVoting/docroot


ssh jrootham@jrootham.ca "mkdir -p $BASE/demo.jrootham.ca/$SUFFIX"
ssh jrootham@jrootham.ca "mkdir -p $BASE/thursday.jrootham.ca/$SUFFIX"
ssh jrootham@jrootham.ca "mkdir -p $BASE/friday.jrootham.ca/$SUFFIX"
ssh jrootham@jrootham.ca "mkdir -p $BASE/book.jrootham.ca/$SUFFIX"

ssh jrootham@jrootham.ca "mkdir -p $BASE/servers/demo"
ssh jrootham@jrootham.ca "mkdir -p $BASE/servers/thursday"
ssh jrootham@jrootham.ca "mkdir -p $BASE/servers/friday"
ssh jrootham@jrootham.ca "mkdir -p $BASE/servers/book"

scp $DOCROOT/* $REMOTE$BASE/demo.jrootham.ca
scp $DOCROOT/* $REMOTE$BASE/thursday.jrootham.ca
scp $DOCROOT/* $REMOTE$BASE/friday.jrootham.ca
scp $DOCROOT/* $REMOTE$BASE/book.jrootham.ca

scp $PREFIX/$SUFFIX/* $REMOTE$BASE/demo.jrootham.ca/$SUFFIX
scp $PREFIX/$SUFFIX/* $REMOTE$BASE/thursday.jrootham.ca/$SUFFIX
scp $PREFIX/$SUFFIX/* $REMOTE$BASE/friday.jrootham.ca/$SUFFIX
scp $PREFIX/$SUFFIX/* $REMOTE$BASE/book.jrootham.ca/$SUFFIX

elm make src/Main.elm --output voting-server/resources/public/main.js

scp $LOCAL $REMOTE$BASE/demo.jrootham.ca/$SUFFIX
scp $LOCAL $REMOTE$BASE/thursday.jrootham.ca/$SUFFIX
scp $LOCAL $REMOTE$BASE/friday.jrootham.ca/$SUFFIX
scp $LOCAL $REMOTE$BASE/book.jrootham.ca/$SUFFIX

cd voting-server

# local

ln -sf $PREFIX/src/voting_server/localstuff.clj $PREFIX/src/voting_server/stuff.clj

lein uberjar

mv $PREFIX$UBERJAR $PREFIX/local

# demo

ln -sf $PREFIX/src/voting_server/demostuff.clj $PREFIX/src/voting_server/stuff.clj

lein uberjar

scp $PREFIX$UBERJAR $REMOTE$BASE/servers/demo


# thursday

ln -sf $PREFIX/src/voting_server/thursdaystuff.clj $PREFIX/src/voting_server/stuff.clj

lein uberjar

scp $PREFIX$UBERJAR $REMOTE$BASE/servers/thursday

# friday

ln -sf $PREFIX/src/voting_server/fridaystuff.clj $PREFIX/src/voting_server/stuff.clj

lein uberjar

scp $PREFIX$UBERJAR $REMOTE$BASE/servers/friday

# book

ln -sf $PREFIX/src/voting_server/bookstuff.clj $PREFIX/src/voting_server/stuff.clj

lein uberjar

scp $PREFIX$UBERJAR $REMOTE$BASE/servers/book
