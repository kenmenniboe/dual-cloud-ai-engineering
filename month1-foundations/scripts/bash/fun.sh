#!/bin/bash

#fun="Shell Scripting is Fun!"

#echo "Shell Scripting is Fun!"

#echo "At this point I can't wait to tell everyone that $fun"


store_cmd=$(hostname)

sys_cmd=$(lsb_release -d)

echo "This script is running on $sys_cmd. Where $store_cmd is the output of the hostname command."



