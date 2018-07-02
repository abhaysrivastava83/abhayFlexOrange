#!/bin/bash
#*******************************************************************************
#                       Discovery script (Inventory)
#*******************************************************************************
# Author(s) :
# ---------
#
# - Abhay Srivastava (OCB)
#
#
#*******************************************************************************
# Description :
# -----------
#
#  This discovery script will capture inventory from remote host & save data in csv file.
#
#  It follows those steps :
#
#   - First it capture username, password & IP from user input.
#
#   - Then it will logi into remote host and run all command which mention in command_to_execute file.
#
#
#*******************************************************************************
# History :
# -------
#
#  - 2018/05/25 - v0.1 - OCB - First released version.


#
#*******************************************************************************
# Exit codes :
# ----------
#
#  > 0 : Check the error codes definition section below.
#    0 : No error.
#
#*******************************************************************************

# Taking input  from user  for username, password & IP or hostname
echo "Please provide the hostname or IP address: "
        read ip_name
echo "Please provide the login user name: "
        read u_name
echo "Please provide the password for $u_name: "
        read u_pass

#Assign name to all log files & csv file
if [ ! -f time.start ]
then
date -u +'%d/%m/%Y %H:%M:%S' > time.start
fi
dns_n=`sshpass -p $u_pass ssh $u_name@"$ip_name" "hostname -f"`
linuxasset="linuxasset"
        datatime=`sshpass -p $u_pass ssh $u_name@"$ip_name" date "+%Y-%m-%d_%H:%M:%S"`
                logFile=${dns_n}_${linuxasset}_${datatime}.log
                        errorFile=${dns_n}_${linuxasset}_${datatime}.log
                                csvFile=${dns_n}_${linuxasset}_${datatime}.csv

#Final execution of all task which is mention in command_to_execute file:

sshpass -p $u_pass ssh $u_name@"$ip_name" < command_to_execute >> $logFile 2> $errorFile
        sed -n -e '/HOSTNAME/,$p'  $logFile   |  sed -r 's/ +/;/' > testFile
#           sed "/ServerNTPSourceName/a  `echo "DateLastScriptExecution;"` `date -u "+%d/%m/%Y %T"`" testFile1 > testFile
                awk -F';' '{for (i=1; i<=NF; i++) a[i,NR]=$i; max=(max<NF?NF:max)} END {for(i=1; i<=max; i++) {for (j=1; j<=NR; j++) printf "%s%s", a[i,j], (j==NR?RS :FS) }}'  testFile>$csvFile

#                rm -rf testFile
#				rm -rf testFile1
