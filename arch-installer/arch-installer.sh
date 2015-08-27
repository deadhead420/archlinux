#!/bin/bash

ARCH=/mnt
INSTALLED=false
BluBG=$'\e[44m';

check_connection() {
	clear
	ping -w 1.5 google.com &> /dev/null
	if [ "$?" -gt "0" ]; then
		whiptail --title "Test Message Box" --msgbox "No internet connection found. \n *Check your connection and try again" 10 60
		exit 1
	fi
	start=$(date +%s)
	wget http://cachefly.cachefly.net/10mb.test &> /dev/null &
	pid=$! pri=1 msg="Please wait while we test your connection..." load
	end=$(date +%s)
	diff=$((end-start))
	case "$diff" in
		[1-4]) down="0.5" ;;
		[5-9]) down="1.5" ;;
		1[0-9]) down="3" ;;
		2[0-9]) down="4" ;;
		3[0-9]) down="5" ;;
		4[0-9]) down="6" ;;
		5[0-9]) down="7" ;;
		6[0-9]) down="8" ;;
		[0-9][0-9][0-9]) 
			if (whiptail --title "Arch Linux Installer" --yesno "Your connection is very slow, this might take a long time...\n *Continue?" 10 60) then
				down="15"
			else
				exit
			fi
		;;
		*) down="10" ;;
	esac
	set_locale
}

set_locale() {
	echo -e ${BluBG}
	clear
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
	keys_set=true
	prepare_drives
}

