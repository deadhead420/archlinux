#!/bin/bash

# This function is used to create a loading bar with dialog
# This loading bar reads from a log every .5 seconds and displays output
# This all looks very complex but its not command starts with wget at the bottom
# I wget a test file append output to my created tmpfile and fork to background &
# Then I set pid equal to the process ID of wget command
# Then I set pri to 1 (this means to increase guage by 1 every 1 second)
# at the top of loop pri is set to $((pri*2))
# this is because the loop updates every .5 seconds
# the variable pos is increased by 1 every .5 seconds
# so when [ "$pos" -eq "$pri" ]; it means to increase guage percent by 1 $((int+1))
# The message part is pretty simple. first simply echo $int (percent to be displayed in bar)
# then echo -e (so you can create newline with \n) like so: "XXX\nsome text\n$log\nXXX"
# then when the loop goes around every .5 seconds the log is updated and displays new output in dialog

load_log() {
	
	{	int=1 								# $int is responsible for the guage percentage (start at 1)
		pos=1 								# $pos marks how many times the loop has gone around
		pri=$(<<<"$pri" sed 's/\..*$//') 	# $pri may be a float remove anything after '.' just in case
		pri=$((pri*2)) 						# times pri by two (the loop goes around once every .5 seconds times pri by two to account)
		while (true) 						# Start while true loop
    	    do
    	        proc=$(ps | grep "$pid") 			# Frist check if process $pid is still running
    	        if [ "$?" -gt "0" ]; then break; fi # If exit is greater than 0 process is no longer running break from loop
    	        sleep 0.5 							# sleep for .5 seconds
    	        if [ "$pos" -eq "$pri" ]; then 		# check if loop has gone around enought to equal $pri seconds
    	        	pos=0 							# reset pos to zero if it is equal
    	        	if [ "$int" -lt "100" ]; then 	# if loading bar is not 100
    	        		int=$((int+1)) 				# add one to loading bar
    	        	fi
    	        fi
				log=$(tail -n 1 "$tmpfile" | sed 's/\.//g') # tail log for output here I use sed to remove '.' from wget command
#    	        log=$(tail -n 1 "$tmpfile" | sed 's/.pkg.tar.xz//') # here I remove '.pkg.tar.xz' from pacstrap output
    	        echo "$int" 								# echo $int (this is what is displayed as guage percentage)
    	        echo -e "XXX$msg \n \Z1> \Z2$log\Zn\nXXX" 	# echo -e start XXX insert $msg and $log then XXX to end
    	        pos=$((pos+1)) 								# increase pos by 1 every .5 seconds (meaning it will equal int*2 when it is time to increase $int
    	    done
            echo 100 # When loop is finished echo 100 and sleep 1
            sleep 1
	} | dialog --colors --gauge "$msg" 10 79 0

}

# Here I use wget in place of pacstrap to demonstrate loading output
# pacstrap can be used like so:
# pacstrap /mnt base base-devel &> "$tmpfile" &
# pid is the process id of the process the loading bar is waiting for
# pri is how long it should wait to echo out new percentage to guage
# this means since the loop sleeps for .5 the loop will go around twice before $pri = $pos

tmpfile=$(mktemp) # create tmpfile for log
wget -O /dev/null -a "$tmpfile" "http://speedtest.wdc01.softlayer.com/downloads/test10.zip" &
pid=$! pri=1 msg="\n<#>\n Fetching test file...\n" load_log
