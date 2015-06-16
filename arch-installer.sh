#!/bin/bash

ARCH=/mnt
INSTALLED=false
echo -e '\e[44m'

set_locale() {
	LOCALE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Please select your locale" 15 60 5 \
	"en_US.UTF-8" ">" \
	"en_AU.UTF-8" ">" \
	"en_CA.UTF-8" ">" \
	"en_GB.UTF-8" ">" \
	"Other"       ">"		 3>&1 1>&2 2>&3)

	if [ "$LOCALE" = "Other" ]; then
		localelist="$(cat /etc/locale.gen | awk '{print substr ($1,2) " " ($2);}' | sed 's/^/"/' | sed 's/$/"/' | sed 's/$/ >/')"
		LOCALE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Please enter your desired locale:" 15 60 5 $localelist 3>&1 1>&2 2>&3)
	fi
	clear
}

set_zone() {
	zonelist="$(ls /usr/share/zoneinfo/ | grep -v "CET\|CST6CDT\|Cuba\|EET\|Egypt\|Eire\|EST\|EST5EDT\|Factory\|GB\|GB-Eire\|GMT\|GMT0\|GMT-0\|GMT+0\|Greenwich\|Hongkong\|HST\|Iceland\|Iran\|iso3166.tab\|Israel\|Jamaica\|Japan\|Kwajalein\|Libya\|MET\|MST\|MST7MDT\|Navajo\|NZ\|NZ-CHAT\|Poland\|Portugal\|Posixrules\|PRC\|PST8PDT\|ROC\|ROK\|Singapore\|Turkey\|UTC\|Universal\|UCT\|WET\|W-SU\|zone1970.tab\|zone.tab\|Zulu\|posix\|right\|US" | sed 's/$/ >/')"
	ZONE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Please enter your time-zone:" 15 60 5 $zonelist 3>&1 1>&2 2>&3)
	if [ "$ZONE" = "America" ]; then
		ZONE=US
		sublist="$(ls /usr/share/zoneinfo/US/ | sed 's/$/ >/')"
		SUBZONE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Please enter your sub-zone:" 15 60 5 $sublist 3>&1 1>&2 2>&3)
	else
		sublist="$(ls /usr/share/zoneinfo/$ZONE | sed 's/$/ >/')"
		SUBZONE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Please enter your sub-zone:" 15 60 5 $sublist 3>&1 1>&2 2>&3)
	fi
}

set_keys() {
	keyboard=$(whiptail --nocancel --inputbox "Set key-map:" 10 40 "us" 3>&1 1>&2 2>&3)
	loadkeys $keyboard
}