prepare_drives() {
	drive=$(lsblk | grep "disk" | grep -v "rom" | awk '{print $1   " "   $4}')
	DRIVE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Select the drive you would like to install arch onto:" 15 60 5 $drive 3>&1 1>&2 2>&3)
	PART=$(whiptail --title "Arch Linux Installer" --menu "Select your desired method of partitioning:\nNOTE Auto Partition will format the selected drive" 15 60 6 \
	"Auto Partition Drive"           "-" \
	"Auto partition encrypted LVM"   "-" \
	"Manual Partition Drive"         "-" \
	"Return To Menu"                 "-" 3>&1 1>&2 2>&3)
	if [ "$PART" == "Auto partition encrypted LVM" ] || [ "$PART" == "Auto Partition Drive" ]; then
		if (whiptail --title "Arch Linux Installer" --defaultno --yesno "WARNING! Will erase all data on /dev/$DRIVE! \n Would you like to contunue?" 10 60) then
			sgdisk --zap-all "$DRIVE"
		else
			prepare_drives
		fi
		SWAP=false
		if (whiptail --title "Arch Linux Installer" --yesno "Create SWAP space?" 10 60) then
			SWAP=true
			SWAPSPACE=$(whiptail --nocancel --inputbox "Specify desired swap size \n (Align to M or G):" 10 35 "512M" 3>&1 1>&2 2>&3)
		fi
#		UEFI=false
#		if (whiptail --title "Arch Linux Installer" --defaultno --yesno "Would you like to enable UEFI bios?" 10 60) then
#			GPT=true			
#			UEFI=true
#		else
			GPT=false
			if (whiptail --title "Arch Linux Installer" --defaultno --yesno "Would you like to use GPT partitioning?" 10 60) then
				GPT=true
			fi
#		fi
		clear
	else
		part_tool=$(whiptail --title "Arch Linux Installer" --menu "Please select your desired partitioning tool:" 15 60 5 \
																	"cfdisk"  "Curses Interface" \
																	"fdisk"   "CLI Partitioning" \
																	"gdisk"   "GPT Partitioning" \
																	"parted"  "GNU Parted CLI" 3>&1 1>&2 2>&3)
		if [ "$?" -gt "0" ]; then
			prepare_drives
		fi

	fi
	case "$PART" in
		"Auto Partition Drive")
			if "$GPT" ; then
				if "$SWAP" ; then
					echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n4\n\n+$SWAPSPACE\n8200\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" &> /dev/null
					SWAP="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==5) print substr ($1,3) }')"
					wipefs -a -q /dev/"$SWAP"
					mkswap /dev/"$SWAP" &> /dev/null
					swapon /dev/"$SWAP" &> /dev/null
				else
					echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" &> /dev/null
				fi
					BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"	
					ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
					wipefs -a -q /dev/"$BOOT"
					wipefs -a -q /dev/"$ROOT"
					echo -e ${BluBG}
					clear
					mkfs.ext4 -q /dev/"$BOOT" &> /dev/null
					mkfs.ext4 -q /dev/"$ROOT" &
					pid=$! pri=1 msg="Please wait while creating filesystem" load
					mount /dev/"$ROOT" "$ARCH"
					if [ "$?" -eq "0" ]; then
						mounted=true
					fi
					mkdir $ARCH/boot
					mount /dev/"$BOOT" "$ARCH"/boot
			else
				if "$SWAP" ; then
					echo -e "o\nn\np\n1\n\n+100M\nn\np\n3\n\n+$SWAPSPACE\nt\n\n82\nn\np\n2\n\n\nw" | fdisk /dev/"$DRIVE" &> /dev/null
					SWAP="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"					
					wipefs -a -q /dev/"$SWAP"
					mkswap /dev/"$SWAP" &> /dev/null
					swapon /dev/"$SWAP" &> /dev/null
				else
					echo -e "o\nn\np\n1\n\n+100M\nn\np\n2\n\n\nw" | fdisk /dev/"$DRIVE" &> /dev/null
				fi
				BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
				ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"
				wipefs -a -q /dev/"$BOOT"
				wipefs -a -q /dev/"$ROOT"
				clear
				echo -e ${BluBG}
				mkfs.ext4 -q /dev/"$BOOT" &> /dev/null
				mkfs.ext4 -q /dev/"$ROOT" &
				pid=$! pri=1 msg="Please wait while creating filesystem" load
		        mount /dev/"$ROOT" "$ARCH"
				if [ "$?" -eq "0" ]; then
					mounted=true
				fi
				mkdir "$ARCH"/boot		
				mount /dev/"$BOOT" "$ARCH"/boot
			fi
		;;
		"Auto partition encrypted LVM")
			if "$GPT" ; then
				echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" &> /dev/null
				ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
				BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
			else
				echo -e "o\nn\np\n1\n\n+100M\nn\np\n2\n\n\nw" | fdisk /dev/"$DRIVE" &> /dev/null
				BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
				ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"
				
			fi
			lvm pvcreate /dev/"$ROOT" &> /dev/null
			lvm vgcreate lvm /dev/"$ROOT" &> /dev/null
			if "$SWAP" ; then
				lvm lvcreate -L $SWAPSPACE -n swap lvm &> /dev/null
			fi
			lvm lvcreate -L 500M -n tmp lvm &> /dev/null
			lvm lvcreate -l 100%FREE -n lvroot lvm &> /dev/null
            clear
            echo "This will encrypt /dev/$ROOT are you sure you want to continue? [ y/N ]: "
            read input
            if [ "$input" == [y][Y][yes][""] ]; then
				cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/lvm/lvroot
				cryptsetup open --type luks /dev/lvm/lvroot root
				mkfs -q -t ext4 /dev/mapper/root &> /dev/null &
				pid=$! pri=1 msg="Please wait while creating encrypted filesystem" load
				mount -t ext4 /dev/mapper/root "$ARCH"
				if [ "$?" -eq "0" ]; then
					mounted=true
					crypted=true
				fi
				wipefs -a /dev/"$BOOT"
				mkfs -q -t ext4 /dev/"$BOOT" &> /dev/null
				mkdir "$ARCH"/boot
				mount -t ext4 /dev/"$BOOT" "$ARCH"/boot
			else
				prepare_drives
			fi
		;;
		"Manual Partition Drive")
			$part_tool /dev/"$DRIVE"
			echo -e ${BluBG}
			clear
			if [ "$?" -gt "0" ]; then
				whiptail --title "Arch Linux Installer" --msgbox "An error was detected during partitioning \n Returing partitioning menu" 10 60
				prepare_drives
			fi
			partition=$(lsblk | grep "$DRIVE" | grep -v "/\|1K" | sed "1d" | cut -c7- | awk '{print $1" "$4}')
			ROOT=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Please select your desired root partition first:" 15 60 5 $partition 3>&1 1>&2 2>&3)
			if (whiptail --title "Arch Linux Installer" --yesno "This will create a new filesystem on the partition. \nAre you sure you want to do this?" 10 60) then
				wipefs -a -q /dev/"$ROOT"
				mkfs.ext4 -q /dev/"$ROOT" &> /dev/null &
				pid=$! pri=1 msg="Please wait while creating filesystem" load
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
					partition=$(lsblk | grep "$DRIVE" | grep -v "/\|[SWAP]\|1K" | sed "1d" | cut -c7- | awk '{print $1"     "$4}')
					new_mnt=$(whiptail --title "Arch Linux Installer" --nocancel --menu "Select a partition to create a mount point: \n *Select done when finished*" 15 60 5 $partition "Done" "Continue" 3>&1 1>&2 2>&3)
					if [ "$new_mnt" != "Done" ]; then
						MNT=$(whiptail --title "Arch Linux Installer" --menu "Select a mount point for /dev/$new_mnt" 15 60 5 $points 3>&1 1>&2 2>&3)				
						if [ "$?" -gt "0" ]; then
							:
						elif [ "$MNT" == "SWAP" ]; then
							if (whiptail --title "Arch Linux Installer" --yesno "Will create swap space on /dev/$new_mnt \n Continue?" 10 60) then
								wipefs -a -q /dev/"$new_mnt"
								mkswap /dev/"$new_mnt" &> /dev/null
								swapon /dev/"$new_mnt" &> /dev/null
							fi
						else
							if (whiptail --title "Arch Linux Installer" --yesno "Will create mount point $MNT with /dev/$new_mnt \n Continue?" 10 60) then
								wipefs -a -q /dev/"$new_mnt"
								mkfs.ext4 -q /dev/"$new_mnt" &> /dev/null &
								pid=$! pri=1 msg="Please wait while creating filesystem" load
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
	clear
	update_mirrors
}

