#!/bin/bash
# This script is used to install mpd-conky on your computer.
# To run mpd-conky simply type "mpd-conky" into your shell of choice.
# To remove mpd-conky from your computer simply remove /usr/bin/mpd-conky as well as ~/.conky/mpd-conky

if [ ! -f /usr/bin/mpd ]; then
	echo "This program requires mpd in order to run. Please install mpd and try again"
	exit1
fi
if [ ! -f /usr/bin/mpc ]; then
	echo "This program requires mpc in order to run. Please install mpc and try again"
	exit1
fi
if [ ! -f /usr/bin/lynx ]; then
	echo "This program requires lynx in order to run. Please install lynx and try again"
	exit1
fi
if [ ! -f /usr/bin/wget ]; then
	echo "This program requires wget in order to run. Please install wget and try again"
	exit1
fi
if [ ! -d ~/.conky ]; then
	mkdir ~/.conky
fi
if [ ! -d ~/.covers ]; then
	mkdir ~/.covers
fi
if [ ! -d ~/.covers ]; then
	mkdir ~/.covers/album
fi
root_account() {
if [ "$UID" -eq "0" ]; then
	cd ..	
	cp -r mpd-conky/ ~/.conky/
	ln -s ~/.conky/mpd-conky/mpc_status.sh /usr/bin/mpd-conky
	end
else
	user_account
fi
}

user_account() {
if [ -e "/usr/bin/sudo" ]; then # check if sudo is installed
	cd ..
	cp -r mpd-conky/ ~/.conky/
	sudo ln -s ~/.conky/mpd-conky/mpc_status.sh /usr/bin/mpd-conky
	end
else
	cd ..
	cp -r mpd-conky/ ~/.conky/mpd
	echo
	echo "*sudo not detected* it is recommended to use sudo for administration from a user account."
	echo
	echo "To install mpd-conky please provide the root password"
	su -c ln -s ~/.conky/mpd-conky/mpc_status.sh /usr/bin/mpd-conky
	end
fi
}

end() {
echo "mpd-conky installed successfully, to run it now type "mpd-conky" into the terminal and press enter"
exit
}
root_account
