#!/bin/bash
root_account() {
if [ "$UID" -eq "0" ]; then
	wget https://raw.githubusercontent.com/deadhead420/archlinux/master/wiki/wiki.sh -O /usr/bin/arch-wiki # wget wiki script straight from github repo
	chmod +x /usr/bin/arch-wiki # make executeable
	echo "arch-wiki sucessfully installed!"
	arch-wiki --help # show info
else user_account
fi
}

user_account() {
if [ -e "/usr/bin/sudo" ]; then # check if sudo is installed
	sudo wget https://raw.githubusercontent.com/deadhead420/archlinux/master/wiki/wiki.sh -O /usr/bin/arch-wiki # wget wiki script straight from github repo
	sudo chmod +x /usr/bin/arch-wiki # make executeable
	echo "arch-wiki sucessfully installed!"
	arch-wiki --help # show info
else
	echo
	echo "*sudo not detected* it is recommended to use sudo for administration from a user account."
	echo
	echo "To install arch-wiki-cli please provide the root password"
	su -c 'wget -O - https://raw.githubusercontent.com/deadhead420/archlinux/master/wiki/installer.sh | sh'
fi
}
root_account