update_mirrors() {
	countries=$(echo -e "AT Austria\n AU  Australia\n BE Belgium\n BG Bulgaria\n BR Brazil\n BY Belarus\n CA Canada\n CL Chile \n CN China\n CO Columbia\n CZ Czech-Republic\n DK Denmark\n EE Estonia\n ES Spain\n FI Finland\n FR France\n GB United-Kingdom\n HU Hungary\n IE Ireland\n IL Isreal\n IN India\n IT Italy\n JP Japan\n KR Korea\n KZ Kazakhstan\n LK Sri-Lanka\n LU Luxembourg\n LV Lativia\n MK Macedonia\n NC New-Caledonia\n NL Netherlands\n NO Norway\n NZ New-Zealand\n PL Poland\n PT Portugal\n RO Romania\n RS Serbia\n RU Russia\n SE Sweden\n SG Singapore\n SK Slovakia\n TR Turkey\n TW Taiwan\n UA Ukraine\n US United-States\n UZ Uzbekistan\n VN Viet-Nam\n ZA South-Africa")
	if (whiptail --title "Arch Linux Installer" --yesno "Would you like to update your mirrorlist now?" 10 60) then
		code=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Select your country code:" 15 60 5 $countries 3>&1 1>&2 2>&3)
		wget --append-output=/dev/null "https://www.archlinux.org/mirrorlist/?country=$code&protocol=http" -O /etc/pacman.d/mirrorlist.bak &
		pid=$! pri=0.5 msg="Retreiving new mirrorlist..." load
		sed -i 's/#//' /etc/pacman.d/mirrorlist.bak
		rankmirrors -n 6 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist &
  		pid=$! pri=0.5 msg="Please wait while ranking mirrors" load
  		mirrors_updated=true
	fi
	install_base
}

