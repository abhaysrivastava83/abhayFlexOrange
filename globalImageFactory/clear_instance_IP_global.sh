#!/bin/bash -xe
source /opt/abhay/project/{{ instance_name }}/script.sh >/dev/null 2>&1
#source lib/functions.sh
openstack floating ip delete `cat /opt/abhay/project/{{ instance_name }}/eip.entry`
openstack server delete --wait  $instance_name
openstack keypair delete mykey-$instance_name
rm -rf /opt/abhay/project/{{ instance_name }}/mykey-$instance_name.pem
openstack image delete $image_name
rm -rf /opt/abhay/project/{{ instance_name }}/images/*
echo "" >/opt/abhay/project/{{ instance_name }}/eip.entry
echo "" >/opt/abhay/project/{{ instance_name }}/eip1.entry
echo "" >/opt/abhay/project/{{ instance_name }}/var_stuff.yml
echo "" >/opt/abhay/project/{{ instance_name }}/hosts
rm -rf /opt/abhay/project/{{ instance_name }}/

