#!/bin/bash

function create_keypair {

openstack keypair create mykey-$instance_name > ~/mykey-$instance_name.pem
chmod 600 ~/mykey-$instance_name.pem

}

function delete_keypair {

openstack keypair delete mykey-$instance_name>/dev/null 2>&1

rm -f ~/mykey-$instance_name.pem

}