install_base() {
	if [[ -n "$ROOT" && "$INSTALLED" == "false" && "$mounted" == "true" ]]; then	
		if (whiptail --title "Arch Linux Installer" --yesno "Begin installing Arch Linux base onto /dev/$DRIVE?" 10 60) then
			echo -e ${BluBG}
			pacstrap "$ARCH" base base-devel libnewt &> /dev/null &
			pid=$! pri="$down" msg="Please wait while we install Arch Linux... \n *This may take awhile" load
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
			clear
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
				whiptail --title "Test Message Box" --msgbox "Error root filesystem already installed at $ARCH \n Continuing to menu." 10 60
				main_menu
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
		if [ "$system_configured" == "true" ]; then
			whiptail --title "Test Message Box" --msgbox "Error system already configured \n Continuing to menu." 10 60
			main_menu
		fi
		if [ "$crypted" == "true" ]; then
			sed -i 's/k filesystems k/k lvm2 encrypt filesystems k/' "$ARCH"/etc/mkinitcpio.conf
			arch-chroot "$ARCH" mkinitcpio -p linux &> /dev/null &
			pid=$! pri=1 msg="Please wait while configuring kernel for encryption" load
		fi
		sed -i -e "s/#$LOCALE/$LOCALE/" "$ARCH"/etc/locale.gen
		echo LANG="$LOCALE" > "$ARCH"/etc/locale.conf
		arch-chroot "$ARCH" locale-gen &> /dev/null
		arch-chroot "$ARCH" loadkeys "$keyboard" &> /dev/null
		if [ -n "$SUB_SUBZONE" ]; then
			arch-chroot "$ARCH" ln -s /usr/share/zoneinfo/"$ZONE"/"$SUBZONE"/"$SUB_SUBZONE" /etc/localtime
		elif [ -n "$SUBZONE" ]; then
			arch-chroot "$ARCH" ln -s /usr/share/zoneinfo/"$ZONE"/"$SUBZONE" /etc/localtime
		elif [ -n "$ZONE" ]; then
			arch-chroot "$ARCH" ln -s /usr/share/zoneinfo/"$ZONE" /etc/localtime
		fi
		arch=$(uname -a | grep -o "x86_64\|i386\|i686")
		if [ "$arch" == "x86_64" ]; then
			if (whiptail --title "Arch Linux Installer" --yesno "*64 bit architecture detected\nAdd multilib repos to pacman.conf?" 10 60) then
				sed -i '/\[multilib]$/ {
				N
				/Include/s/#//g}' /mnt/etc/pacman.conf
				multilib=true
			fi
		fi
		if (whiptail --title "Arch Linux Installer" --yesno "Would you like to add archlinuxfr to your pacman.conf?" 10 60) then
			echo -e "[archlinuxfr]\nServer = http://repo.archlinux.fr/\$arch\nSigLevel = Never" >> /mnt/etc/pacman.conf
		fi
		system_configured=true
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
		user=root
		echo -e 'user='$user'
			input=default
			while [ "$input" != "$input_chk" ]
                		do
                       			 input=$(whiptail --passwordbox --nocancel "Please enter a new $user password" 8 78 --title "Arch Linux Installer" 3>&1 1>&2 2>&3)
                		         input_chk=$(whiptail --passwordbox --nocancel "New $user password again" 8 78 --title "Arch Linux Installer" 3>&1 1>&2 2>&3)
                       			 if [ "$input" != "$input_chk" ]; then
                          		      whiptail --title "Test Message Box" --msgbox "Passwords do not match, please try again." 10 60
                         		 fi
             		        done
        			echo -e "$input\n$input\n" | passwd "$user" &> /dev/null' > /mnt/root/set.sh
		chmod +x "$ARCH"/root/set.sh
		arch-chroot "$ARCH" ./root/set.sh
		rm "$ARCH"/root/set.sh
		add_user
	else
		whiptail --title "Test Message Box" --msgbox "Error no root filesystem installed at $ARCH \n Continuing to menu." 10 60
		main_menu
	fi
}

