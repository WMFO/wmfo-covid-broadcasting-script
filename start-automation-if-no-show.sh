#!/bin/bash

function get_show_date () {
        file=$1
        seconds=$2

        date_string=`echo "$file" | cut -f1 -d'-' | sed "s/_/ /g"`
        # split on the '-' character and replace _ with ' ' so date works properly
        if [ -z ${2+x} ] ; then
                date --date="$date_string"
        else
                # option to get date as seconds format
                date --date="$date_string" +%s
        fi
}

function get_next_show() {
        # bash arrays are really horrifying this took forever to get right
        shows=("$@")
        # We subtract a minute just in case there is overlap in shows
        current_date=`date +%s -d '1 minute ago'`
        # I created a fake show in 2030 as the maximum
        next_show="20300101_0000-not-actual-show"
        # wow that syntax is ugly, but it looks through the show names
        for show in "${shows[@]}"
        do
                next_show_date=`get_show_date $next_show seconds`
                show_date=`get_show_date $show seconds`
                # we want the minimum show time that is greater than the current date
                if [[ "$show_date" > "$current_date" ]] && [[ "$show_date" < "$next_show_date" ]]
                then
                        next_show="$show"
                fi
        done
        if [ "$next_show" = "20300101_0000-not-actual-show" ] ; then
                # this means we didn't find a next show
                echo ""
        else
                echo "$next_show"
        fi
}

 # Grab all the shows in the directory
IFS=$'\n'
export MYSQL_PWD=`bash ./credentials.sh`
shows=(`mysql Rivendell -sN -u rduser -h 192.168.9.240 -e "select TITLE from CART where GROUP_NAME = 'Shows';"`)

echo $shows
# Lord have mercy is that array syntax ugly...
next_show=`get_next_show "${shows[@]}"`
if [ -z $next_show ] ; then
	rmlsend EX\ 999998\!
	exit 0
fi
next_show_date=`get_show_date $next_show`

echo -e "The next show is:\n$next_show\nwhich will begin playing at:\n$next_show_date"
next_show_date_seconds=`get_show_date $next_show seconds`
# date doesn't understand "from now" but does understand "hence" ... no comment
date_plus_minute=`date -d '1 minute hence' +%s`
if [[ "$next_show_date_seconds" > "$date_plus_minute" ]] ; then
	rmlsend EX\ 999998\!
	exit 0
fi

