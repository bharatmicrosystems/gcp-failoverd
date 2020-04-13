#!/bin/bash
VIP=$1
mkdir -p /etc/gcp-failoverd
#Check if the VIP is being used
IP=`gcloud compute addresses list| grep $VIP | awk '{ print $2 }'`
while true; do
  while [[ $(gcloud compute addresses list --filter="name=$VIP"| grep $VIP | awk '{ print $NF }') == "IN_USE" ]];
  do
    echo "IP address in use at $(date)" >> /etc/gcp-failoverd/poll.log
    sleep 30
  done

  ZONE=`gcloud compute instances list --filter="name=$(hostname)"| grep $(hostname) | awk '{ print $2 }'`
  # Assign IP aliases to me because now I am the MASTER!
  gcloud compute instances add-access-config $(hostname) \
   --access-config-name "$(hostname)-access-config" --address $IP >> /etc/gcp-failoverd/takeover.log 2>&1
  echo "I became the MASTER of ${IP} at: $(date)" >> /etc/gcp-failoverd/takeover.log
  sleep 30
done
