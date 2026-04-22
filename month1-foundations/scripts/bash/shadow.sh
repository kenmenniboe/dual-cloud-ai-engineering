#!/bin/bash

if [ -a "/ect/shadow" ]; then
	echo "File exists. Shadow passwords are enabled."
elif [ -w "/etc/shadow" ]; then
	echo "I have permissions to edit /etc/shadow."
else
	echo "File does not exists, or I do not have permissions to edit."
fi

