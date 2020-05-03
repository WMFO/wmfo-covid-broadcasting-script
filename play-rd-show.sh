#!/bin/bash

LOCKFILE=/var/lock/automation_is_on.lock

if [ -z ${1+x} ]
then
        echo Usage: $0 \"[cart-number]\"
	exit 1
fi
cart=$1

# Pressing fader off button on board should not clear logs unless
# automation is actually running
if [ -f ${LOCKFILE} ]
then
	echo "automation on, stopping"
	rmlsend EX\ 999997\!
	sleep 10
else
	echo "automation off, clearing"
	/usr/local/bin/rmlsend LL\ 1\ BLANK\!
fi
rmlsend PX\ 1\ 999996\!
sleep 1
rmlsend PX\ 1\ $cart\! # queue up specified show
sleep 1
rmlsend PX\ 1\ 3004\! #This is the WMFO shows pre-recorded announcement, will push to top
sleep 1
rmlsend PL\ 1\ 0\! #press play if not running (no-op if running)
# TODO: queue up automation restart macro cart
# rmlsend PX\ 1\ 
sleep 180 #delay enough time that we don't find the same show again
