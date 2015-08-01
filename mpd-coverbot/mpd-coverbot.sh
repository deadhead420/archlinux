#!/bin/bash
##
## MPD-CoverBot
## By: deadhead
## Date: July 31, 2015
## License: GPL Version 2
## This program is used to download album covers for songs using mpd. This script requires mpd, mpc, lynx, and wget as dependencies.
## Album covers are saved to ~/.covers/ ensure this directory exists, or change the "download_dir" variable at the top of this script to the directory of your choice.
## This script also relies on the proper artist and album tags being set for each song playing or it will not return any results.
## Feel free to use this script in any way you would like and make any changes you would like.
## To submit your changes or suggest any ideas see my github:
##

download_dir=~/.covers                                                                                 # change this variable to specify the directory you would like the covers to be downloaded to
																       # set to full directory path, default path set to ~/.covers
if [ -d "$download_dir" ]; then
		init
else
	echo "Error the download directory '$download_dir' does not exist"
	echo "Please create '$download_dir' and try running again"
fi
init() {
state=$(mpc status | awk 'NR==2' | awk '{print $1}')                             # checks is music is playing
if [ "$state" == "[playing]" ]; then                                                                      # defines variables if music is playing
	artist=$(mpc -f %artist% | awk 'NR==1' | sed 's!/! !g;s/&/ /g')
	album=$(mpc -f %album% | awk 'NR==1' | sed 's/disk 1//;s/disk 2//;s/disk 3//;s/disk 4//;s/Disk 1//;s/Disk 2//;s/Disk 3//;s/Disk 4//;s/disc 1//;s/disc 2//;s/disc 3//;s/disc 4//;s/Disc 1//;s/Disc 2//;s/Disc 3//;s/Disc 4//;s!1/2!!;s!2/2!!;s/]//;s/\[//;s/)//;s/(//;s!/! !g;s/&/+/g')
	now_playing="$artist-$album.jpg"                                                        # uses artist and album tags to specify an image file
	if [ -f "$download_dir"/"$now_playing" ]; then                                                  # checks if that image exists under cover directory
		hold                                                                                                                    # holds if image exists
	else
		download                                                                                                         # if image does not exist download
	fi
else
	hold															       # hold when not playing
fi
}
hold() {
played_percent=$(mpc status | awk 'NR==2' | awk '{print $4}' | sed 's/(\|)\|%//g')
while [[ "$played_percent" -gt "0" && "$state" == "[playing]"  ]]        # checks played percent and state of mpd
	do
		played_percent=$(mpc status | awk 'NR==2' | awk '{print $4}' | sed 's/(\|)\|%//g')
		state=$(mpc status | awk 'NR==2' | awk '{print $1}')
		sleep 1                                                                                                                  # sleeps for 1 second while played percent is greater than 0
	done
while [ "$state" == "[paused]" ]
	do
		state=$(mpc status | awk 'NR==2' | awk '{print $1}')
		sleep 2                                                                                                                   # sleeps for 2 seconds while state is paused
	done
while [ ! "$state" ] 
	do
		state=$(mpc status | awk 'NR==2' | awk '{print $1}')
		sleep 4                                                                                                                   # sleeps for 4 seconds while state is not defined
	done
init                                                                                                                                            # back to initial function when hold phase is no longer true
}
download() {
SEARCH=$(echo "$artist+$album" | sed "s/ /+/g;s!/!!g;s/'//g")             # prepares a search querry 
cover_url=$(lynx --dump http://www.covermytunes.com/search.php\?search_query\=$SEARCH\&x\=0\&y\=0 | grep -a "2. http://www.covermytunes.com/cd-cover" | cut -c7- | awk 'NR==1')
if [ -n "$cover_url" ]; then                                                                                              # if search querry returns a result searches page for correct size image
	image_url=$(lynx -image_links -dump $cover_url | grep -a "600x600" | cut -c7-)
	test_url=$(echo "$image_url" | wc -l)
	if [ "$test_url" -gt 1 ]; then                                                                                    # tests image url to ensure correct link is downloaded
		download_url=$(echo "$image_url" | awk "NR==2")
	else
		download_url=$(echo "$image_url")
	fi
	if [ -n "$download_url" ]; then									       # if a download url exists wget the image and save to cover directory as artist-album.jpg
		wget "$download_url" -O "$download_dir"/"$now_playing"
	else
		google_cover														# if no link is found attempt a google search
	fi
else
	google_cover
fi
init																		# once finished return to initial function
}
google_cover() {
cover_url=$(lynx -dump 'https://www.google.com/search?q='$SEARCH'&biw=1600&bih=789&tbm=isch&source=lnt&tbs=isz:ex,iszw:600,iszh:600' | grep -a "http://www.google.com/imgres?imgurl=" | awk "NR==1" | cut -c7-)
image_url=$(echo $cover_url | sed 's/&imgrefurl=.*//' | cut -c37-)
if [ -n "$image_url" ]; then
	wget "$image_url" -O "$download_dir"/"$now_playing"
else
	echo "Couldn't locate $now_playing be sure you have proper artist and album tags set for each song."
fi
hold
}
init