#!/bin/bash
sleep 2
ping -w 1.5 google.com &> /dev/null
if [ "$?" -gt "0" ]; then
	interface=$(ip addr | grep wlp | awk 'NR==1 {print $2}' | sed 's/://')
    if [ -n "$interface" ]; then
    	if (whiptail --title "Arch Linux Installer" --yesno "No connection found, would you like to connect to wifi?" 10 60) then
        	wifi_menu "$interface"
        	source .zprofile
        else
        	whiptail --title "Test Message Box" --msgbox "No internet connection found. \n *Check your connection and try running again: \n # source .zprofile" 10 60
            exit 1
        fi
    else
        whiptail --title "Test Message Box" --msgbox "No internet connection found. \n *Check your connection and try running again: \n # source .zprofile" 10 60
        exit 1
	fi
else
	if (whiptail --title "Arch Linux Installer" --yesno "Welcome to the Deadhead arch-installer! \n Would you like to begin the install process?" 10 60) then
		wget -O .arch_installer.sh https://raw.githubusercontent.com/deadhead420/archlinux/master/arch-installer/arch-installer.sh
    	if [ "$?" -eq "0" ]; then
    	    chmod +x .arch_installer.sh
    	    ./.arch_installer.sh
    	else
    	    whiptail --title "Test Message Box" --msgbox "Something went wrong starting the installer. \n *Please try again: \n # source .zprofile" 10 60
		fi
	else
		if (whiptail --title "Arch Linux Installer" --yesno "Are you sure you want to exit the installer? \n *You will be put into the CLI" 10 60) then
			exit
		else
			source .zprofile
		fi
	fi
fi
