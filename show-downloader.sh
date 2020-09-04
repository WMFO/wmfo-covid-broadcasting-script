#!/bin/bash
echo "Begin the script downloady thingy"
while true ; do
	# Grab all the shows in the directory
	IFS=$'\n'
	shows=(`rclone lsf nickdrive:/wmfo-shows/ --max-depth=1`)
	
	for show in "${shows[@]}"
	do
		# Skip directories
		if [[ $show == */ ]] ; then
			#echo "Skipping directory $show"
			continue
		fi
		filename=$(basename -- "$show")
		extension="${filename##*.}"
		filename_short="${filename%.*}"
		if [ "$extension" != "wav" ] && [ "$extension" != "mp3" ] ; then
			continue
		fi
		if [[ $show == rejected-* ]] ; then
			continue
		fi
		chars_before_underscore=`echo $show | cut -f 1 -d'_' | wc -c`
		chars_before_dash=`echo $show | cut -f 1 -d'-' | wc -c`
		if [ $chars_before_underscore -ne 9 ] || [ $chars_before_dash -ne 14 ] ; then
			rclone moveto "nickdrive:/wmfo-shows/$show" "nickdrive:/wmfo-shows/rejected-date-format-$show"
			echo "`date` Skipping $show due to incorrect formatting"
			continue
		fi
        	date_string=`echo "$show" | cut -f1 -d'-' | sed "s/_/ /g"`
                next_show_date_seconds=`date --date="$date_string" +%s`
		date_seconds=`date +%s`
		date_plus_a_year=`date -d '1 year hence' +%s`
		if [ $next_show_date_seconds -lt $date_seconds ] || [ $next_show_date_seconds -gt $date_plus_a_year ] ; then
			rclone moveto "nickdrive:/wmfo-shows/$show" "nickdrive:/wmfo-shows/rejected-date-wrong-$show"
			echo "`date` Skipping $show due to being a weird date"
			continue
		fi
		rclone ls "nickdrive:/wmfo-shows/already-imported-shows/$show" 2>/dev/null
		if [ $? -eq 0 ] ; then
			rclone moveto "nickdrive:/wmfo-shows/$show" "nickdrive:/wmfo-shows/rejected-already-imported-$show"
			echo "`date` Skipping $show due to being a duplicate"
			continue
		fi
		
		echo -ne "`date`: starting $show download..."
		rclone copy "nickdrive:/wmfo-shows/$show" /home/wmfo-dj/Downloads/show-queue
		rdimport --autotrim-level=0 --metadata-pattern=%t.wav --delete-source Shows /home/wmfo-dj/Downloads/show-queue/*
		rclone move "nickdrive:/wmfo-shows/$show" nickdrive:/wmfo-shows/already-imported-shows/
		echo "Success!"
	done
	#echo "We are done for now. Will check again in 10 minutes."
	sleep 600
done
