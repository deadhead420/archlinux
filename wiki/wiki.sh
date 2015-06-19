#!/bin/bash

var=$(echo "$@" | sed 's/ /_/g')

attempt_search=$(lynx -dump wiki.archlinux.org/index.php/$var | grep "There is currently no text in this page" | cut -c57-) #Make sure page exists
	if [ "$attempt_search" = "search for this" ]; then
		lynx https://wiki.archlinux.org/index.php?title=Special%3ASearch&profile=default&search=$var&fulltext=Search #Connect to search results
	else
		lynx https://wiki.archlinux.org/index.php/$var #Connect directly to wiki page
fi