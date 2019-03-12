#!/bin/bash -xe
source /opt/abhay/project/redhat_7_4/script.sh >/dev/null 2>&1
servername=$1
image_name=$2-Final

echo "Aquiring AUTH.Token from Openstack....."

token=$(curl -s -i -k $OS_AUTH_URL/auth/tokens -H "Content-type: application/json" -X POST -d @<(cat <<EOF
{
"auth":{"identity":{"methods":["password"],"password":{"user":{"name":'$OS_USERNAME',"password":'$OS_PASSWORD',"domain":{"name":'$OS_DOMAIN_NAME'}}}},"scope":{"project":{"name":'$OS_TENANT_NAME'}}}
}
EOF
) | grep "X-Subject-Token:"| cut -d : -f 2)

echo $token

F_EIP=`openstack server show $servername -f json  | grep addresses | awk -F"," '{print $2}' | sed -e 's/"//'`

ECS_STATUS=$(openstack server list | grep $servername |  awk {'print $6'})>/dev/null 2>&1
if [ "$ECS_STATUS" != "SHUTOFF" ]
then
openstack server stop $servername
fi

status=$(openstack server list | grep $servername |  awk {'print $6'})>/dev/null 2>&1

while [ "$status" != "SHUTOFF" ]
do
sleep 20
status=$(openstack server list | grep $servername |  awk {'print $6'})>/dev/null 2>&1
done

SERVER_ID=$(openstack server show $servername -f json |jq '.id' | sed -e 's/^"//'  -e 's/"$//')>/dev/null 2>&1

curl -sS https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v2/cloudimages/action -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $token" -H 'X-Language: en-us' -d @<(cat <<EOF
{
"name": "$image_name",
"description":"Create an image using an ECS.",
"instance_id": "$SERVER_ID"
}
EOF
)>/dev/null 2>&1

echo "Sleeping for 15 mins" `sleep 900`
