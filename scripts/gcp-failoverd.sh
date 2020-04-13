#!/bin/bash
while getopts ":i:e:" opt; do
    case "$opt" in
    i)  internal_vip=$OPTARG
        internal=true
        ;;
    e)  external_vip=$OPTARG
        external=true
        ;;
    esac
done

mkdir -p /etc/gcp-failoverd
#Check if the VIP is being used
if $internal; then
    INTERNAL_IP=`gcloud compute addresses list --filter=\"name=$internal_vip\"| grep $internal_vip | awk '{ print $2 }'`
fi
if $external; then
    EXTERNAL_IP=`gcloud compute addresses list --filter=\"name=$external_vip\"| grep $external_vip | awk '{ print $2 }'`
fi
while true; do
  if $internal; then
      INTERNAL_IP_STATUS=`gcloud compute addresses list --filter=\"name=$internal_vip\"| grep $internal_vip | awk '{ print $NF }'`
  fi
  if $external; then
      EXTERNAL_IP_STATUS=`gcloud compute addresses list --filter=\"name=$external_vip\"| grep $external_vip | awk '{ print $NF }'`
  fi
  if [[ $INTERNAL_IP_STATUS == "IN_USE" ]];
  then
    echo "Internal IP address in use at $(date)" >> /etc/gcp-failoverd/poll.log
  else
    ZONE=`gcloud compute instances list --filter=\"name=$(hostname)\"| grep $(hostname) | awk '{ print $2 }'`
    # Assign IP aliases to me because now I am the MASTER!
    gcloud compute instances network-interfaces update $(hostname) \
      --zone $ZONE \
      --aliases "${INTERNAL_IP_STATUS}/32" >> /etc/gcp-failoverd/takeover.log 2>&1
    echo "I became the MASTER of ${INTERNAL_IP_STATUS} at: $(date)" >> /etc/gcp-failoverd/takeover.log
  fi
  if [[ $EXTERNAL_IP_STATUS == "IN_USE" ]];
  then
    echo "External IP address in use at $(date)" >> /etc/gcp-failoverd/poll.log
  else
    ZONE=`gcloud compute instances list --filter=\"name=$(hostname)\"| grep $(hostname) | awk '{ print $2 }'`
    # Assign IP aliases to me because now I am the MASTER!
    gcloud compute instances add-access-config $(hostname) \
     --access-config-name "$(hostname)-access-config" --address $EXTERNAL_IP_STATUS >> /etc/gcp-failoverd/takeover.log 2>&1
    echo "I became the MASTER of ${EXTERNAL_IP_STATUS} at: $(date)" >> /etc/gcp-failoverd/takeover.log
  fi
  sleep 30
done
