#!/bin/bash
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
## To submit your changes or suggest any ideas see my github: https://github.com/deadhead420/archlinux/blob/master/mpd-coverbot/mpd-coverbot.sh
##

# change this variable to specify the directory you would like the covers to be downloaded to
# set to full directory path, default path set to ~/.covers
download_dir=~/.covers

if [ -d "$download_dir" ]; then
	sleep 2
else
	echo "Error the download directory '$download_dir' does not exist"
	echo "Please create '$download_dir' and try running again"
	exit 1
fi
exec_conky() {
conky_state=$(ps -f -C "conky" | grep "conky -p 10 -c conkyrc")
if [ -n "$conky_state" ]; then
	conky_pid=$(ps -f -C "conky" | grep "conky -p 10 -c conkyrc" | awk '{print $2}')
	kill "$conky_pid"
	conky -p 10 -c conkyrc &
	init
else
	conky -p 10 -c conkyrc &
	init
fi
}
init() {
state=$(mpc status | awk 'NR==2' | awk '{print $1}')
if [ "$state" == "[playing]" ]; then
	artist=$(mpc -f %artist% | awk 'NR==1' | sed 's/[/\,.;:%$!#^@*{}<>]//g;s/&/ /g' | tr -s " ")
	album=$(mpc -f %album% | awk 'NR==1' | sed -e 's/\[[^][]*\]\|([^()]*)\|[/\,.;:%$!#^@&*{}<>]\|disk.*\|disc.*\|1\/2\|2\/2//gi' | tr -s " ")
	now_playing="$artist-$album.jpg"
	if [ -f "$download_dir"/"$now_playing" ]; then
		cp "$download_dir"/"$now_playing" ~/.conky/mpd-conky/cover.jpg
		hold
	else
		download
	fi
else
	hold
fi
}
hold() {
cover=$(md5sum "$download_dir"/"$now_playing" | awk '{print $1}')
current_cover=$(md5sum ~/.conky/mpd-conky/cover.jpg | awk '{print $1}')
if [ "$cover" == "$current_cover" ] || [ "$current_cover" ==  "034bf031009499ef5e93cbd68c3ce06f" ]; then
	sleep 2
fi
played_percent=$(mpc status | awk 'NR==2' | awk '{print $4}' | sed 's/(\|)\|%//g')
while [[ "$played_percent" -gt "0" && "$state" == "[playing]"  ]]
	do
		played_percent=$(mpc status | awk 'NR==2' | awk '{print $4}' | sed 's/(\|)\|%//g')
		state=$(mpc status | awk 'NR==2' | awk '{print $1}')
		sleep 1
	done
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
download() {
SEARCH=$(echo "$artist+$album" | sed "s/ /+/g;s!/!!g;s/'//g")
cover_url=$(lynx --dump http://www.covermytunes.com/search.php\?search_query\=$SEARCH\&x\=0\&y\=0 | grep -a "2. http://www.covermytunes.com/cd-cover" | cut -c7- | awk 'NR==1')
if [ -n "$cover_url" ]; then
	image_url=$(lynx -image_links -dump $cover_url | grep -a "600x600" | cut -c7-)
	test_url=$(echo "$image_url" | wc -l)
	if [ "$test_url" -gt 1 ]; then
		download_url=$(echo "$image_url" | awk "NR==2")
	else
		download_url=$(echo "$image_url")
	fi
	if [ -n "$download_url" ]; then
		wget "$download_url" -O "$download_dir"/"$now_playing"
	else
		google_cover
	fi
else
	google_cover
fi
init
}
google_cover() {
cover_url=$(lynx -dump 'https://www.google.com/search?q='$SEARCH'&biw=1600&bih=789&tbm=isch&source=lnt&tbs=isz:ex,iszw:600,iszh:600' | grep -a "http://www.google.com/imgres?imgurl=" | awk "NR==1" | cut -c7-)
image_url=$(echo $cover_url | sed 's/&imgrefurl=.*//' | cut -c37-)
if [ -n "$image_url" ]; then
	wget "$image_url" -O "$download_dir"/"$now_playing"
	init
else
	cp ~/.conky/mpd-conky/nocover.png ~/.conky/mpd-conky/cover.jpg
fi
hold
}
exec_conky
