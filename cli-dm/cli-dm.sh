#!/bin/bash
ColorOff=$'\e[0m';
Green=$'\e[0;32m';
Yellow=$'\e[0;33m';
Red=$'\e[0;31m';
dn=0
x_chk=$(ps -a | grep Xorg)
if [ -n "$x_chk" ]; then
	echo "${Red}ERROR! Xorg is already running!"
	exit 1
fi
clear
echo -e "${Yellow}\nWelcome to the Command Line Interface Display Manager!\n\nPlease select your desired enviornment:\n\n${Green}(1) Awesome\n(2) Gnome\n"
echo -n "${Yellow}[1,2,3...]: "
read input
if [ "$input" == "1" ]; then
	echo "exec awesome" > ~/.xinitrc
elif [ "$input" == "2" ]; then
	echo "exec gnome-session" > ~/.xinitrc
else
	echo "${Red}ERROR please enter then number for your enviornment${ColorOff}"
	exit 1
fi
startx
