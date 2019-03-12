#!/bin/bash
for i in `cat users`
do
userdel -r  $i
if [ $? -eq 0 ]
then
echo "$i successfully deleted"
else
echo "$i not deleted"
fi
done
