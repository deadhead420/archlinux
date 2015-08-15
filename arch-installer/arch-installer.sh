#!/bin/bash

ARCH=/mnt
INSTALLED=false
BluBG=$'\e[44m';

set_locale() {
	clear
	echo -e ${BluBG}
	LOCALE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Please select your locale" 15 60 5 \
	"en_US.UTF-8" "-" \
	"en_AU.UTF-8" "-" \
	"en_CA.UTF-8" "-" \
	"en_GB.UTF-8" "-" \
	"Other"       "-"		 3>&1 1>&2 2>&3)
	if [ "$LOCALE" = "Other" ]; then
		localelist=$(</etc/locale.gen  awk '{print substr ($1,2) " " ($2);}' | grep -F ".UTF-8" | sed "1d" | sed 's/$/  -/g;s/ UTF-8//g')
		LOCALE=$(whiptail --title "Arch Linux Installer" --menu "Please enter your desired locale:" 15 60 5  $localelist 3>&1 1>&2 2>&3)
		if [ "$?" -gt "0" ]; then
			set_locale
		fi
	fi
	locale_set=true
	set_zone
}

set_zone() {
	zonelist=$(find /usr/share/zoneinfo -maxdepth 1 | sed -n -e 's!^.*/!!p' | grep -v "posix\|right\|zoneinfo\|zone.tab\|zone1970.tab\|W-SU\|WET\|posixrules\|MST7MDT\|iso3166.tab\|CST6CDT" | sort | sed 's/$/ -/g')
	ZONE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Please enter your time-zone:" 15 60 5 $zonelist 3>&1 1>&2 2>&3)
		check_dir=$(find /usr/share/zoneinfo -maxdepth 1 -type d | sed -n -e 's!^.*/!!p' | grep "$ZONE")
		if [ -n "$check_dir" ]; then
			sublist=$(find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g')
			SUBZONE=$(whiptail --title "Arch Linux Installer" --menu "Please enter your sub-zone:" 15 60 5 $sublist 3>&1 1>&2 2>&3)
			if [ "$?" -gt "0" ]; then
				set_zone
			fi
			chk_dir=$(find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 -type  d | sed -n -e 's!^.*/!!p' | grep "$SUBZONE")
			if [ -n "$chk_dir" ]; then
				sublist=$(find /usr/share/zoneinfo/"$ZONE"/"$SUBZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g')
				SUB_SUBZONE=$(whiptail --title "Arch Linux Installer" --menu "Please enter your sub-zone:" 15 60 5 $sublist 3>&1 1>&2 2>&3)
				if [ "$?" -gt "0" ]; then
					set_zone
				fi
			fi
		fi
	zone_set=true
	set_keys
}

set_keys() {
	keyboard=$(whiptail --nocancel --inputbox "Set key-map: \n If unsure leave default" 10 35 "us" 3>&1 1>&2 2>&3)
	loadkeys "$keyboard"
	keys_set=true
	prepare_drives
}

prepare_drives() {
	drive=$(lsblk | grep "disk" | grep -v "rom" | awk '{print $1"      "$4}')
	DRIVE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Select the drive you would like to install arch onto:" 15 60 5 $drive 3>&1 1>&2 2>&3)
	PART=$(whiptail --title "Arch Linux Installer" --menu "Select your desired method of partitioning:\nNOTE Auto Partition will format the selected drive" 15 60 4 \
	"Auto Partition Drive"          "-" \
	"Manual Partition Drive"        "-" \
	"Return To Menu"                "-" 3>&1 1>&2 2>&3)

	case "$PART" in
		"Auto Partition Drive")
			if (whiptail --title "Arch Linux Installer" --defaultno --yesno "WARNING! Will erase all data on /dev/$DRIVE!! \n Would you like to contunue? \n Select yes to continue" 10 60) then
				wipefs -a /dev/"$DRIVE"
			else
				prepare_drives
			fi
			SWAP=false
			if (whiptail --title "Arch Linux Installer" --yesno "Create SWAP space?" 15 60) then
				SWAP=true
				SWAPSPACE=$(whiptail --nocancel --inputbox "Specify desired swap size \n (Align to M or G):" 10 35 "512M" 3>&1 1>&2 2>&3)
			fi				
			GPT=false
			if (whiptail --title "Arch Linux Installer" --defaultno --yesno "Would you like to use GPT partitioning?" 15 60) then
				GPT=true
			fi
			if "$GPT" ; then
				if "$SWAP" ; then
					echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n4\n\n+$SWAPSPACE\n8200\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" > /dev/null
					BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
					SWAP="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==5) print substr ($1,3) }')"
					ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
					echo -e ${BluBG}
					clear
					wipefs -a /dev/"$BOOT"
					mkfs.ext4 /dev/"$BOOT"
					wipefs -a /dev/"$ROOT"
					mkfs.ext4 /dev/"$ROOT"
					wipefs -a /dev/"$SWAP"
					mkswap /dev/"$SWAP"
					swapon /dev/"$SWAP"
					mount /dev/"$ROOT" "$ARCH"
					if [ "$?" -eq "0" ]; then
						mounted=true
					fi
					mkdir $ARCH/boot
					mount /dev/"$BOOT" "$ARCH"/boot
				else
					echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" > /dev/null
					BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
					ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
					echo -e ${BluBG}
					clear
					wipefs -a /dev/"$BOOT"
					mkfs.ext4 /dev/"$BOOT"
					wipefs -a /dev/"$ROOT"
					mkfs.ext4 /dev/"$ROOT"
					mount /dev/"$ROOT" "$ARCH"
					if [ "$?" -eq "0" ]; then
						mounted=true
					fi
					mkdir "$ARCH"/boot
					mount /dev/"$BOOT" "$ARCH"/boot
				fi
			else
				if "$SWAP" ; then
					echo -e "o\nn\np\n1\n\n+100M\nn\np\n3\n\n+$SWAPSPACE\nt\n\n82\nn\np\n2\n\n\nw" | fdisk /dev/"$DRIVE" > /dev/null
					BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
					ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"
					SWAP="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
					clear
					echo -e ${BluBG}
					wipefs -a -q /dev/"$BOOT"
					mkfs.ext4 -q /dev/"$BOOT"
					wipefs -a -q /dev/"$ROOT"
					mkfs.ext4 -q /dev/"$ROOT"
			        wipefs -a -q /dev/"$SWAP"
					mkswap /dev/"$SWAP"
					swapon /dev/"$SWAP"
		            mount /dev/"$ROOT" "$ARCH"
					if [ "$?" -eq "0" ]; then
						mounted=true
					fi
					mkdir "$ARCH"/boot		
					mount /dev/"$BOOT" "$ARCH"/boot			
				else
					echo -e "o\nn\np\n1\n\n+100M\nn\np\n2\n\n\nw" | fdisk /dev/"$DRIVE" > /dev/null
					BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
					ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"
					clear
					echo -e ${BluBG}
					wipefs -a /dev/"$BOOT"
					mkfs.ext4 -q /dev/"$BOOT"
					wipefs -a /dev/"$ROOT"
					mkfs.ext4 -q /dev/"$ROOT"
					mount /dev/"$ROOT" "$ARCH"
					if [ "$?" -eq "0" ]; then
						mounted=true
					fi
					mkdir "$ARCH"/boot
					mount /dev/"$BOOT" "$ARCH"/boot
				fi
	 		fi
		;;
		"Manual Partition Drive")
			clear
			echo -e ${BluBG}
			part_tool=$(whiptail --title "Arch Linux Installer" --menu "Please select your desired partitioning tool:" 15 60 5 \
																							"cfdisk"  "Best for beginners" \
																							"fdisk"  "Command line Partitioning Tool" \
																							"gdisk"  "GPT fdisk" \
																							"parted"  "GNU Parted" 3>&1 1>&2 2>&3)
			if [ "$?" -gt "0" ]; then
				prepare_drives
			fi
			$part_tool /dev/"$DRIVE"
			if [ "$?" -gt "0" ]; then
				whiptail --title "Arch Linux Installer" --msgbox "An error was detected during partitioning \n Returing partitioning menu" 10 60
				prepare_drives
			fi
			partition=$(lsblk | grep "$DRIVE" | grep -v "/" | sed "1d" | cut -c7- | awk '{print $1" "$4}')
			ROOT=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Please select your desired root partition first:" 15 60 5 $partition 3>&1 1>&2 2>&3)
			if (whiptail --title "Arch Linux Installer" --yesno "This will create a new filesystem on /dev/$ROOT and mount it as the root filesystem. \nAre you sure you want to do this?" 10 60) then
				wipefs -a /dev/"$ROOT"
				mkfs.ext4 /dev/"$ROOT" > /dev/null
				mount /dev/"$ROOT" "$ARCH"
				if [ "$?" -eq "0" ]; then
					mounted=true
				else
					whiptail --title "Arch Linux Installer" --msgbox "An error was detected during partitioning \n Returing partitioning menu" 10 60
					prepare_drives
				fi
			else
				prepare_drives
			fi
			points=$(echo -e "/boot   >\n/home   >\n/srv    >\n/usr    >\n/var    >\nSWAP   >")
			until [ "$new_mnt" == "Done" ] 
				do
					partition=$(lsblk | grep "$DRIVE" | grep -v "/\|[SWAP]" | sed "1d" | cut -c7- | awk '{print $1"     "$4}')
					new_mnt=$(whiptail --title "Arch Linux Installer" --nocancel --menu "Select a partition to create a mount point: \n Select done when finished" 15 60 5 $partition "Done" "Continue" 3>&1 1>&2 2>&3)
					if [ "$new_mnt" != "Done" ]; then
						MNT=$(whiptail --title "Arch Linux Installer" --menu "Select a mount point for /dev/$new_mnt" 15 60 5 $points 3>&1 1>&2 2>&3)				
						if [ "$?" -eq "0" ]; then
							:
						elif [ "$MNT" == "SWAP" ]; then
							if (whiptail --title "Arch Linux Installer" --yesno "Will create swap space on /dev/$new_mnt \n Continue?" 10 60) then
								wipefs -a /dev/"$new_mnt"
								mkswap /dev/"$new_mnt" > /dev/null
								swapon /dev/"$new_mnt"
							fi
						else
							if (whiptail --title "Arch Linux Installer" --yesno "Will create mount point $MNT with /dev/$new_mnt \n Continue?" 10 60) then
								wipefs -a /dev/"$new_mnt"
								mkfs.ext4 /dev/"$new_mnt" > /dev/null
								mkdir "$ARCH"/"$MNT"
								mount /dev/"$new_mnt" "$ARCH"/"$MNT"
								points=$(echo  "$points" | grep -v "$MNT")
							fi
						fi
					fi
				done
		;;
		"Return To Menu")
			if (whiptail --title "Arch Linux Installer" --yesno "Are you sure you want to return to menu?" 10 60) then
				main_menu
			else
				prepare_drives

			fi
		;;
	esac
	if [ "$mounted" != "true" ]; then
		whiptail --title "Arch Linux Installer" --msgbox "An error was detected during partitioning \n Returing to drive partitioning" 10 60
		prepare_drives
	fi
	update_mirrors
}

