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
	sleep 2
else
	echo "automation off, clearing"
	/usr/local/bin/rmlsend LL\ 1\ BLANK\!
	sleep 1
fi
rmlsend PX\ 1\ 3004\! #This is the WMFO shows pre-recorded announcement, will push to top
sleep 1
rmlsend PN\ 1\! #press play next (second track in queue or first if not running), which should fade out existing track
sleep 1
rmlsend PX\ 1\ 999996\!
sleep 1
rmlsend PX\ 1\ $cart\! # queue up specified show
sleep 180 #delay enough time that we don't find the same show again
