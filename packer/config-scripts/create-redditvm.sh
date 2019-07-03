#!/bin/bash

#create instance
gcloud compute instances create reddit-full\
  --boot-disk-size=10GB \
  --image-family reddit-full \
  --machine-type=f1-micro \
  --tags reddit-full \
  --restart-on-failure \
  --zone europe-west1-b

#open port for instance
gcloud compute firewall-rules create reddit-full \
  --direction=INGRESS --priority=1000 --network=default --action=ALLOW \
  --rules=tcp:9292 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=reddit-full