add_user() {
	if [ "$user_added" == "true" ]; then
		whiptail --title "Test Message Box" --msgbox "User already added \n Continuing to menu." 10 60
		main_men
	elif [ "$INSTALLED" == "true" ]; then
		if (whiptail --title "Arch Linux Installer" --yesno "Create a new sudo user now?" 10 60) then
			user=$(whiptail --nocancel --inputbox "Set username:" 10 40 "" 3>&1 1>&2 2>&3)
		else
			configure_network
		fi
		arch-chroot "$ARCH" useradd -m -g users -G wheel,audio,network,power,storage,optical -s /bin/bash "$user"
		echo -e 'user='$user'
				   input=default
				           while [ "$input" != "$input_chk" ]
                				do
                       					 input=$(whiptail --passwordbox --nocancel "Please enter a new password for $user" 8 78 --title "Arch Linux Installer" 3>&1 1>&2 2>&3)
                				         input_chk=$(whiptail --passwordbox --nocancel "New password for $user again" 8 78 --title "Arch Linux Installer" 3>&1 1>&2 2>&3)
                       					 if [ "$input" != "$input_chk" ]; then
                          				      whiptail --title "Test Message Box" --msgbox "Passwords do not match, please try again." 10 60
                         				 fi
             				        done
        					echo -e "$input\n$input\n" | passwd "$user" &> /dev/null' > /mnt/root/set.sh
		chmod +x "$ARCH"/root/set.sh
		arch-chroot "$ARCH" ./root/set.sh
		rm "$ARCH"/root/set.sh
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
				arch-chroot "$ARCH" systemctl enable dhcpcd.service &> /dev/null
				clear
			fi
			clear
		#Wireless tools
			if (whiptail --title "Arch Linux Installer" --yesno "Install wireless tools and WPA supplicant? \n *Necessary for wifi*" 10 60) then
				pacstrap "$ARCH" wireless_tools wpa_supplicant &> /dev/null &
				pid=$! pri=0.5 msg="Installing wireless tools and WPA supplicant..." load
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
		if (whiptail --title "Arch Linux Installer" --yesno "Install GRUB onto /dev/$DRIVE? \n *Required to make bootable" 10 60) then
			if (whiptail --title "Arch Linux Installer" --yesno "Install os-prober first \n *Required for dualboot" 10 60) then
				pacstrap "$ARCH" os-prober &> /dev/null &
				pid=$! pri=0.5 msg="Installing os-prober..." load
			fi
			pacstrap "$ARCH" grub &> /dev/null &
			pid=$! pri=1 msg="Installing grub onto /dev/$DRIVE" load
			if [ "$crypted" == "true" ]; then
				sed -i 's!quiet!cryptdevice=/dev/lvm/lvroot:root root=/dev/mapper/root!' "$ARCH"/etc/default/grub
				echo "/dev/$BOOT                    /boot           ext4           defaults        0       2" > "$ARCH"/etc/fstab
				echo "/dev/mapper/root        /                      ext4            defaults       0       1" >> "$ARCH"/etc/fstab
				echo "/dev/mapper/tmp       /tmp             tmpfs        defaults        0       0" >> "$ARCH"/etc/fstab
				echo "tmp	       /dev/lvm/tmp	       /dev/urandom	tmp,cipher=aes-xts-plain64,size=256" >> "$ARCH"/etc/crypttab
				if "$SWAP" ; then
					echo "/dev/mapper/swap     none            swap          sw                    0       0" >> "$ARCH"/etc/fstab
					echo "swap	/dev/lvm/swap	/dev/urandom	swap,cipher=aes-xts-plain64,size=256" >> "$ARCH"/etc/crypttab
				fi
			fi
			arch-chroot "$ARCH" grub-install --recheck /dev/"$DRIVE" &> /dev/null &
			pid=$! pri=0.5 msg="Installing grub..." load
			loader_installed=true
			arch-chroot "$ARCH" grub-mkconfig -o /boot/grub/grub.cfg &> /dev/null &
			pid=$! pri=0.5 msg="Configuring grub..." load
			graphics
		else
			if (whiptail --title "Arch Linux Installer" --defaultno --yesno "WARNING! Are you sure you don't want a bootloader? Your system will not boot!" 10 60) then
				main_menu
			else
				install_bootloader
			fi
		fi
	else
		whiptail --title "Test Message Box" --msgbox "Error no root filesystem installed at $ARCH \n Continuing to menu." 10 60
		main_menu
	fi
	main_menu
}

