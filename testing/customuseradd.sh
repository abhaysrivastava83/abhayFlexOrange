#!/bin/bash
if [ -f  /etc/passwd ]
then
echo "Enter The UserName you want to Create"
read USER
UD=`tail -1 /etc/passwd | awk -F":" '{print $3}'`
UD=`expr $UD + 1`
useradd -u $UD  $USER
else 
echo "nofile found"
fi
