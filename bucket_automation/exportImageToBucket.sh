#!/bin/bash -xe

source /opt/abhay/project/redhat_7_4/script.sh >/dev/null 2>&1
ImgDir=$(date +%Y%m%d%S)

find /opt/abhay/project/bucket_automation/ -type d -name "2*" -exec rm -r {} \;

echo "Aquiring AUTH.Token from Openstack....."

token=$(curl -s -i -k $OS_AUTH_URL/auth/tokens -H "Content-type: application/json" -X POST -d @<(cat <<EOF
{
"auth":{"identity":{"methods":["password"],"password":{"user":{"name":'$OS_USERNAME',"password":'$OS_PASSWORD',"domain":{"name":'$OS_DOMAIN_NAME'}}}},"scope":{"project":{"name":'$OS_TENANT_NAME'}}}
}
EOF
) | grep "X-Subject-Token:"| cut -d : -f 2)

IMG_ID=`openstack image list | grep -i "$ImageName"  | awk -F "|" '{print $2}' | sed 's/ //g'`

echo $IMG_ID

sleep 10

curl -i -k -X POST https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v1/cloudimages/"$IMG_ID"/file -d "{\"bucket_url\":\"$bucketName:"$ImageName".qcow2\",\"file_format\":\"qcow2\"}" -H "X-Auth-Token: ${token}"

fileCount=`s3cmd  ls -c /opt/abhay/project/bucket_automation/obs-abhay-FE-Prod/.s3cfg s3://"$bucketName"/"$ImageName".qcow2 | grep -c "$ImageName".qcow2`
if [ "$fileCount" -ne 1 ]
then
    until [ "$fileCount" -eq 1 ]
    do
        fileCount=`s3cmd  ls -c /opt/abhay/project/bucket_automation/obs-abhay-FE-Prod/.s3cfg s3://"$bucketName"/"$ImageName".qcow2 | grep -c "$ImageName".qcow2`
        sleep 10
    done
fi

mkdir -p /opt/abhay/project/bucket_automation/"$ImgDir"

s3cmd get -c /opt/abhay/project/bucket_automation/obs-abhay-FE-Prod/.s3cfg s3://"$bucketName"/"$ImageName".qcow2 /opt/abhay/project/bucket_automation/"$ImgDir"/ --force
if [ -e /opt/abhay/project/bucket_automation/"$ImgDir"/"$ImageName".qcow2 ]
then
    img_file=`find /opt/abhay/project/bucket_automation/"$ImgDir"/ -name "*.qcow2" -type f`
    cd /opt/abhay/project/bucket_automation/"$ImgDir"
    mv -f  "$ImageName".qcow2 "$ImageNewName".qcow2
    s3cmd put -c /opt/abhay/project/bucket_automation/OBS-bucket-img-ppr/.s3cfg "$ImageNewName".qcow2 s3://bucket-image-ppr
fi

fileCount_ppr=`s3cmd  ls -c /opt/abhay/project/bucket_automation/OBS-bucket-img-ppr/.s3cfg s3://bucket-image-ppr/"$ImageNewName".qcow2 | grep -c "$ImageNewName".qcow2`

if [ "$fileCount_ppr" -ne 1 ]
then
    until [ "$fileCount_ppr" -eq 1 ]
    do
        fileCount_ppr=`s3cmd  ls -c /opt/abhay/project/bucket_automation/OBS-bucket-img-ppr/.s3cfg s3://bucket-image-ppr/"$ImageName".qcow2 | grep -c "$ImageName".qcow2`
        sleep 5
    done
fi

if [ -d /opt/abhay/project/bucket_automation/"$ImgDir" ]
then
    rm -rf /opt/abhay/project/bucket_automation/"$ImgDir"
fi
