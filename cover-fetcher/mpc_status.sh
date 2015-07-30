#!/bin/bash
init() {
artist=$(mpc -f %artist% | awk 'NR==1')
album=$(mpc -f %album% | awk 'NR==1' | sed 's/disk 1//;s/disk 2//;s/disk 3//;s/disk 4//;s/Disk 1//;s/Disk 2//;s/Disk 3//;s/Disk 4//;s/disc 1//;s/disc 2//;s/disc 3//;s/disc 4//;s/Disc 1//;s/Disc 2//;s/Disc 3//;s/Disc 4//;s/]//;s/\[//;s/)//;s/(//')
state=$(mpc status | awk 'NR==2' | awk '{print $1}')
now_playing="$artist-$album.jpg"
if [ "$state" == "[playing]" ]; then
	if [ -f ~/.covers/"$now_playing" ]; then
		cp ~/.covers/"$now_playing" cover.jpg
		hold
	else
		download
	fi
else
	halt
fi
}
hold() {
cover=$(md5sum ~/.covers/"$now_playing" | awk '{print $1}')
current_cover=$(md5sum cover.jpg | awk '{print $1}')
if [ "$cover" == "$current_cover" ]; then
	sleep 2
else
	init
fi
played_percent=$(mpc status | awk 'NR==2' | awk '{print $4}' | sed 's/(\|)\|%//g')
while [ "$played_percent" -gt "0" ]
	do
		played_percent=$(mpc status | awk 'NR==2' | awk '{print $4}' | sed 's/(\|)\|%//g')
		sleep 1
	done
init
}
download() {
SEARCH=$(echo "$artist+$album" | sed 's/ /+/g')
cover_url=$(lynx --dump http://www.covermytunes.com/search.php\?search_query\=$SEARCH\&x\=0\&y\=0 | grep -F "2. http://www.covermytunes.com/cd-cover" | cut -c7-)
if [ -n "$cover_url" ]; then
	image_url=$(lynx -image_links -dump $cover_url | grep -a "600x600" | awk 'NR==2' | cut -c7-)
	if [ -n "$image_url" ]; then
		wget "$image_url" -O ~/.covers/"$now_playing"
		init
	else
		cp nocover.png cover.jpg
		hold
	fi
else
	cp nocover.png cover.jpg
	hold
fi
}
halt() {
while [ "$state" == "[paused]" ]
	do
		state=$(mpc status | awk 'NR==2' | awk '{print $1}')
		sleep 2
	done
while [ ! "$state" ] 
	do
		state=$(mpc status | awk 'NR==2' | awk '{print $1}')
		sleep 4
	done
init
}
init
