#!/usr/bin/python
import os
import sys
os.system('export ANSIBLE_HOST_KEY_CHECKING=false')
inv_host = raw_input("Please insert IP of host without key: ")
file = open('inv_cloud', 'w')
file.write(inv_host)
file.close()

inv_sys_host = raw_input("Please insert IP of host with cloud key path EXAMPLE  192.168.1.140 ansible_ssh_private_key_file=/root/abhay/abhay_keys/KeyPair-1c48_abhay_prod.pem: ")
file1 = open('inv_system', 'w')
file1.write(inv_sys_host)
file1.close()
os.system('ansible-playbook -i inv_cloud suse_playbook_Cloud_work.yml --ask-pass')
os.system('ansible-playbook -i inv_system suse_playbook_OS_Work.yml')
u_input = raw_input("DO YOU WANT TO CLEAR ALL LOGS, press y to proceed: ")
if u_input == 'y' or u_input == 'Y':
    os.system('ansible-playbook -i inv_system clearAllLogs.yml')
