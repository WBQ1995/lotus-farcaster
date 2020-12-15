#!/bin/bash
#@author: s0nik42
#Copyright (c) 2020 Julien NOEL (s0nik42)
#
#MIT License
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

IUSER="$1"
PROMETHEUS_NODE_EXPORTER_FOLDER="/var/lib/prometheus/node-exporter/" # DEFAULT UBUNTU LOCATION
EXEC_PATH="$(dirname $0)"

if [ "$(id -u)" -ne 0 ]
then
	echo "ERROR: must be run as root"
elif [ -z "$IUSER" ]
then
	echo "Usage: $0 LOTUS_USER_USERNAME"
elif [ ! "$(id $IUSER)" ]
then
	echo "ERROR: user $IUSER doesn't exist"
elif [ ! -f "$(getent passwd $IUSER | cut -d: -f6)/.lotus/config.toml" ]
then
	echo "ERROR: user $IUSER doesn't seems to be a lotus user $(getent passwd $IUSER | cut -d: -f6)/.lotus/config.toml doesn't exist"
else
    echo 
	echo "Installing required debian packages : "
	echo "------------------------------------- "
	apt install python3-toml prometheus-node-exporter

    echo 
    echo "Check :"
	echo "------- "
    echo -n "prometheus-node-exporter : " 
    r=$(curl -s -o - http://localhost:9100/metrics |wc -l 2>/dev/null)
    if [ "$r" -gt 0 ]
    then
        echo "[ OK ] : properly installed"
    else
        echo "[ KO ] : Error cannot connect to prometheus-node-exporter"
    fi

	echo -e "\nFinishing installation : "
	echo      "------------------------ "
	set -x
	cp "$EXEC_PATH/lotus-exporter-farcaster.py" "/usr/local/bin"
	chown "$IUSER" "$EXEC_PATH/lotus-exporter-farcaster.py"
	chmod +x "$EXEC_PATH/lotus-exporter-farcaster.py"
	chmod g+r "$PROMETHEUS_NODE_EXPORTER_FOLDER"
	chmod g+w "$PROMETHEUS_NODE_EXPORTER_FOLDER"
	chgrp "$IUSER" "$PROMETHEUS_NODE_EXPORTER_FOLDER"
	cat "$EXEC_PATH/lotus-exporter-farcaster.cron" |sed "s/LOTUS_USER/$IUSER/" > "/etc/cron.d/lotus-exporter-farcaster"
	set +x
	cat << EOF 

FARCASTER INSTALLATION COMPLETED

********************************************************************************

TESTING : run the check.sh script : $EXEC_PATH/check.sh LOTUS_USER_USERNAME

NEXT STEPS : 
  - Add this node to your prometheus server
  - Add the farecaster dashboard to grafana (import through ui)

********************************************************************************
EOF
	exit 0
fi
exit 1
