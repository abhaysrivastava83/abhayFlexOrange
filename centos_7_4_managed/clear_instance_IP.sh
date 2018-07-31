#!/bin/bash -xe
source /opt/abhay/project/centos_7_4_managed/script.sh >/dev/null 2>&1
#source lib/functions.sh
openstack floating ip delete `cat /opt/abhay/project/centos_7_4_managed/eip.entry`
openstack server delete --wait  $instance_name
openstack keypair delete mykey-$instance_name
rm -rf /opt/abhay/project/centos_7_4_managed/mykey-$instance_name.pem 
openstack image delete $image_name
rm -rf /opt/abhay/project/centos_7_4_managed/images/*
echo "" >/opt/abhay/project/centos_7_4_managed/eip.entry
echo "" >/opt/abhay/project/centos_7_4_managed/eip1.entry
echo "" >/opt/abhay/project/centos_7_4_managed/var_stuff.yml
echo "" >/opt/abhay/project/centos_7_4_managed/hosts
