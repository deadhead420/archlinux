#!/bin/bash
interface=$(ip addr | grep wlp | awk 'NR==1 {print $2}' | sed 's/://')
if [ -n "$interface" ]; then
    if (whiptail --title "Arch Linux Installer" --yesno "Would you like to connect to wifi?" 10 60) then
        wifi_menu "$interface"
    fi
fi

if (whiptail --title "Arch Linux Installer" --yesno "Welcome to the Deadhead arch-installer! \n Would you like to begin the install process?" 10 60) then
	ping -w 1.5 google.com &> /dev/null
	if [ "$?" -eq "0" ]; then	
		wget -O /root/.arch_installer.sh https://raw.githubusercontent.com/deadhead420/archlinux/master/arch-installer/arch-installer.sh &> /dev/null
    	if [ "$?" -eq "0" ]; then
    	    chmod +x /root/.arch_installer.sh
    	    source /root/.arch_installer.sh
    	else
    	    whiptail --title "Test Message Box" --msgbox "Something went wrong starting the installer. \n*Please try again: \n # arch-installer" 10 60
		fi
	else
		whiptail --title "Test Message Box" --msgbox "No internet connection found. \n*Check your connection and try again: \n # arch-installer" 10 60
		exit 1
	fi
else
	exit
fi
