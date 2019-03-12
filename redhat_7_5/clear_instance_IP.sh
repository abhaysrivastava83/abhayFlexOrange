#!/bin/bash -xe
source /opt/abhay/project/redhat_7_5/script.sh >/dev/null 2>&1
#source lib/functions.sh
openstack floating ip delete `cat /opt/abhay/project/redhat_7_5/eip.entry`
openstack server delete --wait  $instance_name
openstack keypair delete mykey-$instance_name
rm -rf /opt/abhay/project/redhat_7_5/mykey-$instance_name.pem 
openstack image delete $image_name
rm -rf /opt/abhay/project/redhat_7_5/images/*
echo "" >/opt/abhay/project/redhat_7_5/eip.entry
echo "" >/opt/abhay/project/redhat_7_5/eip1.entry
echo "" >/opt/abhay/project/redhat_7_5/var_stuff.yml

