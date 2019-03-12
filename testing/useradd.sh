#!/bin/bash
for i in `cat users`
do
useradd $i
if [ $? -eq 0 ]
then
echo "$i successfully created"
else
echo "$i not created"
fi
done