graphics() {
	if [[ "$INSTALLED" == "true" && "$loader_installed" == "true" ]]; then
		if [ "$x" != "true" ]; then
			if (whiptail --title "Arch Linux Installer" --yesno "Would you like to install xorg-server now? \n *Select yes for a graphical interface" 10 60) then
				pacstrap "$ARCH" xorg-server xorg-server-utils xorg-xinit xterm &> /dev/null &
				pid=$! pri="$down" msg="Please wait while installing xorg-server..." load
				x=true
				until [ "$GPU" == "set" ]
					do
						GPU=$(whiptail --title "Arch Linux Installer" --menu "Select your GPU" 15 60 5 \
						"Default" "Mesa Graphics" \
						"AMD"     "AMD/ATI Graphics" \
						"Intel"   "Intel Graphics" \
						"Nvidia"  "NVIDIA Graphics" \
						"VBOX"    "VirtualBox Guest" 3>&1 1>&2 2>&3)
						if [ "$?" -gt "0" ]; then
							if (whiptail --title "Arch Linux Installer" --yesno "Continue without installing graphics drivers? \n Default mesa drivers will be used" 10 60) then
								GPU=set
							fi
						fi
						case "$GPU" in
							"Default")
								GPU=set
							;;
							"AMD")
								DRIV=$(whiptail --title "Arch Linux Installer" --menu "Select your desired AMD driver \n Cancel if none" 15 60 4 \
								"xf86-video-ati"   "Open source AMD driver" 3>&1 1>&2 2>&3)
								if [ "$?" -eq "0" ]; then
									if [ "$multilib" == "true" ]; then
										query="xf86-video-ati lib32-mesa-libgl"
									else
										query="xf86-video-ati"
									fi
									if (whiptail --title "Arch Linux Installer" --yesno "Enable openGL support? \n Used for games and other graphics" 10 60) then
										query="$query mesa-libgl"
									fi
									GPU=set
								fi
							;;
							"Intel")
								DRIV=$(whiptail --title "Arch Linux Installer" --menu "Select your desired Intel driver \n Cancel if none" 15 60 4 \
								"xf86-video-intel"     "Open source Intel driver" 3>&1 1>&2 2>&3)
								if [ "$?" -eq "0" ]; then
									if [ "$multilib" == "true" ]; then
										query="xf86-video-intel lib32-mesa-libgl"
									else
										query="xf86-video-intel"
									fi
									if (whiptail --title "Arch Linux Installer" --yesno "Enable openGL support? \n Used for games and other graphics" 10 60) then
										query="$query mesa-libgl"
									fi
									GPU=set
								fi
							;;
							"Nvidia")
								DRIV=$(whiptail --title "Arch Linux Installer" --menu "Select your desired Intel driver \n Cancel if none" 15 60 4 \
								"nvidia"       "Latest stable nvidia" \
								"nvidia-340xx" "Legacy 340xx branch" \
								"nvidia-304xx" "Legaxy 304xx branch" 3>&1 1>&2 2>&3)
								if [ "$?" -eq "0" ]; then
									if [ "$multilib" == "true" ]; then
										query="$DRIV $DRIV-libgl lib32-$DRIV-libgl $DRIV-utils lib32-$DRIV-utils"
									else
										query="$DRIV $DRIV-libgl $DRIV-utils"
									fi
									GPU=set
								fi
							;;
							"VBOX")
								DRIV=$(whiptail --title "Arch Linux Installer" --menu "Provides graphics and features for virtualbox guests:" 15 60 4 \
								"virtualbox-guest-additions" "-" 3>&1 1>&2 2>&3)
								if [ "$?" -eq "0" ]; then
									query="virtualbox-guest-utils"
									echo -e "vboxguest\nvboxsf\nvboxvideo" > /etc/modules-load.d/vbox.conf
									GPU=set
								fi
							;;
						esac
					done
				if [ -n "$query" ]; then
					pacstrap "$ARCH" ${query} &> /dev/null &
					pid=$! pri=1 msg="Please wait while installing graphics drivers..." load
				fi
			fi
		fi
		if [ "$x" == "true" ]; then
			if (whiptail --title "Arch Linux Installer" --yesno "Would you like to install a desktop enviornment or window manager?" 10 60) then
				DE=$(whiptail --title  "Arch Linux Installer" --menu "Select your desired enviornment:" 15 60 6 \
				"xfce4"    "Light  DE" \
				"i3"       "Tiling WM" \
				"mate"     "Light DE" \
				"lxde"     "Light DE" \
				"gnome"    "Modern DE" \
				"cinnamon" "Eligant DE" \
				"openbox"  "Stacking WM" \
				"fluxbox"  "Light WM" \
				"awesome"  "Awesome WM" \
				"dwm"      "Dynamic WM" 3>&1 1>&2 2>&3)
				if [ "$?" -gt "0" ]; then
					if (whiptail --title "Arch Linux Installer" --yesno "Are you sure you sure you dont want a desktop? \nYou will be booted into a command line" 10 60) then
						install_software
					fi
				fi
				case "$DE" in
					"xfce4") start_term="exec startxfce4"
						if (whiptail --title "Arch Linux Installer" --yesno "Install xfce4 goodies?" 10 60) then
							envr="xfce4 xfce4-goodies"
						else
							envr="xfce4"
						fi
						if (whiptail --title "Arch Linux Installer" --yesno "Install SLiM display manager?" 10 60) then
							envr="$envr slim archlinux-themes-slim"
							DM="slim.service"
							if [ "$user_added" == "true" ]; then
								echo "exec xfce4-session" > "$ARCH"/home/"$user"/.xinitrc
							else
								echo "exec xfce4-session" > "$ARCH"/root/.xinitrc
							fi
						fi
					;;
					"cinnamon") envr="cinnamon slim archlinux-themes-slim" DM="slim.service"
						if [ "$user_added" == "true" ]; then
							echo "exec gnome-session-cinnamon" > "$ARCH"/home/"$user"/.xinitrc
						else
							echo "exec gnome-session-cinnamon" > "$ARCH"/root/.xinitrc
						fi
					;;
					"gnome")
						if (whiptail --title "Arch Linux Installer" --yesno "Install gnome extras?" 10 60) then
							envr="gnome gnome-extra"
							extra_down=true post_down="$down" down=$((down+4))
						else
							envr="gnome"
						fi
						DM="gdm.service"
					;;
					"mate") start_term="exec mate-session"
						if (whiptail --title "Arch Linux Installer" --yesno "Install mate extras?" 10 60) then
							envr="mate mate-extra"
						else
							envr="mate"
						fi
						if (whiptail --title "Arch Linux Installer" --yesno "Install SLiM display manager?" 10 60) then
							envr="$envr slim archlinux-themes-slim"
							DM="slim.service"
							if [ "$user_added" == "true" ]; then
								echo "$start_term" > "$ARCH"/home/"$user"/.xinitrc
							else
								echo "$start_term" > "$ARCH"/root/.xinitrc
							fi
						fi
					;;
					"lxde")
						envr="lxde"
						if (whiptail --title "Arch Linux Installer" --yesno "Install SLiM display manager?" 10 60) then
							envr="$envr slim archlinux-themes-slim"
							DM="slim.service"
							if [ "$user_added" == "true" ]; then
								echo "exec lxsession" > "$ARCH"/home/"$user"/.xinitrc
							else
								echo "exec lxsession" > "$ARCH"/root/.xinitrc
							fi
						else
							start_term="exec startlxde"
						fi
					;;
					"openbox") envr="openbox" start_term="exec openbox-session"
						if (whiptail --title "Arch Linux Installer" --yesno "Install SLiM display manager?" 10 60) then
							envr="$envr slim archlinux-themes-slim"
							DM="slim.service"
							if [ "$user_added" == "true" ]; then
								echo "$start_term" > "$ARCH"/home/"$user"/.xinitrc
							else
								echo "$start_term" > "$ARCH"/root/.xinitrc
							fi
						fi
						
					;;
					"fluxbox") envr="fluxbox" start_term="exec startfluxbox"
						if (whiptail --title "Arch Linux Installer" --yesno "Install SLiM display manager?" 10 60) then
							envr="$envr slim archlinux-themes-slim"
							DM="slim.service"
							if [ "$user_added" == "true" ]; then
								echo "$start_term" > "$ARCH"/home/"$user"/.xinitrc
							else
								echo "$start_term" > "$ARCH"/root/.xinitrc
							fi
						fi
						
					;;

					"awesome") envr="awesome" start_term="exec awesome" ;;
					"dwm") envr="dwm" start_term="exec dwm" ;;
					"i3") envr="i3" start_term="exec i3" ;;
				esac
				if [ -n "$envr" ]; then
					pacstrap "$ARCH" ${envr} &> /dev/null &
					pid=$! pri="$down" msg="Please wait while installing desktop... \n *This may take awhile" load
					if [ "$extra_down" == "true" ]; then
						down="$post_down"
					fi
					if [ -n "$DM" ]; then
						arch-chroot "$ARCH" systemctl enable "$DM"
						sed -i 's/current_theme       default/current_theme       archlinux-simplyblack/' "$ARCH"/etc/slim.conf
					elif [ -n "$start_term" ]; then
						echo "$start_term" > "$ARCH"/home/"$user"/.xinitrc
						whiptail --title "Test Message Box" --msgbox "$DE installed successfully \nOn login use the command 'startx'" 10 60
					fi
				fi
			else
				if (whiptail --title "Arch Linux Installer" --yesno "Are you sure you sure you dont want a desktop? \nYou will be booted into a command line" 10 60) then				
					install_software
				else
					graphics
				fi
			fi
		fi
		install_software
	else
		whiptail --title "Test Message Box" --msgbox "Error no root filesystem installed at $ARCH \n Continuing to menu." 10 60
		main_menu
	fi
}