prepare_drives() {

	
	drive="$(lsblk | grep "disk" | grep -v "rom" | awk '{print $1 "                          " $4}')"
	DRIVE=$(whiptail --nocancel --title "Arch Linux Installer" --menu "Select the drive to install arch onto:" 15 60 5 $drive 3>&1 1>&2 2>&3)
	if (whiptail --title "Arch Linux Installer" --yesno "WARNING! Will erase all data on /dev/$DRIVE Continue?" 10 60) then
		gdisk --zap-all "$DRIVE"
		SWAP=false
		if (whiptail --title "Arch Linux Installer" --yesno "Create SWAP space?" 15 60) then
			SWAP=true
			SWAPSPACE=$(whiptail --nocancel --inputbox "Specify desired swap size(Align to M or G):" 10 40 "512M" 3>&1 1>&2 2>&3)
		fi
	fi

	PART=$(whiptail --title "Arch Linux Installer" --menu "Manual Partitioning coming soon" 15 60 4 \
	"Auto Partition Drive"          ">" 3>&1 1>&2 2>&3)
#	"Manual Partition Drive"        ">" 3>&1 1>&2 2>&3)

	GPT=false
	if (whiptail --title "Arch Linux Installer" --defaultno --yesno "Would you like to use GPT partitioning?" 15 60) then
		GPT=true
	fi

	case "$PART" in
		"Auto Partition Drive")
			if "$GPT" ; then
				if "$SWAP" ; then
					echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n4\n\n+$SWAPSPACE\n8200\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE"
					BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
					SWAP="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==5) print substr ($1,3) }')"
					ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
					wipefs -a /dev/$BOOT
					mkfs.ext4 /dev/$BOOT
					wipefs -a /dev/$ROOT
					mkfs.ext4 /dev/$ROOT
					wipefs -a /dev/$SWAP
					mkswap /dev/$SWAP
					swapon /dev/$SWAP
					mount /dev/$ROOT $ARCH
					mkdir $ARCH/boot
					mount /dev/$BOOT $ARCH/boot
				else
					echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE"
					BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
					ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
					wipefs -a /dev/$BOOT
					mkfs.ext4 /dev/$BOOT
					wipefs -a /dev/$ROOT
					mkfs.ext4 /dev/$ROOT
					mount /dev/$ROOT $ARCH
					mkdir $ARCH/boot
					mount /dev/$BOOT $ARCH/boot
				fi
			else
				if "$SWAP" ; then
					echo -e "o\nn\np\n1\n\n+100M\nn\np\n3\n\n+$SWAPSPACE\nt\n\n82\nn\np\n2\n\n\nw" | fdisk /dev/"$DRIVE" | grep "%" &
					BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
					ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"
					SWAP="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
					wipefs -a -q /dev/"$BOOT"
					mkfs.ext4 -q /dev/"$BOOT"
					wipefs -a -q /dev/"$ROOT"
					mkfs.ext4 -q /dev/"$ROOT"
			                wipefs -a -q /dev/"$SWAP"
					mkswap /dev/"$SWAP"
					swapon /dev/"$SWAP"
		                        mount /dev/"$ROOT" "$ARCH"
					mkdir "$ARCH"/boot		
					mount /dev/"$BOOT" "$ARCH"/boot			
				else
					echo -e "o\nn\np\n1\n\n+100M\nn\np\n2\n\n\nw" | fdisk /dev/$DRIVE  | grep "%" &
					BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
					ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"
					wipefs -a /dev/"$BOOT"
					mkfs.ext4 -q /dev/"$BOOT"
					wipefs -a /dev/"$ROOT"
					mkfs.ext4 -q /dev/"$ROOT"
					mount /dev/"$ROOT" "$ARCH"
					mkdir "$ARCH"/boot
					mount /dev/"$BOOT" "$ARCH"/boot
				fi
	 		fi
		;;
	esac
}

fdisk_load() {

	{       i="0"
			while (true)
	   		do
			proc=$(ps aux | grep -v grep | grep -e "fdisk")
				if [[ "$proc" == "" ]]; then break; fi
				    sleep 0
				    echo $i
				    i=$(expr $i + 1)
			done
			echo 100
			sleep 1
	} | whiptail --title "Arch Linux Installer" --gauge "Partitioning Drive" 8 78 0
}

mkfs_load() {
    {       i="0"
            while (true)
            do
            proc=$(ps aux | grep -v grep | grep -e "mkfs")
              if [[ "$proc" == "" ]]; then break; fi
                 sleep 0.5
                 echo $i
                 i=$(expr $i + 1)
         done
           echo 100
            sleep 1
    } | whiptail --title "Arch Linux Installer" --gauge "Please wait while creating file system(s)..." 8 78 0
}

update_mirrors() {
	if (whiptail --title "Arch Linux Installer" --yesno "Would you like to update your mirrorlist now?" 10 60) then
		wget -O mirrorlist "https://www.archlinux.org/mirrorlist/?country=US&protocol=http"
  		sed 's/#//' mirrorlist > /etc/pacman.d/mirrorlist
	fi
	clear
}

install_base() {
	if [ -n "$ROOT" ]; then
		INSTALLED=false	
			if (whiptail --title "Arch Linux Installer" --yesno "Begin installing base system onto /dev/$DRIVE?" 10 60) then
				pacstrap "$ARCH" base base-devel dialog
				genfstab -U -p "$ARCH" >> "$ARCH"/etc/fstab
				INSTALLED=true
				if `cat /proc/cpuinfo | grep vendor_id | grep -iq intel` ; then
					pacstrap $ARCH intel-ucode
				fi
			clear
		fi
	fi
}

