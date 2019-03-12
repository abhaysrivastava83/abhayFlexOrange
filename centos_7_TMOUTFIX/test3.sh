cat <<EOF
{
"auth":{"identity":{"methods":["password"],"password":{"user":{"name":'$OS_USERNAME',"password":'$OS_PASSWORD',"domain":{"name":'$OS_DOMAIN_NAME'}}}},"scope":{"project":{"name":'$OS_TENANT_NAME'}}}
}
