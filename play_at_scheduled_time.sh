#!/bin/bash
if [ -z ${1+x} ] || [ -z ${2+x} ] ; then
	echo "Usage: $0 [track-to-play] [target-date]"
	exit 1
fi
target_date=$2
echo "testing date validity:"
date -d "$target_date"
if [ $? -ne 0 ] ; then
	echo error parsing date
	exit 1
else 
	echo date successfully parsed!
fi
target_file=$1
if [ -f "$target_file" ] ; then
	echo target_file exists! now to calculate sleep time...
else
	echo "target_file doesn't exist :( exiting..."
	exit 1
fi
filename=$(basename -- "$target_file")
extension="${filename##*.}"
if [ "$extension" == "mp3" ] || [ "$extension" == "wav" ] ; then
	echo "I can play file with extension $extension"
else
	echo "Cannot play $extension"
	exit 1
fi

current_epoch=$(date +%s)
target_epoch=$(date -d "$target_date" +%s)

# First, calculate the number of seconds we should wait
sleep_seconds=$(( $target_epoch - $current_epoch ))

if [ $sleep_seconds > 0 ] ; then
	echo Sleeping $sleep_seconds seconds until the scheduled show start...
	sleep $sleep_seconds # Wait that number of seconds
fi
/opt/wmfo/macro_sh/axia_manipulate.sh 192.168.0.110 7 13500 > /dev/null # Switch to Studio C
if [ "$extension" == "mp3" ] ; then
	/usr/bin/mpg123 $target_file
elif [ "$extension" == "wav" ] ; then
	/usr/bin/aplay $target_file # Play a song
fi
/opt/wmfo/macro_sh/axia_manipulate.sh 192.168.0.110 7 10500 > /dev/null # Switch back to Studio A when done
exit 0
