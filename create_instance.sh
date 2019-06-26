#!/bin/bash

#create instance
gcloud compute instances create reddit-app1\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server1 \
  --restart-on-failure \
  --metadata startup-script-url='https://raw.githubusercontent.com/otus-devops-2019-05/apshenniy_infra/cloud-testapp/startup_script.sh'

#open port for instance
gcloud compute firewall-rules create default-puma-server1 \
  --direction=INGRESS --priority=1000 --network=default --action=ALLOW \
  --rules=tcp:9292 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=puma-server1