update_mirrors() {
	countries=$(echo -e "AT Austria\n AU  Australia\n BE Belgium\n BG Bulgaria\n BR Brazil\n BY Belarus\n CA Canada\n CL Chile \n CN China\n CO Columbia\n CZ Czech-Republic\n DK Denmark\n EE Estonia\n ES Spain\n FI Finland\n FR France\n GB United-Kingdom\n HU Hungary\n IE Ireland\n IL Isreal\n IN India\n IT Italy\n JP Japan\n KR Korea\n KZ Kazakhstan\n LK Sri-Lanka\n LU Luxembourg\n LV Lativia\n MK Macedonia\n NC New-Caledonia\n NL Netherlands\n NO Norway\n NZ New-Zealand\n PL Poland\n PT Portugal\n RO Romania\n RS Serbia\n RU Russia\n SE Sweden\n SG Singapore\n SK Slovakia\n TR Turkey\n TW Taiwan\n UA Ukraine\n US United-States\n UZ Uzbekistan\n VN Viet-Nam\n ZA South-Africa")
	if (whiptail --title "Arch Linux Installer" --yesno "Would you like to update your mirrorlist now?" 10 60) then
		code=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Select your country code:" 15 60 5 $countries 3>&1 1>&2 2>&3)
		wget --append-output=/dev/null "https://www.archlinux.org/mirrorlist/?country=$code&protocol=http" -O /etc/pacman.d/mirrorlist 
  		sed -i 's/#//' /etc/pacman.d/mirrorlist
  		mirrors_updated=true
	fi
	clear
	install_base
}

