#!/bin/bash
token=$(curl -i -k $OS_AUTH_URL/auth/tokens -H "Content-type: application/json" -X POST -d @<(cat <<EOF
"auth":{"identity":{"methods":["password"],"password":{"user":{"name":'$OS_USERNAME',"password":'$OS_PASSWORD',"domain":{"id":'$OS_USER_DOMAIN_ID'}}}},"scope":{"project":{"name":'$OS_TENANT_NAME'}}}
))
echo Token is "$token"
