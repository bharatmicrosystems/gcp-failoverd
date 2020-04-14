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
    INTERNAL_IP=`gcloud compute addresses list --filter="name=$internal_vip"| grep $internal_vip | awk '{ print $2 }'`
fi
if $external; then
    EXTERNAL_IP=`gcloud compute addresses list --filter="name=$external_vip"| grep $external_vip | awk '{ print $2 }'`
fi
internal_status=false
external_status=false
while $internal_status && $external_status; do
  ZONE=`gcloud compute instances list --filter="name=$(hostname)"| grep $(hostname) | awk '{ print $2 }'`
  if $internal; then
    INTERNAL_IP_STATUS=`gcloud compute addresses list --filter="name=$internal_vip"| grep $internal_vip | awk '{ print $NF }'`
  else
    internal_status=true
  fi

  if $external; then
    EXTERNAL_IP_STATUS=`gcloud compute addresses list --filter="name=$external_vip"| grep $external_vip | awk '{ print $NF }'`
  else
    external_status=true
  fi

  if [[ $INTERNAL_IP_STATUS == "IN_USE" ]];
  then
    #Check if the instance where the IP is tagged is running
    INTERNAL_INSTANCE_REGION=$(gcloud compute addresses list --filter="name=${internal_vip}"|grep ${internal_vip}|awk '{print $(NF-2)}')
    INTERNAL_INSTANCE_NAME=$(gcloud compute addresses describe ${internal_vip} --region=${INTERNAL_INSTANCE_REGION} --format='get(users[0])'|awk -F'/' '{print $NF}')
    INTERNAL_INSTANCE_ZONE=$(gcloud compute instances list --filter="name=${INTERNAL_INSTANCE_NAME}"|grep ${INTERNAL_INSTANCE_NAME}|awk '{print $2}')
    INTERNAL_INSTANCE_STATUS=$(gcloud compute instances describe --zone=${INTERNAL_INSTANCE_ZONE} $INTERNAL_INSTANCE_NAME --format='get(status)')
    if [[ $INTERNAL_INSTANCE_STATUS == "RUNNING" ]];
    then
      echo "Internal IP address in use at $(date)" >> /etc/gcp-failoverd/poll.log
    else
      #Update the alias from the terminated instance to null
      gcloud compute instances network-interfaces update $INTERNAL_INSTANCE_NAME \
        --zone $INTERNAL_INSTANCE_ZONE \
        --aliases "" >> /etc/gcp-failoverd/takeover.log 2>&1
      INTERNAL_IP_STATUS="RESERVED"
    fi
  fi
  if [[ $EXTERNAL_IP_STATUS == "IN_USE" ]];
  then
    #Check if the instance where the IP is tagged is running
    EXTERNAL_INSTANCE_REGION=$(gcloud compute addresses list --filter="name=${external_vip}"|grep ${external_vip}|awk '{print $(NF-1)}')
    EXTERNAL_INSTANCE_NAME=$(gcloud compute addresses describe ${external_vip} --region=${EXTERNAL_INSTANCE_REGION} --format='get(users[0])'|awk -F'/' '{print $NF}')
    EXTERNAL_INSTANCE_ZONE=$(gcloud compute instances list --filter="name=${EXTERNAL_INSTANCE_NAME}"|grep ${EXTERNAL_INSTANCE_NAME}|awk '{print $2}')
    EXTERNAL_INSTANCE_STATUS=$(gcloud compute instances describe --zone=${EXTERNAL_INSTANCE_ZONE} $EXTERNAL_INSTANCE_NAME --format='get(status)')
    if [[ $EXTERNAL_INSTANCE_STATUS == "RUNNING" ]];
    then
      echo "External IP address in use at $(date)" >> /etc/gcp-failoverd/poll.log
    else
      EXTERNAL_ACCESS_CONFIG=$(gcloud compute instances describe --zone=${ZONE} $EXTERNAL_INSTANCE_NAME --format='get(networkInterfaces[0].accessConfigs[0].name')
      #Delete the access config from the terminated node
      gcloud compute instances delete-access-config --zone=${ZONE} $EXTERNAL_INSTANCE_NAME --access-config-name=${EXTERNAL_ACCESS_CONFIG}
      EXTERNAL_IP_STATUS="RESERVED"
    fi
  fi
  if [[ $INTERNAL_IP_STATUS == "IN_USE" ]];
  then
    echo "Internal IP address in use at $(date)" >> /etc/gcp-failoverd/poll.log
    sleep 60
  else
    # Assign IP aliases to me because now I am the MASTER!
    gcloud compute instances network-interfaces update $(hostname) \
      --zone $ZONE \
      --aliases "${INTERNAL_IP}/32" >> /etc/gcp-failoverd/takeover.log 2>&1
    if [ $? -eq 0 ]; then
      echo "I became the MASTER of ${INTERNAL_IP} at: $(date)" >> /etc/gcp-failoverd/takeover.log
      internal_status=true
    fi
  fi
  if [[ $EXTERNAL_IP_STATUS == "IN_USE" ]];
  then
    echo "External IP address in use at $(date)" >> /etc/gcp-failoverd/poll.log
    sleep 60
  else
    # Assign IP aliases to me because now I am the MASTER!
    gcloud compute instances add-access-config $(hostname) \
     --zone $ZONE \
     --access-config-name "$(hostname)-access-config" --address $EXTERNAL_IP >> /etc/gcp-failoverd/takeover.log 2>&1
    if [ $? -eq 0 ]; then
      echo "I became the MASTER of ${EXTERNAL_IP} at: $(date)" >> /etc/gcp-failoverd/takeover.log
      external_status=true
    fi
  fi
done