install_base() {
	if [[ -n "$ROOT" && "$INSTALLED" == "false" && "$mounted" == "true" ]]; then	
		if (whiptail --title "Arch Linux Installer" --yesno "Begin installing base system onto /dev/$DRIVE?" 10 60) then
			echo -e ${BluBG}
			pacstrap "$ARCH" base base-devel
			if [ "$?" -eq "0" ]; then
				INSTALLED=true
			else
				INSTALLED=false
				whiptail --title "Arch Linux Installer" --msgbox "An error occured returning to menu" 10 60
				main_menu
			fi
			genfstab -U -p "$ARCH" >> "$ARCH"/etc/fstab
			intel=$(< /proc/cpuinfo grep vendor_id | grep -iq intel)
			if [ -n "$intel" ]; then
				pacstrap $ARCH intel-ucode
			fi
			configure_system
		else
			if (whiptail --title "Arch Linux Installer" --yesno "Ready to install system to $ARCH \n Are you sure you want to exit to menu?" 10 60) then
				main_menu
			else
				install_base
			fi
		fi
	else
		if [ "$INSTALLED" == "true" ]; then
			if (whiptail --title "Arch Linux Installer" --yesno "Error root filesystem already installed at $ARCH. \n Begin configuring system?" 10 60) then
				configure_system
			else
				whiptail --title "Test Message Box" --msgbox "Error root filesystem already installed at $ARCH \n Continuing to menu." 10 60
				main_menu
			fi
		else
			if (whiptail --title "Arch Linux Installer" --yesno "Error no filesystem mounted \n Return to drive partitioning?" 10 60) then
				partition_drives
			else
				whiptail --title "Test Message Box" --msgbox "Error no filesystem mounted \n Continuing to menu." 10 60
				main_menu
			fi
		fi
	fi
}