install_software() {
	if [[ "$INSTALLED" == "true" && "$loader_installed" == "true" ]]; then
		if (whiptail --title "Arch Linux Installer" --yesno "Would you like to install some common software?" 10 60) then
			software=$(whiptail --title "Test Checklist Dialog" --checklist "Choose your desired software \nUse spacebar to check/uncheck \npress enter when finished" 20 60 10 \
						"openssh" "Secure Shell Deamon" ON \
						"vim" 	  	  "Popular Text Editor" ON \
						"zsh"     	  "The Z shell" ON \
						"wget"        "CLI web downloader" ON \
						"tmux"    	  "Terminal multiplxer" OFF \
						"screen"  	  "GNU Screen" OFF \
						"netctl"	  "CLI Wireless Controls " OFF \
						"htop"        "CLI process Info" OFF \
						"mplayer"     "Media Player" OFF \
						"screenfetch" "Display System Info" OFF \
						"gparted"     "GNU Parted GUI" OFF \
						"gimp"        "GNU Image Manipulation " OFF \
						"firefox"     "Graphical Web Browser" OFF \
						"chromium"    "Graphical Web Browser" OFF \
						"libreoffice" "Open source word processing " OFF \
						"vlc"         "GUI media player" OFF \
						"virtualbox"  "Desktop virtuialization" OFF \
						"lynx"        "Terminal Web Browser" OFF \
						"ufw"         "Uncomplicated Firewall" OFF \
						"apache"  	  "Web Server" OFF 3>&1 1>&2 2>&3)
			download=$(echo "$software" | sed 's/\"//g')
			if [ "$?" -eq "0" ]; then
    			pacstrap "$ARCH" ${download} &> /dev/null &
    			pid=$! pri=1 msg="Please wait while installing software..." load
			fi
		fi
	else
		whiptail --title "Test Message Box" --msgbox "Error no root filesystem installed at $ARCH \n Continuing to menu." 10 60
		main_menu
	fi
	clear
	reboot_system
}

