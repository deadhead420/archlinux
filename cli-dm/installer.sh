#!/bin/bash
root_account() {
if [ "$UID" -eq "0" ]; then
	wget https://raw.githubusercontent.com/deadhead420/archlinux/master/cli-dm/cli-dm.sh -O /usr/bin/cli-dm # wget cli-dm script straight from github repo
	chmod +x /usr/bin/cli-dm # make executeable
	echo "Cli-Dm sucessfully installed!"
	echo "At login run 'cli-dm' to select your desktop"
else user_account
fi
}

user_account() {
if [ -e "/usr/bin/sudo" ]; then # check if sudo is installed
	sudo wget https://raw.githubusercontent.com/deadhead420/archlinux/master/cli-dm/cli-dm.sh -O /usr/bin/cli-dm # wget cli-dm script straight from github repo
	sudo chmod +x /usr/bin/cli-dm # make executeable
	echo "Cli-Dm sucessfully installed!"
	echo "At login run 'cli-dm' to select your desktop"
else
	echo
	echo "*sudo not detected* it is recommended to use sudo for administration from a user account."
	echo
	echo "To install cli-dm please provide the root password"
	su -c 'wget -O - https://raw.githubusercontent.com/deadhead420/archlinux/master/cli-dm/installer.sh | sh'
fi
}
root_account
