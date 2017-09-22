#!/usr/bin/env bash
echo "Connecting to BBS via Websockets..."
BASEDIR=$(dirname "$0")
$BASEDIR/usock2wsock -u $1 -r $2 &
sleep 2
/usr/bin/telnet -8 -u /tmp/telnetBYwebsocket.$2.sock
