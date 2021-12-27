#!/bin/bash

BASE=/var/www/vhosts/jrootham.ca
VAR=$BASE/.local/var

nohup stdbuf -oL java -jar $BASE/servers/$1/voting-server.jar $2 &>> $VAR/log/voting/$1.log &
echo $! > $VAR/run/$1.pid

