#!/bin/bash -xe
source /opt/abhay/project/redhat_6_T2/script.sh >/dev/null 2>&1
servername=$1
image_name=$2-Final

token=`curl -i -k -H 'Content-Type:application/json;charset=utf8' -X POST -d'{"auth": {"identity": {"methods": ["password"],"password": {"user": {"name": "abhay.srivastava","password": "appu@orange","domain": {"id": "c9f1d27bef8041dbafe721a8d25b3d28"}}}},"scope": {"project": {"name": "eu-west-0"}}}}' https://iam.eu-west-0.prod-cloud-ocb.orange-business.com/v3/auth/tokens | grep "X-Subject"|awk -F':' '{print $2}' |tr -d '\r'| tr -d '\n'`

F_EIP=`openstack server show $servername -f json  | grep addresses | awk -F"," '{print $2}' | sed -e 's/"//'`

openstack server stop $servername

status=$(openstack server list | grep $servername |  awk {'print $6'})>/dev/null 2>&1

while [ "$status" != "SHUTOFF" ]
do
sleep 20
status=$(openstack server list | grep $servername |  awk {'print $6'})>/dev/null 2>&1
done

SERVER_ID=$(openstack server show $servername -f json |jq '.id' | sed -e 's/^"//'  -e 's/"$//')>/dev/null 2>&1

curl -sS https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v2/cloudimage1/action -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $token" -H 'X-Language: en-us' -d @<(cat <<EOF
{
"name": "$image_name",
"description":"Create an image using an ECS.",
"instance_id": "$SERVER_ID"
}
EOF
)>/dev/null 2>&1

echo "Sleeping for 15 mins" `sleep 900`
