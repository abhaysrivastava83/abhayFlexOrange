#!/usr/bin/env bash

set -o xtrace

if [ -z $* ];then
    echo "Usage: ./test-cases.sh <Image name or ID to be tested as can be seen in openstack image list> "
    exit
fi

TOP="$(cd "$(dirname "$0")"/.. && pwd)"
WD="$(pwd)"
mkdir -p "$WD"/keys "$WD"/bck
KEY_DIR="$(cd "$WD"/keys && pwd )"
BK_DIR="$(cd "$WD"/bck && pwd )"
TENANT_ID=81f369b80f664ed283540062135a7a41
IMAGE="$@"

source "$WD"/fe_rc
source "$WD"/common-functions.sh

pre_steps(){
    local server_key="$(openstack keypair list -c Name -f value|grep -c testkey)"
    if [ $server_key -eq 1 ];then
        openstack keypair delete testkey
    fi

    local server_old="$(openstack server list -c ID -c Name -f value |grep test-ecs|awk '{print $1}')"
    if [ ! -z $server_old ];then
        openstack server delete --wait $server_old
    fi

    local port_old="$(openstack port list -f value |grep fe-test| awk '{print $1}')"
    if [ ! -z $port_old ];then
        openstack port delete $port_old
    fi
    local port_ip=$(openstack port show fe-test-port -c fixed_ips -f value| awk -F "=" '{print $2}'| cut -d "'" -f 2)
    if [ ! -z $port_ip ];then
        local server_port=$(openstack server list -f table|grep "$port_ip" | awk '{print $2}')
        if [ ! -z server_port ];then
            openstack server remove port "$server_port" fe-test-port
            openstack port delete $port_old
            openstack server delete --wait $server_port
        fi
    sleep 3
    fi

    volume_old="$(openstack volume list -f value|grep fe-test-volume| awk '{print $1}')"
    if [ ! -z $volume_old ];then
        openstack volume delete $volume_old
    fi
    local server_vol="$(openstack volume show fe-test-volume -c attachments -f yaml|grep server_id|awk '{print $2}')"
    if [ ! -z server_vol ];then
        openstack server delete --wait $server_vol
        openstack volume delete $volume_old
    fi
    sleep 3

    rm -rf "${KEY_DIR:?}/"*
    rm -rf "$WD"/create_vol.json "$WD"/attach_vol.json
    openstack keypair create testkey > "$KEY_DIR"/testkey.pem
    chmod -R 600 "${KEY_DIR:?}/"*

    mv "$WD"/fe_test_report.txt "$BK_DIR"/result-"$(TZ=IST-5:30 date)"

    cat >>"$WD"/fe_test_report.txt <<EOL
                                                    FE TEST REPORT
########################################################################################################################

+++++++++++++++++++++++++++++++++++++++++++++++++++++++
+   Date: %time%
+   Start Time: %time_start%
+   End Time: %time_end%
+   Image Name: %image%
+++++++++++++++++++++++++++++++++++++++++++++++++++++++

________________________________________________________________________________________________________________________
S.no |   TEST                                                                   |         RESULT
========================================================================================================================
1.   |   Start instance                                                         |         %test1%
2.   |   Stop a running instance                                                |         %test2%
3.   |   Restart instance                                                       |         %test3%
4.   |   Check instance active from reboot                                      |         %test4%
5.   |   Check SSH                                                              |         %test5%
6.   |   Attach port to instance                                                |         %test6%
7.   |   Check NIC in instance                                                  |         %test7%
8.   |   Remove NIC from instance                                               |         %test8%
9.   |   Attach EVS disk to instance                                            |         %test9%
10.  |   Check EVS disk attached in instance                                    |         %test10%
11.  |   Detach EVS disk from instance                                          |         %test11%
12.  |   Check EVS disk removed from instance                                   |         %test12%
13.  |   Delete instance                                                        |         %test13%
========================================================================================================================

DEBUG--


EOL

    sed -i -e "s/%time%/"$(TZ=IST-5:30 date +%F)"/g" "$WD"/fe_test_report.txt
    sed -i -e "s/%time_start%/"$(TZ=IST-5:30 date +%T)"/g" "$WD"/fe_test_report.txt
    sed -i -e 's/%image%/'"$IMAGE"'/g' "$WD"/fe_test_report.txt


    local server_image=$(openstack image list|grep -ci "$IMAGE")
    if [ "$server_image" -eq 0 ];then
        echo "Image not found on FE" >> "$WD"/fe_test_report.txt
        die 108 "Wrong argument"
    fi


}

