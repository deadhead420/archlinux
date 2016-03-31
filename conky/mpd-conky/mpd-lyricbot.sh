#!/bin/bash
lyric_dir=~/.lyrics

state=$(mpc status | awk 'NR==2' | awk '{print $1}')
if [ "$state" == "[playing]" ]; then
	artist=$(mpc -f %artist% | awk 'NR==1' | tr '[:upper:]' '[:lower:]' | sed 's/[/\, .;:%$!#^&@*{}<>]//g;s/&/ /g')
	title=$(mpc -f %title% | awk 'NR==1' | tr '[:upper:]' '[:lower:]' | sed -e 's/\[[^][]*\]\|([^()]*)\|[/\, .;:%$!#^@&*{}<>]//g')
	now_playing="$artist-$title.lyric"
	if [ -f "$lyric_dir"/"$now_playing" ]; then
		cat "$lyric_dir"/"$now_playing"
	else
		direct_url=$(lynx -dump http://www.azlyrics.com/lyrics/$artist/$title.html | sed '1,15d;/Submit Corrections/q' | grep -v "Submit Corrections")
#		test_url=$(echo "$direct_url" | grep "All lyrics are property and copyright of their owners")
#		if [ -n "$test_url" ]; then
		echo "$direct_url" > "$lyric_dir"/"$now_playing"		
		cat "$lyric_dir"/"$now_playing"
	fi
else
	echo "No song is playing"
fi
