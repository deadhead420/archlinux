#!/bin/bash
## Attempt to connect to search

if $4 ; then
attempt_search=$(lynx -dump wiki.archlinux.org/index.php/$1_$2_$3_$4 | grep "There is currently no text in this page") #Make sure page exists
	if [ "$attempt_search" = "search for this" ]; then
		lynx https://wiki.archlinux.org/index.php?title=Special%3ASearch&profile=default&search=$1_$2_$3_$4&fulltext=Search #Connect to search results
	else
		lynx https://wiki.archlinux.org/index.php/$1_$2_$3_$4 #Connect directly to wiki page
fi

if $3 ; then
attempt_search=$(lynx -dump wiki.archlinux.org/index.php/$1_$2_$3 | grep "There is currently no text in this page") #Make sure page exists
	if [ "$attempt_search" = "search for this" ]; then
		lynx https://wiki.archlinux.org/index.php?title=Special%3ASearch&profile=default&search=$1_$2_$3&fulltext=Search #Connect to search results
	else
		lynx https://wiki.archlinux.org/index.php/$1_$2_$3 #Connect directly to wiki page
fi

if $2 ; then
	attempt_search=$(lynx -dump wiki.archlinux.org/index.php/$1_$2 | grep "There is currently no text in this page") #Make sure page exists
	if [ "$attempt_search" = "search for this" ]; then
		lynx https://wiki.archlinux.org/index.php?title=Special%3ASearch&profile=default&search=$1&fulltext=Search #Connect to search results
	else
		lynx https://wiki.archlinux.org/index.php/$1_$2 #Connect directly to wiki page
fi

attempt_search=$(lynx -dump wiki.archlinux.org/index.php/$1 | grep "There is currently no text in this page") #Make sure page exists
	if [ "$attempt_search" = "search for this" ]; then
		lynx https://wiki.archlinux.org/index.php?title=Special%3ASearch&profile=default&search=$1&fulltext=Search #Connect to search results
	else
		lynx https://wiki.archlinux.org/index.php/$1 #Connect directly to wiki page
fi