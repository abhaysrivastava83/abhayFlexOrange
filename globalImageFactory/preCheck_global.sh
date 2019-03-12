#!/bin/bash -xe
source /opt/abhay/project/globalImageFactory/script.sh
CountECS=`openstack server list -c ID -f value | wc -l`
CountEIP=`openstack floating ip list -c 'Floating IP Address' -f value | wc -l`
if [ $CountECS -lt 100 && $CountEIP -lt 10 ]
then
if [ -d /opt/abhay/project/globalImageFactory/$instance_name 
then
openstack floating ip delete `cat /opt/abhay/project/{{ instance_name }}/eip.entry` || true
openstack server delete --wait  $instance_name  || true
openstack keypair delete mykey-$instance_name || true
rm -rf /opt/abhay/project/{{ instance_name }}/mykey-$instance_name.pem || true
openstack image delete $image_name || true
rm -rf /opt/abhay/project/{{ instance_name }}/images/* || true
echo "" >/opt/abhay/project/{{ instance_name }}/eip.entry || true
echo "" >/opt/abhay/project/{{ instance_name }}/eip1.entry  || true
echo "" >/opt/abhay/project/{{ instance_name }}/var_stuff.yml  || true
echo "" >/opt/abhay/project/{{ instance_name }}/hosts  || true
rm -rf /opt/abhay/project/{{ instance_name }}/  || true