configure_system() {
	if [ "$INSTALLED" == "true" ]; then
			sed -i -e "s/#$LOCALE/$LOCALE/" "$ARCH"/etc/locale.gen
			echo LANG="$LOCALE" > "$ARCH"/etc/locale.conf
			arch-chroot "$ARCH" locale-gen
			arch-chroot "$ARCH" loadkeys "$keyboard"
			if [ -n "$SUB_SUBZONE" ]; then
				arch-chroot "$ARCH" ln -s /usr/share/zoneinfo/"$ZONE"/"$SUBZONE"/"$SUB_SUBZONE" /etc/localtime
			elif [ -n "$SUBZONE" ]; then
				arch-chroot "$ARCH" ln -s /usr/share/zoneinfo/"$ZONE"/"$SUBZONE" /etc/localtime
			elif [ -n "$ZONE" ]; then
				arch-chroot "$ARCH" ln -s /usr/share/zoneinfo/"$ZONE" /etc/localtime
			fi
			arch=$(uname -a | grep -o "x86_64\|i386\|i686")
			if [ "$arch" == "x86_64" ]; then
				if (whiptail --title "Arch Linux Installer" --yesno "64 bit architecture detected\nAdd multilib repos to pacman.conf?" 10 60) then
					sed -i '/\[multilib]$/ {
					N
					/Include/s/#//g}' /mnt/etc/pacman.conf
				fi
			fi
			if (whiptail --title "Arch Linux Installer" --yesno "Would you like to add archlinuxfr to your pacman.conf?" 10 60) then
				echo -e "[archlinuxfr]\nServer = http://repo.archlinux.fr/\$arch\nSigLevel = Never" >> /mnt/etc/pacman.conf
			fi
			system_configured=true
			clear
			set_hostname
	else
		whiptail --title "Test Message Box" --msgbox "Error no root filesystem installed at $ARCH \n Continuing to menu." 10 60
		main_menu
	fi
}