test1(){
    #TODO: Generic image and flavor name
    echo "TEST: Start instance"

    # Start ECS
    local status=$(openstack server list -c Name -f value|grep -c test-ecs)
    if [ $status -ge 0 ]; then
        local COUNTER=0
        until [ $status -eq 0 ];do
            if [ $COUNTER -eq 0 ];then
                local server_id
                server_id=$(openstack server list -c ID -c Name -f value |grep test-ecs|awk '{print $1}')
                openstack server delete --wait "$server_id"
                local status=$(openstack server list -c Name -f value|grep -c test-ecs)
                    if [ $status -ge 0 ]; then
                        COUNTER=$(expr "$COUNTER" + 1)
                    fi
            fi
            local status=$(openstack server list -c Name -f value|grep test-ecs|wc -l)
            sleep 3
        done
    fi

    openstack --insecure server create --flavor t2.micro --image "$IMAGE" \
    --key-name testkey --nic net-id=1fd7a904-2367-4a43-ae49-1351588387d6 --security-group default --wait test-ecs

    local status=$(openstack server list -c Name -f value|grep -c test-ecs)
    local status_check=1
    assert_equal $status $status_check "Instance Launch Successful"
    if [ $status -eq 1 ];then
        sed -i "s/%test1%/PASSED/g" $WD/fe_test_report.txt
    else
        sed -i "s/%test1%/FAILED/g" $WD/fe_test_report.txt
    fi
}


test2(){
    echo "TEST: Stop a running instance"

    local pre_status=$(openstack server show test-ecs -c status -f value)
    if [[ "$pre_status" = "ACTIVE" ]]; then
        local COUNTER=0
        until [[ "$status" = "SHUTOFF" ]];do
            if [ $COUNTER -eq 0 ];then
              openstack server stop test-ecs
              COUNTER=$(expr $COUNTER + 1)
            fi
            local status=$(openstack server show test-ecs -c status -f value)
            sleep 2
        done
    fi

    local status=$(openstack server show test-ecs -c status -f value)
    local status_check=SHUTOFF
    assert_equal $status $status_check "Instance Stop Successful"
    if [ "$status" == "$status_check" ];then
        sed -i "s/%test2%/PASSED/g" $WD/fe_test_report.txt
    else
        sed -i "s/%test2%/FAILED/g" $WD/fe_test_report.txt
    fi
}

test3_4(){
    echo "TEST: Restart instance"

    local pre_status=$(openstack server show test-ecs -c status -f value)

    if [[ "$pre_status" = "SHUTOFF" ]]; then
        local COUNTER=0
        until [[ "$status" = "ACTIVE" ]];do
            if [[ $COUNTER -eq 0 ]];then
              openstack server start test-ecs
              COUNTER=$(expr $COUNTER + 1)
            fi
            local status=$(openstack server show test-ecs -c status -f value)
            sleep 2
        done
    fi

    local token=$(openstack token issue -c id -f value)
    local server_id=$(openstack server show test-ecs -c id -f value)
    local pre_status=$(openstack server show test-ecs -c status -f value)
    local status_check=REBOOT
    local COUNTER=0
    if [[ "$pre_status" != "SHUTOFF" ]]; then
        until [ "$status" = "REBOOT" ];do
            if [ $COUNTER -eq 0 ];then
                curl -sS https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v2/$TENANT_ID/servers/$server_id/action -X POST \
                -H 'Content-Type: application/json' -H 'Accept: application/json' \
                -H "X-Auth-Token: $token" -H 'X-Language: en-us' -d @<(cat <<EOF
                    {
                        "reboot": {
                        "type": "SOFT"
                        }
                    }
EOF
)
                 COUNTER=$(expr $COUNTER + 1)
            fi
            local status=$(openstack server show test-ecs -c status -f value)
            sleep 2
        done
    fi

    assert_equal $status $status_check "ECS rebooting"
    if [ "$status" == "$status_check" ];then
        sed -i "s/%test3%/PASSED/g" $WD/fe_test_report.txt
    else
        sed -i "s/%test3%/FAILED/g" $WD/fe_test_report.txt
    fi


    echo "TEST: Instance up from Reboot"
    local status_check1=ACTIVE
    if [ "$status" != "ACTIVE" ]; then
        until [ "$status" = "ACTIVE" ];do
        local status=$(openstack server show test-ecs -c status -f value)
        sleep 2
        done
    fi
    assert_equal $status $status_check1 "ECS successfully up from reboot"
    if [ "$status" == "$status_check1" ];then
        sed -i "s/%test4%/PASSED/g" $WD/fe_test_report.txt
    else
        sed -i "s/%test4%/FAILED/g" $WD/fe_test_report.txt
    fi

}

