#!/bin/bash
### The intention of this script is a fast arch install with efi boot
### The install is 100% automatic with no user input
### Simply run the script and wait for it to prompt for reboot
### NOTE: Only run in virtualbox, this script expects to install to /dev/sda and will format the drive
### Enjoy!

# Format
sgdisk --zap-all /dev/sda
wipefs -a /dev/sda

# Partition
# Creates a new partition size of "512MB" sets type to "ef00" (efi system partition)
# Creates a 2nd part using the remaining space.
# Write and confirm writ with "y"
# What im doing here is echoing commands into gdisk "\n" is newline and the same as hitting return in gdisk (or fdisk)
echo -e "n\n\n\n512M\nef00\nn\n\n\n\n\nw\ny" | gdisk /dev/sda

# Create filesystems
# Note the esp must be vfat
mkfs.vfat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount filesystems
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

pacstrap /mnt base base-devel grub efibootmgr # Install base system 

arch-chroot /mnt grub-install --efi-directory=/boot --target=x86_64-efi --bootloader-id=boot 	# Install grub in efi mode
mv /mnt/boot/EFI/boot/grubx64.efi /mnt/boot/EFI/boot/bootx64.efi 				# Rename efi file (this is needed for vritualbox)
arch-chroot /mnt mkinitcpio -p linux 								# Reconfigure kernel (Not sure if this is necessary)
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg						# Configure grub

genfstab -U -p /mnt >> /mnt/etc/fstab		# Generate fstab
cp /etc/locale.gen /mnt/etc/ 			# Copy over locale gen file
arch-chroot /mnt locale-gen			# Generate locale on new system
printf "arch\narch" | arch-chroot /mnt passwd	# Set root password default as "arch"
echo -e "\nDefault root password set to: arch\n"

# Prompt user for reboot
echo -n "Install complete, reboot now? [y/n]: "
read input
if [ "$input" == "y" ]; then
	umount -R /mnt
	reboot
else
	echo -e "\nExiting, note system is still mounted at /mnt\n"
fi
