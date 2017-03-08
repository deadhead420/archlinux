#!/bin/bash

main() {

	Cyan=$'\e[0;36m';
	Magenta=$'\e[0;35m';
	Blue=$'\e[0;34m';
	Yellow=$'\e[0;33m';
	Green=$'\e[0;32m';
	Red=$'\e[0;31m';
	ColorOff=$'\e[0m';
	clear
	local char=
    local input=
    local -a history=( )
    local -i histindex=0
	trap ctrl_c INT
	dir=$(pwd | sed "s|/home/$USER|~|")
	
	while (true)
	  do
		echo -n "${Yellow}<${Red}$(whoami)${Yellow}@${Green}$(</etc/hostname)${Yellow}>: ${dir}>${Red}# ${ColorOff}" ; while IFS= read -r -n 1 -s char
		  do
			if [ "$char" == $'\x1b' ]; then
				while IFS= read -r -n 2 -s rest
          		  do
                	char+="$rest"
                	break
            	done
        	fi

			if [ "$char" == $'\x1b[D' ]; then
				pos=-1

			elif [ "$char" == $'\x1b[C' ]; then
				pos=1

			elif [[ $char == $'\177' ]];  then
				input="${input%?}"
				syntax
			
			elif [ "$char" == $'\x1b[A' ]; then
            # Up
            	if [ $histindex -gt 0 ]; then
                	histindex+=-1
                	input=$(echo -ne "${history[$histindex]}")
					echo -ne "\r\033[K${Yellow}<${Red}$(whoami)${Yellow}@${Green}$(</etc/hostname)${Yellow}>: ${dir}>${Red}# ${ColorOff}${history[$histindex]}"
				fi  
        	elif [ "$char" == $'\x1b[B' ]; then
            # Down
            	if [ $histindex -lt $((${#history[@]} - 1)) ]; then
                	histindex+=1
                	input=$(echo -ne "${history[$histindex]}")
                	echo -ne "\r\033[K${Yellow}<${Red}$(whoami)${Yellow}@${Green}$(</etc/hostname)${Yellow}>: ${dir}>${Red}# ${ColorOff}${history[$histindex]}"
				fi  
        	elif [ -z "$char" ]; then
            # Newline
				echo
            	history+=( "$input" )
            	histindex=${#history[@]}
				break
        	else
            	echo -n "$char"
            	input+="$char"
            	syntax
        	fi  
		done
    	
		if [ "$input" == "exit" ]; then
			break
#		elif (<<<$input grep "^cd") then
			
		else
#	    	alias command="$input"
	    	$input ; dir=$(pwd | sed "s|/home/$USER|~|")
	    fi   
		input=
	done

}

syntax() {
	
	if ("$input" &> /dev/null) then
		echo -ne "\r\033[K${Yellow}<${Red}$(whoami)${Yellow}@${Green}$(</etc/hostname)${Yellow}>: ${dir}>${Red}# ${Green}${input}${ColorOff}"
    else
        echo -ne "\r\033[K${Yellow}<${Red}$(whoami)${Yellow}@${Green}$(</etc/hostname)${Yellow}>: ${dir}>${Red}# ${Red}${input}${ColorOff}"
    fi

}

ctrl_c() {

	echo
	echo "${Red} Exiting and cleaning up..."
	sleep 0.5
	unset input
	rm /tmp/chroot_dir.var &> /dev/null
	clear
	reboot_system

}

main
