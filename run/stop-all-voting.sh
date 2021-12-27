#!/bin/bash

BASE=/var/www/vhosts/jrootham.ca
RUN=$BASE/.local/var/run

kill `cat $RUN/demo.pid`
kill `cat $RUN/thursday.pid`
kill `cat $RUN/friday.pid`
kill `cat $RUN/book.pid`
