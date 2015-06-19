#!/bin/bash
## Attempt to connect to search
attempt_search=$(lynx -dump wiki.archlinux.org/index.php/$1 | grep "There is currently no text in this page") #Make sure page exists
	if [ "$attempt_search" = "search for this" ]; then
		lynx https://wiki.archlinux.org/index.php?title=Special%3ASearch&profile=default&search=$1&fulltext=Search #Connect to search results
	else
		lynx https://wiki.archlinux.org/index.php/$1 #Connect directly to wiki page
fi
