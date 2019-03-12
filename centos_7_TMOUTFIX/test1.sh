#!/bin/bash
Token=`curl -i -k -H 'Content-Type:application/json;charset=utf8' -X POST -d'{"auth": {"identity": {"methods": ["password"],"password": {"user": {"name": "abhay.srivastava","password": "appu@orange","domain": {"id": "c9f1d27bef8041dbafe721a8d25b3d28"}}}},"scope": {"project": {"name": "eu-west-0"}}}}' https://iam.eu-west-0.prod-cloud-ocb.orange-business.com/v3/auth/tokens | grep "X-Subject"|awk -F':' '{print $2}' |tr -d '\r'| tr -d '\n'`
 