test5(){
    echo "TEST: Check SSH"

    local ip="$(openstack server show test-ecs -c addresses -f value|awk -F "=" '{print $2}'|awk -F "," '{print $1}')"
    local status=0
    until [[ $status -eq 8  ]];do
        local status="$(ping -c 3 "$ip"|wc -l)"
        if [ $status -eq 8 ];then
            sleep 120
            local status_ssh="$(ssh -o StrictHostKeyChecking=no -i keys/testkey.pem cloud@"$ip" "ls -A /sys/class/net | wc -l")"
            assert_equal $status_ssh 1 "Able to SSH"
            if [ "$status_ssh" -ge "1" ];then
                sed -i "s/%test5%/PASSED/g" "$WD"/fe_test_report.txt
            else
                sed -i "s/%test5%/FAILED/g" "$WD"/fe_test_report.txt
            fi
        else
            sed -i "s/%test5%/FAILED/g" "$WD"/fe_test_report.txt
        fi
    done
}

test6_7(){
    echo "TEST: Attach NIC to ECS and check it in instance"

    local ip=$(openstack server show test-ecs -c addresses -f value|awk -F "=" '{print $2}'|awk -F "," '{print $1}')
    openstack port create --network ef4f624b-bd3f-4e93-a53a-3ca3e08d8e21 fe-test-port
    openstack server add port test-ecs fe-test-port
    status_port=1 #Random Value for next loop
    until [[ -z "$status_port" ]];do
        local port_ip=$(openstack port show fe-test-port -c fixed_ips -f value| awk -F "=" '{print $2}'| cut -d "'" -f 2)
        local status_port="$(openstack server show test-ecs -c addresses -f value |grep -v "$port_ip")"
        sleep 5
    done
    assert_empty $status_port "Port Added Successfully"
    if [ -z "$status_port" ];then
        sleep 120
        local status_new="$(ssh -o StrictHostKeyChecking=no -i keys/testkey.pem cloud@"$ip" "ls -A /sys/class/net | wc -l")"
        assert_equal $status_new 3 "NIC is available in instance and SSH Works"
        if [ $status_new -eq  3 ];then
            sed -i "s/%test6%/PASSED/g" "$WD"/fe_test_report.txt
            sed -i "s/%test7%/PASSED/g" "$WD"/fe_test_report.txt
        elif [ $status_new -eq 2 ];then
            sed -i "s/%test6%/PASSED/g" "$WD"/fe_test_report.txt
            sed -i "s/%test7%/FAILED/g" "$WD"/fe_test_report.txt
        else
            sed -i "s/%test6%/PASSED/g" "$WD"/fe_test_report.txt
            sed -i "s/%test7%/UNKNOWN_ERROR/g" "$WD"/fe_test_report.txt
        fi
    else
        sed -i "s/%test6%/FAILED/g" "$WD"/fe_test_report.txt
        sed -i "s/%test7%/FAILED/g" "$WD"/fe_test_report.txt
    fi
}

