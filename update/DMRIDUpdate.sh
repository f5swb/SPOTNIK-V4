#!/bin/bash

###############################################################################
#
# DMRIDUpdate.sh
#
# Copyright (C) 2016 by Tony Corbett G0WFV
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
###############################################################################
#
# On a Linux based system, such as a Raspberry Pi, this script will perform all
# the steps required to maintain the DMRIds.dat (or similar) file for you.
#
# It is designed to run from crontab and will download the latest IDs from the
# master DMR-MARC ID database and optionally keep a backup of previously
# created files for you.
#
# It will also prune the number of backup files according to a value specified
# by you in the configuration below.
#
# When done, it will restart MMDVMHost to make the ID changes take effect.
#
# To install in root's crontab use the command ...
#
#     sudo crontab -e
#
# ... and add the following line to the bottom of the file ...
#
#     0  0  *  *  *  /path/to/script/DMRIDUpdate.sh 1>/dev/null 2>&1
#
# ... where /path/to/script/ should be replaced by the path to this script.
#
###############################################################################
#
#                              CONFIGURATION
#
# Full path to DMR ID file
DMRIDFILE=/var/lib/mmdvm/DMRIds.dat
#
# How many DMR ID files do you want backed up (0 = do not keep backups)
DMRFILEBACKUP=1
#
# Command line to restart MMDVMHost
# RESTARTCOMMAND="systemctl restart mmdvmhost.service"
# RESTARTCOMMAND2="killall YSF2DMR ; /opt/YSF2DMR/YSF2DMR"

###############################################################################
#
# Do not edit below here
#
###############################################################################

# Check we are root
if [ "$(id -u)" != "0" ]
then
        echo "This script must be run as root" 1>&2
        exit 1
fi

# Create backup of old file
if [ -f ${DMRIDFILE} ]
then

	if [ ${DMRFILEBACKUP} -ne 0 ]
	then
	        cp ${DMRIDFILE} ${DMRIDFILE}.$(date +%d%m%y)
	fi

# Prune backups
	BACKUPCOUNT=$(ls ${DMRIDFILE}.* | wc -l)
	BACKUPSTODELETE=$(expr ${BACKUPCOUNT} - ${DMRFILEBACKUP})

	if [ ${BACKUPCOUNT} -gt ${DMRFILEBACKUP} ]
	then
        	for f in $(ls -tr ${DMRIDFILE}.* | head -${BACKUPSTODELETE})
        	do
                	rm $f
        	done
	fi
fi

# Generate new file
curl -s -N "https://www.radioid.net/api/dmr/user/?id=%" | jq -r '.results[] | [.id, .callsign, .fname] | @csv' | sed -e 's/"//g' | sed -e 's/,/ /g' > ${DMRIDFILE}

# Restart YSF2DMR & mmdmvhost
#eval ${RESTARTCOMMAND2}
#eval ${RESTARTCOMMAND}
