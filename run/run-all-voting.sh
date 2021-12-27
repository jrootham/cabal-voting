#!/bin/bash

LOCAL=/var/www/vhosts/jrootham.ca/.local/

$LOCAL/bin/run-voting.sh demo 4000
$LOCAL/bin/run-voting.sh thursday 4001
$LOCAL/bin/run-voting.sh friday 4002
$LOCAL/bin/run-voting.sh book 4003

