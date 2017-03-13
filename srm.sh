#!/bin/bash

TRASH=~/trash
TRASH_LOG=~/trash/.trash.log

case "$1" in
	-r)	shift
		for i in "$@" ; do
			if (ls $TRASH/$i &>/dev/null); then
				mv $TRASH/$i $(grep -w "$i" "$TRASH_LOG")
				sed -i "s/.*$i$//" "$TRASH_LOG"
			else
				echo "Error: file $i not found in $TRASH"
			fi
		done
	;;
	-h)	shift
		for i in "$@" ; do
			if (ls $TRASH/$i &>/dev/null); then
				mv $TRASH/$i $(pwd)
				sed -i "s/.*$i$//" "$TRASH_LOG"
			else
				echo "Error: file $i not found in $TRASH"
			fi
		done
	;;
	*)	for i in "$@" ; do
			if (ls $i &>/dev/null); then
				realpath "$i" >> "$TRASH_LOG"
				mv "$i" "$TRASH"
			fi
		done
	;;
esac
