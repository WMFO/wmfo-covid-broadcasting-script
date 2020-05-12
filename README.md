# WMFO COVID Remote Broadcasting Scripts

written by nick@wmfo.org around 4/30/20

A set of scripts we are using to run shows during the COVID pandemic.

1. A script to run shows called wmfo-rd-show-robot.sh
2. A script to send Rivendell Macro Language (RML) commands to Rivendell to start shows (fade-rd-show.sh)

I decided to try to write it in bash (horrible idea, don't do it, not pretty -- if anyone asks I will deny that I wrote these). Anyways here's the result.

## Version 1.1 - the robot should start shows on time

I tweaked the script using a new set of RD commands in the fade-rd-show.sh script designed to fade out the currently playing track. The wmfo-rd-show-robot.sh has been altered to call fade-rd-show.sh and wait until 25 seconds before the top of the hour to trigger it. This (combined with the time required to clear the log and whatnot along with the 22.2 seconds for the announcement) started a show exactly on time in my testing. The new RML in the fade-rd-show.sh script uses:

- `rmlsend EX\ 999997\!` if automation is on, which turns it off
- `rmlsend LL\ 1\ BLANK\!` if automation is off, which clears the main log
- `rmlsend PX\ 1\ 3004\!` This is the WMFO shows pre-recorded announcement
- `rmlsend PN\ 1\!` Press play next (second track in queue or first if not running), which should fade out existing track
- `rmlsend PX\ 1\ 999996\!` Adds the "restart automation" cart
- `rmlsend PX\ 1\ $cart\!` Queues up the specified show (inserts in reverse order for some reason, so)

And adds a few sleep seconds in there.

## Version 1.0

Used the play-rd-show.sh script, which waited until the end of the song to play the track.

## Overview of V0.9 which used bash

Alright I rejiggered the scripts to get continuous play working and it's
uploaded to github at https://github.com/WMFO/wmfo-covid-broadcasting-script.
For the curious:

wmfo-show-robot.sh:

   1. Loops continuously
   2. Checks for the next show in the list. Same as before, except I look
   for the next show (TIME_NOW - 1 minute) just in case we had a 1 hour show
   that was kicked off at 7:00:10 PM and ran for an hour. Without this, if we
   had an hour long show at 7PM that ran exactly 60 minutes we might miss the
   next show at 8PM since we may check for the next show after 8:00:20 PM
   which would exclude a show at 8PM. This way a few extra seconds doesn't
   break things.
   3. If this next show in the list is within 1 hour, it kicks off
   play-at-scheduled-time.sh with the show and time to play at.
   4. If the next show is more than 1 hour away, it waits 58 or so minutes
   and checks again. This is to handle the case where we add shows out of
   order. For example, if someone gets their show in a week early and we copy
   it into the folder, we don't want to queue up that show 4 days in advance
   and miss a show added later that's in between.
   5. If there is no next show, we wait an hour and try again.

play-at-scheduled-time.sh is unchanged; we just pass a file and a time and
it:

   1. Waits till the specified time.
   2. Switches to studio C
   3. plays the track
   4. switches back to studio A when done
   5. exits

    The output looks something like:
    Next show is 74 minutes away. I will check for new shows in 58 or so
    minutes.
    The next show is:
    /home/wmfo-dj/Downloads/show-queue/20200430_1200-Strike-the-Box.wav
    which will begin playing at:
    Thu Apr 30 12:00:00 EDT 2020
    The next show is within an hour; I will queue it up:
    *(calls play-at-scheduled-time)*
    testing date validity:
    Thu Apr 30 12:00:00 EDT 2020
    date successfully parsed!
    target_file exists! now to calculate sleep time...
    I can play file with extension wav
    Sleeping 999 seconds until the scheduled show start...
    Playing WAVE
    '/home/wmfo-dj/Downloads/show-queue/20200430_1200-Strike-the-Box.wav' :
    Signed 16 bit Little Endian, Rate 44100 Hz, Stereo
    *(goes back to wmfo-show-robot)*
    /home/wmfo-dj/Downloads/show-queue/20200430_1800-desperate-hours.wav
    which will begin playing at:
    Thu Apr 30 18:00:00 EDT 2020
    Next show is 299 minutes away. I will check for new shows in 58 or so
    minutes.

etc.

--Nick