reboot_system() {
	if [[ "$INSTALLED" == "true" && "$loader_installed" == "true" ]]; then	
		if (whiptail --title "Arch Linux Installer" --yesno "Install process complete! Reboot now?" 10 60) then
			umount -R $ARCH
			reboot
		else
			if (whiptail --title "Arch Linux Installer" --yesno "System fully installed \nWould you like to unmount?" 10 60) then
				umount -R "$ARCH"
				exit
			else
				exit
			fi
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

load() {
	{       int="1"
                while (true)
    	            do
    	                proc=$(ps | grep "$pid")
    	                if [ "$?" -gt "0" ]; then break; fi
    	                sleep $pri
    	                echo $int
    	                int=$((int+1))
    	            done
                echo 100
                sleep 1
                } | whiptail --title "Arch Linux Installer" --gauge "$msg" 8 78 0
}

main_menu() {
	menu_item=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Menu Items:" 15 60 5 \
		"Set Locale"            "-" \
		"Set Timezone"          "-" \
		"Set Keymap"            "-" \
		"Partition Drive"       "-" \
		"Update Mirrors"        "-" \
		"Install Base System"   "-" \
		"Configure System"      "-" \
		"Set Hostname"          "-" \
		"Add User"              "-" \
		"Configure Network"     "-" \
		"Install Bootloader"    "-" \
		"Install Graphics"      "-"
		"Install Software"      "-" \
		"Reboot System"         "-" \
		"Exit Installer"        "-" 3>&1 1>&2 2>&3)
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
				configure_system
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
		"Install Graphics") graphics
		;;
		"Install Software") install_software
		;;
		"Reboot System") reboot_system
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
check_connection
