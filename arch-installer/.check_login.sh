#!/bin/bash
sleep 1
until [ "$USER" == "root" ]
	do
		sleep 0.5
	done
./.start_script.sh
