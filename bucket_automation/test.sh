#!/bin/bash -xe
fileCount=`s3cmd  ls -c /opt/abhay/project/bucket_automation/obs-abhay-FE-Prod/.s3cfg s3://obs-abhay/ImageName.qcow2 | grep -c ImageName.qcow2`
if [ $fileCount -ne 1 ]
then
until [ $fileCount -eq 1 ]
do
fileCount=`s3cmd  ls -c /opt/abhay/project/bucket_automation/obs-abhay-FE-Prod/.s3cfg s3://obs-abhay/ImageName.qcow2 | grep -c ImageName.qcow2`
sleep 5
done
fi