configure_system() {
	sed -i -e "s/#$LOCALE/$LOCALE/" $ARCH/etc/locale.gen
	echo LANG=$LOCALE > $ARCH/etc/locale.conf
	arch-chroot "$ARCH" /bin/bash -c "export LANG=$LOCALE"
        arch-chroot "$ARCH" /bin/bash -c "locale-gen"
	arch-chroot "$ARCH" /bin/bash -c "ln -s /usr/share/zoneinfo/$ZONE/$SUBZONE /etc/localtime"
	clear
}

set_hostname() {
	hostname=$(whiptail --nocancel --inputbox "Set hostname:" 10 40 "arch" 3>&1 1>&2 2>&3)
	echo $hostname > $ARCH/etc/hostname
#Set ROOT password
	echo "<####################################################>"
	echo "Please enter the root password: "
	arch-chroot "$ARCH" /bin/bash -c "passwd"
	clear
}

add_user() {
	if (whiptail --title "Arch Linux Installer" --yesno "Create a new sudo user now?" 10 60) then
		usrname=$(whiptail --nocancel --inputbox "Set username:" 10 40 "$new_user" 3>&1 1>&2 2>&3)
		arch-chroot "$ARCH" /bin/bash -c "useradd -m -g users -G wheel,audio,network,power,storage,optical -s /bin/bash $usrname"
#Set SUDO password
	echo "<####################################################>"
	echo "Please enter the sudo password for $usrname: "
	arch-chroot "$ARCH" /bin/bash -c "passwd $usrname"
	fi
	clear
	if (whiptail --title "Arch Linux Installer" --yesno "Enable sudo privelege for members of wheel?" 10 60) then
		sed -i '/%wheel ALL=(ALL) ALL/s/^#//' $ARCH/etc/sudoers
	fi
}

configure_network() {

#Enable DHCP
	if (whiptail --title "Arch Linux Installer" --yesno "Enable DHCP at boot?" 10 60) then
		arch-chroot "$ARCH" /bin/bash -c "systemctl enable dhcpcd.service"
	fi
	clear
#Enable SSH
	if (whiptail --title "Arch Linux Installer" --yesno "Enable SSH at boot?" 10 60) then
		pacstrap $ARCH openssh
		arch-chroot "$ARCH" /bin/bash -c "systemctl enable sshd.service"
	fi
	clear
}

enable_multilib() {
	if (whiptail --title "Arch Linux Installer" --yesno "Would you like to add multilib repo to pacman.conf?" 10 60) then
		echo "[multilib]" >> /mnt/etc/pacman.conf
		echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
	fi
#AUR
#	if (whiptail --title "Arch Linux Installer" --yesno "Would you like to add the AUR FR repos to pacman.conf?" 10 60) then
#		arch=$arch
#		echo "" >> /mnt/etc/pacman.conf
#		echo "[archlinuxfr]" >> /mnt/etc/pacman.conf
#		echo "Server = http://repo.archlinux.fr/$(arch)" >> /mnt/etc/pacman.conf
#		echo "SigLevel = Never" >> /mnt/etc/pacman.conf
#	fi
	arch-chroot "$ARCH" /bin/bash -c "pacman -Syyy"
	clear
}

install_bootloader() {
	if (whiptail --title "Arch Linux Installer" --yesno "Install GRUB onto /dev/$DRIVE?" 10 60) then
		pacstrap $ARCH grub-bios
		arch-chroot "$ARCH" /bin/bash -c "grub-install --recheck /dev/$DRIVE"
		arch-chroot "$ARCH" /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
		clear
	fi
}

reboot_system() {
	if (whiptail --title "Arch Linux Installer" --yesno "Install process complete! Reboot now?" 10 60) then
		umount -R $ARCH/boot
		umount -R $ARCH
		reboot
	else
		exit
	fi
}

set_locale
set_zone
set_keys
prepare_drives
update_mirrors
install_base
configure_system
set_hostname
add_user
configure_network
enable_multilib
install_bootloader
reboot_system