set_hostname() {
	if [ "$INSTALLED" == "true" ]; then
		hostname=$(whiptail --nocancel --inputbox "Set hostname:" 10 40 "arch" 3>&1 1>&2 2>&3)
		echo "$hostname" > "$ARCH"/etc/hostname
		echo "<####################################################>"
		echo "Please enter the root password: "
		arch-chroot "$ARCH" passwd
		while [ "$?" -gt "0" ]
			do
				arch-chroot "$ARCH" passwd
			done
		clear
		add_user
	else
		whiptail --title "Test Message Box" --msgbox "Error no root filesystem installed at $ARCH \n Continuing to menu." 10 60
		main_menu
	fi
}

add_user() {
	if [ "$user_added" == "true" ]; then
		if (whiptail --title "Arch Linux Installer" --yesno "User already added, create new sudo user now?" 10 60) then
			usrname=$(whiptail --nocancel --inputbox "Set username:" 10 40 "" 3>&1 1>&2 2>&3)
			arch-chroot "$ARCH" useradd -m -g users -G wheel,audio,network,power,storage,optical -s /bin/bash "$usrname"
			echo "<####################################################>"
			echo "Please enter the sudo password for $usrname: "
			arch-chroot "$ARCH" passwd "$usrname"
			while [ "$?" -gt "0" ]
				do
					arch-chroot "$ARCH" passwd "$usrname"
				done
		fi
		main_menu
	elif [ "$INSTALLED" == "true" ]; then
		if (whiptail --title "Arch Linux Installer" --yesno "Create a new sudo user now?" 10 60) then
			usrname=$(whiptail --nocancel --inputbox "Set username:" 10 40 "" 3>&1 1>&2 2>&3)
		else
			configure_network
		fi
		arch-chroot "$ARCH" useradd -m -g users -G wheel,audio,network,power,storage,optical -s /bin/bash "$usrname"
		echo "<####################################################>"
		echo "Please enter the sudo password for $usrname: "
		arch-chroot "$ARCH" passwd "$usrname"
		while [ "$?" -gt "0" ]
			do
				arch-chroot "$ARCH" passwd "$usrname"
			done
		clear
		if (whiptail --title "Arch Linux Installer" --yesno "Enable sudo privelege for members of wheel?" 10 60) then
			sed -i '/%wheel ALL=(ALL) ALL/s/^#//' $ARCH/etc/sudoers
		fi
		user_added=true
		configure_network
	else
		whiptail --title "Test Message Box" --msgbox "Error no root filesystem installed at $ARCH \n Continuing to menu." 10 60
		main_menu
	fi
}

configure_network() {
	if [ "$INSTALLED" == "true" ]; then
		#Enable DHCP
			if (whiptail --title "Arch Linux Installer" --yesno "Enable DHCP at boot?" 10 60) then
				arch-chroot "$ARCH" systemctl enable dhcpcd.service
			fi
			clear
		#Enable SSH
			if (whiptail --title "Arch Linux Installer" --yesno "Enable SSH at boot?" 10 60) then
				pacstrap $ARCH openssh
				arch-chroot "$ARCH" systemctl enable sshd.service
			fi
			clear
			install_bootloader
	else
		whiptail --title "Test Message Box" --msgbox "Error no root filesystem installed at $ARCH \n Continuing to menu." 10 60
		main_menu
	fi
}

install_bootloader() {
	if [ "$INSTALLED" == "true" ]; then
			if (whiptail --title "Arch Linux Installer" --yesno "Install GRUB onto /dev/$DRIVE?" 10 60) then
				if (whiptail --title "Arch Linux Installer" --yesno "Install os-prober first \n Required to dualboot with windows or mac OSX" 10 60) then
					pacstrap "$ARCH" os-prober
				fi
				pacstrap "$ARCH" grub-bios
				arch-chroot "$ARCH" grub-install --recheck /dev/"$DRIVE"
				if [ "$?" -eq "0" ]; then
					loader_installed=true
				else
					whiptail --title "Arch Linux Installer" --msgbox "An error occured returning to menu" 10 60
					main_menu
				fi
				arch-chroot "$ARCH" grub-mkconfig -o /boot/grub/grub.cfg
				clear
				reboot_system
			fi
	else
		whiptail --title "Test Message Box" --msgbox "Error no root filesystem installed at $ARCH \n Continuing to menu." 10 60
		main_menu
	fi
	main_menu
}