test8(){
    echo "TEST: Remove NIC"

    openstack server remove port test-ecs fe-test-port
    until [[ $status -eq 2 ]];do
        local ip=$(openstack server show test-ecs -c addresses -f value|awk -F "=" '{print $2}'|awk -F "," '{print $1}')
        local status=$(ssh -o StrictHostKeyChecking=no -i keys/testkey.pem cloud@"$ip" "ls -A /sys/class/net | wc -l")
        sleep 5
    done
    assert_equal $status 2 "NIC removed from instance"
    if [ $status -eq  2 ];then
        sed -i "s/%test8%/PASSED/g" "$WD"/fe_test_report.txt
    else
        sed -i "s/%test8%/FAILED/g" "$WD"/fe_test_report.txt
    fi
}

test9(){
    echo "Test 3a: Attach an EVS Disk"

    local az="$(openstack server show test-ecs -c OS-EXT-AZ:availability_zone -f value)"
    local token="$(openstack token issue -c id -f value)"
    local server_id="$(openstack server show test-ecs -c id -f value)"

    cat >>"$WD"/create_vol.json <<EOL
    {
    "volume": {
               "availability_zone": "availzn",
               "display_description": null,
               "snapshot_id": null,
               "size": 25,
               "display_name": "fe-test-volume",
               "volume_type": null,
               " metadata ":{}
              }
    }
EOL
    sed -i "s/availzn/${az}/g" "$WD"/create_vol.json
    curl -sS https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v2/"$TENANT_ID"/os-volumes -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $token" -H 'X-Language: en-us' -d @create_vol.json

    local volume_id
    until [[ ! -z $volume_id ]];do
        volume_id=$(openstack volume show fe-test-volume -c id -f value)
        sleep 5
    done

    cat >>"$WD"/attach_vol.json <<EOL
    {
        "volumeAttachment": {
             "volumeId": "volid",
             "device": "/dev/sdh"
        }
    }
EOL
    sed -i "s/volid/${volume_id}/g" $WD/attach_vol.json
    curl -sS https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v2/"$TENANT_ID"/servers/"$server_id"/os-volume_attachments -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $token" -H 'X-Language: en-us' -d @attach_vol.json

    local status=0
    until [[ $status -eq 1 ]];do
        local status=$(curl -sS https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v2/"$TENANT_ID"/servers/"$server_id"/os-volume_attachments -X GET -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $token" -H 'X-Language: en-us'|python -m json.tool|grep dev|wc -l)
        sleep 5
    done
    assert_equal $status 1  "Disk Attach Successful"
    if [ $status -eq  1 ];then
        sed -i "s/%test9%/PASSED/g" "$WD"/fe_test_report.txt
    else
        sed -i "s/%test9%/FAILED/g" "$WD"/fe_test_report.txt
    fi
}

test10(){
    echo "Check EVS disk attached in instance"

    local ip=$(openstack server show test-ecs -c addresses -f value|awk -F "=" '{print $2}'|awk -F "," '{print $1}')
    local status=0
    until [[ $status -eq 2 ]];do
        status=$(ssh -o StrictHostKeyChecking=no -i "$KEY_DIR"/testkey.pem cloud@"$ip" "lsblk|grep disk|wc -l")
        sleep 5
    done
    assert_equal $status 2 "New EVS present in instance"
    if [ $status -eq  2 ];then
        sed -i "s/%test10%/PASSED/g" "$WD"/fe_test_report.txt
    else
        sed -i "s/%test10%/FAILED/g" "$WD"/fe_test_report.txt
    fi
}

test11(){
    echo "TEST: Detach EVS Disk"

    local token=$(openstack token issue -c id -f value)
    local server_id=$(openstack server show test-ecs -c id -f value)
    local volume_id=$(openstack volume show fe-test-volume -c id -f value)

    curl -sS https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v1/"$TENANT_ID"/cloudservers/"$server_id"/detachvolume/"$volume_id" -X DELETE -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $token" -H 'X-Language: en-us'

    local status=0
    until [[ $status -eq 1 ]];do
        status=$(curl -sS https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v2/"$TENANT_ID"/servers/"$server_id"/os-volume_attachments -X GET -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $token" -H 'X-Language: en-us'|python -m json.tool|grep dev|wc -l)
        sleep 5
    done
    assert_equal $status 1 "Disk Detach Successful"
    if [ $status -eq  1 ];then
        sed -i "s/%test11%/PASSED/g" "$WD"/fe_test_report.txt
    else
        sed -i "s/%test11%/FAILED/g" "$WD"/fe_test_report.txt
    fi
}

test12(){
    echo "TEST: Check EVS disk removed from instance"

    local ip=$(openstack server show test-ecs -c addresses -f value|awk -F "=" '{print $2}'|awk -F "," '{print $1}')
    local status=0
    until [[ $status -eq 1 ]];do
        status=$(ssh -o StrictHostKeyChecking=no -i $KEY_DIR/testkey.pem cloud@$ip "lsblk|grep disk|wc -l")
        sleep 5
    done
    assert_equal $status 1 "New EVS present in instance"
    if [ $status -eq  1 ];then
        sed -i "s/%test12%/PASSED/g" "$WD"/fe_test_report.txt
    else
        sed -i "s/%test12%/FAILED/g" "$WD"/fe_test_report.txt
    fi
}

test13(){
    echo "TEST: Delete instance"

    openstack server delete --wait test-ecs
    sleep 3
    local status=$(openstack server list -c Name|grep test-ecs)
    assert_empty $status "Instance Deletion successful"
    if [ -z "$status" ];then
        sed -i "s/%test13%/PASSED/g" $WD/fe_test_report.txt
    else
        sed -i "s/%test13%/FAILED/g" $WD/fe_test_report.txt
    fi
}

clean_up(){
    echo "Final Cleanup"

    local server_key="$(openstack keypair list -c Name -f value|grep -c testkey)"
    if [ $server_key -eq 1 ];then
        openstack keypair delete testkey
    fi

    local server_old="$(openstack server list -c ID -c Name -f value |grep test-ecs|awk '{print $1}')"
    if [ ! -z $server_old ];then
        openstack server delete --wait $server_old
    fi

    local port_old="$(openstack port list -f value |grep fe-test| awk '{print $1}')"
    if [ ! -z $port_old ];then
        openstack port delete $port_old
    fi
    local port_ip=$(openstack port show fe-test-port -c fixed_ips -f value| awk -F "=" '{print $2}'| cut -d "'" -f 2)
    if [ ! -z $port_ip ];then
        local server_port=$(openstack server list -f table|grep "$port_ip" | awk '{print $2}')
        if [ ! -z server_port ];then
            openstack server remove port "$server_port" fe-test-port
            openstack port delete $port_old
            openstack server delete --wait $server_port
        fi
    sleep 3
    fi

    volume_old="$(openstack volume list -f value|grep fe-test-volume| awk '{print $1}')"
    if [ ! -z $volume_old ];then
        openstack volume delete $volume_old
    fi
    local server_vol="$(openstack volume show fe-test-volume -c attachments -f yaml|grep server_id|awk '{print $2}')"
    if [ ! -z server_vol ];then
        openstack server delete --wait $server_vol
        openstack volume delete $volume_old
    fi
    sleep 3

    rm -rf "${KEY_DIR:?}/"*
    rm -rf "$WD"/create_vol.json "$WD"/attach_vol.json

    while IFS='' read -r line || [[ -n "$line" ]]; do
        for i in {1..15};do
            sed -i -e "s/%test"$i"%/FAILED_TO_RUN/g" "$WD"/fe_test_report.txt
        done         
    done < "$WD"/fe_test_report.txt

    sed -i -e "s/%time_end%/"$(TZ=IST-5:30 date +%T)"/g" "$WD"/fe_test_report.txt
}

# "Run Tests"
run_with_timeout 100 pre_steps
check_test

run_with_timeout 100 test1
check_test

run_with_timeout 100 test2
check_test

run_with_timeout 300 test3_4
check_test

run_with_timeout 300 test5

run_with_timeout 300 test6_7

run_with_timeout 300 test8

run_with_timeout 300 test9

run_with_timeout 300 test10

run_with_timeout 300 test11

run_with_timeout 300 test12

run_with_timeout 300 test13

run_with_timeout 180 clean_up

