#!/bin/bash
if [ -z ${1+x} ]
then
	echo Usage: $0 \"[directory-of-shows]\"
	echo For example, $0 \"/home/wmfo-dj/Downloads/show-queue/\*\"
fi

function get_show_date () {
	fullpath=$1
	seconds=$2

	file=`basename "$fullpath"` # Get the base file
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
	next_show="/some/path/to/20300101_0000-not-actual-show.wav"
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
	if [ "$next_show" = "/some/path/to/20300101_0000-not-actual-show.wav" ] ; then
		# this means we didn't find a next show
		echo ""
	else
		echo "$next_show"
	fi
}

while true ; do
	# Grab all the shows in the directory
	shows=($1)
	
	# Lord have mercy is that array syntax ugly...
	next_show=`get_next_show "${shows[@]}"`
	if [ -z $next_show ] ; then
		echo "No next show found. Will check again in 20 minutes."
		sleep 1200
		continue
	fi
	next_show_date=`get_show_date $next_show`
	
	echo -e "The next show is:\n$next_show\nwhich will begin playing at:\n$next_show_date"
	next_show_date_seconds=`get_show_date $next_show seconds`
	# date doesn't understand "from now" but does understand "hence" ... no comment
	date_plus_an_hour=`date -d '1 hour hence' +%s`
	if [[ "$next_show_date_seconds" < "$date_plus_an_hour" ]] ; then
		echo "The next show is within an hour; I will queue it up:"
		./play_at_scheduled_time.sh "$next_show" "@$next_show_date_seconds"
	else
		current_seconds=`date +%s`
		minutes_away=`echo "( $next_show_date_seconds - $current_seconds ) / 60" | bc`
		#wait 20 minutes and check again if we have no shows within the next hour
		echo "Next show is $minutes_away minutes away. I will check for new shows in 58 or so minutes."
		sleep 3500s
	fi
done
