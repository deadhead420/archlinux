#!/bin/bash
md5="3d924b8e2a6e81610d2cc1de780df733  /usr/bin/arch-wiki"
root_account() {
if [ "$UID" -eq "0" ]; then
	wget https://raw.githubusercontent.com/deadhead420/archlinux/master/wiki/wiki.sh -O /usr/bin/arch-wiki # wget wiki script straight from github repo
	sum=$(md5sum /usr/bin/arch-wiki) # check md5sum
	if [ "$sum" == "$md5" ]; then # verify md5sum
		chmod +x /usr/bin/arch-wiki # make executeable
		echo "arch-wiki sucessfully installed!"
		arch-wiki --help # show info
	else
		rm /usr/bin/arch-wiki # remove script if check sum does not match
		echo "ERROR md5sum does not match!"
		echo "script removed from your system, please contact repo owner ($email)"
	fi
else user_account
fi
}

user_account() {
if [ -e "/usr/bin/sudo" ]; then # check if sudo is installed
	sudo wget https://raw.githubusercontent.com/deadhead420/archlinux/master/wiki/wiki.sh -O /usr/bin/arch-wiki # wget wiki script straight from github repo
	sum=$(md5sum /usr/bin/arch-wiki) # check md5sum
	if [ "$sum" == "$md5" ]; then # verify md5sum
		sudo chmod +x /usr/bin/arch-wiki # make executeable
		echo "arch-wiki sucessfully installed!"
		arch-wiki --help # show info
	else
		sudo rm /usr/bin/arch-wiki # remove script if check sum does not match
		echo "ERROR md5sum does not match!"
		echo "script removed from your system, please contact repo owner ($email)"
	fi

else
	echo
	echo "*sudo not detected* it is recommended to use sudo for administration from a user account."
	echo
	echo "To install arch-wiki-cli please provide the root password"
	su -c 'wget -O - https://raw.githubusercontent.com/deadhead420/archlinux/master/wiki/installer.sh | sh'
fi
}
root_account