reboot_system() {
	if [[ "$INSTALLED" == "true" && "$loader_installed" == "true" ]]; then	
		if (whiptail --title "Arch Linux Installer" --yesno "Install process complete! Reboot now?" 10 60) then
			umount -R $ARCH
			reboot
		else
			whiptail --title "Arch Linux Installer" --msgbox "System fully installed \n Exiting arch installer" 10 60
			exit
		fi
	else
		if (whiptail --title "Arch Linux Installer" --yesno "Install not complete, are you sure you want to reboot?" 10 60) then
			umount -R $ARCH
			reboot
		else
			main_menu
		fi
	fi
}

main_menu() {
	menu_item=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Menu Items:" 15 60 5 \
		"Set Locale"          "-" \
		"Set Timezone"        "-" \
		"Set Keymap"          "-" \
		"Partition Drive"     "-" \
		"Update Mirrors"      "-" \
		"Install Base System" "-" \
		"Configure System"    "-" \
		"Set Hostname"        "-" \
		"Add User"            "-" \
		"Configure Network"   "-" \
		"Install Bootloader"  "-" \
		"Reboot System"       "-" \
		"Exit Installer"      "-" 3>&1 1>&2 2>&3)
	case "$menu_item" in
		"Set Locale" ) 
			if [ "$locale_set" == "true" ]; then
				whiptail --title "Arch Linux Installer" --msgbox "Locale already set, returning to menu" 10 60
				main_menu
			fi	
			set_locale
		;;
		"Set Timezone")
			if [ "$zone_set" == "true" ]; then
				whiptail --title "Arch Linux Installer" --msgbox "Timezone already set, returning to menu" 10 60
				main_menu
			fi	
			 set_zone
		;;
		"Set Keymap")
			if [ "$keys_set" == "true" ]; then
				whiptail --title "Arch Linux Installer" --msgbox "Keymap already set, returning to menu" 10 60
				main_menu
			fi	
			set_keys
		;;
		"Partition Drive")
			if [ "$mounted" == "true" ]; then
				whiptail --title "Arch Linux Installer" --msgbox "Drive already mounted, try install base system \n returning to menu" 10 60
				main_menu
			fi	
 			prepare_drives
		;;
		"Update Mirrors") update_mirrors
		;;
		"Install Base System") install_base
		;;
		"Configure System")
			if [ "$INSTALLED" == "true" ]; then
				if [ "$system_configured" != "true" ]; then
					configure_system
				else
					whiptail --title "Arch Linux Installer" --msgbox "System already configured \n returning to menu" 10 60
					main_menu
				fi
			else
				whiptail --title "Arch Linux Installer" --msgbox "The system hasn't been installed yet \n returning to menu" 10 60
				main_menu
			fi
		;;
		"Set Hostname")
			if [ "$INSTALLED" == "true" ]; then
				set_hostname
			else
				whiptail --title "Arch Linux Installer" --msgbox "The system hasn't been installed yet \n returning to menu" 10 60
				main_menu
			fi
		;;
		"Add User")
			if [ "$INSTALLED" == "true" ]; then
				add_user
			else
				whiptail --title "Arch Linux Installer" --msgbox "The system hasn't been installed yet \n returning to menu" 10 60
				main_menu
			fi
		;;
		"Configure Network")
			if [ "$INSTALLED" == "true" ]; then
				configure_network
			else
				whiptail --title "Arch Linux Installer" --msgbox "The system hasn't been installed yet \n returning to menu" 10 60
				main_menu
			fi
		;;
		"Install Bootloader")
			if [ "$INSTALLED" == "true" ]; then
				install_bootloader
			else
				whiptail --title "Arch Linux Installer" --msgbox "The system hasn't been installed yet \n returning to menu" 10 60
				main_menu
			fi
		;;
		"Reboot System")
			reboot_system
		;;
		"Exit Installer")
			if [[ "$INSTALLED" == "true" && "$loader_installed" == "true" ]]; then
				whiptail --title "Arch Linux Installer" --msgbox "System fully installed \n Exiting arch installer" 10 60
				exit
			else
				if (whiptail --title "Arch Linux Installer" --yesno "System not installed yet \n Are you sure you want to exit?" 10 60) then
					exit
				else
					main_menu
				fi
			fi
		;;
	esac
}

set_locale
