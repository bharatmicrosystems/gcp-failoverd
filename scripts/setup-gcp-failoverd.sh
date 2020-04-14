#!/bin/bash
while getopts ":i:e:l:r:" opt; do
    case "$opt" in
    i)  internal_vip=$OPTARG
        internal=true
        ;;
    e)  external_vip=$OPTARG
        external=true
        ;;
    l)  loadbalancers=$OPTARG
        ;;
    r)  vr_id=$OPTARG
    esac
done
priority=150
for instance in $(echo $loadbalancers | tr ',' ' '); do
  cp -a keepalived.conf.template keepalived.conf
  if $internal; then
    sed -i "s/#VIP/-i ${internal_vip} #VIP/g" keepalived.conf
  fi

  if $external; then
    sed -i "s/#VIP/-e ${external_vip}/g" keepalived.conf
  fi
  SOURCE_IP=$(gcloud compute instances describe $instance --format='get(networkInterfaces[0].networkIP)')
  sed -i "s/#SOURCE_IP/$SOURCE_IP/g" keepalived.conf
  sed -i "s/#VR_ID/$vr_id/g" keepalived.conf
  sed -i "s/#PRIORITY/$priority/g" keepalived.conf
  priority=$(($priority - 10))
  for peer in $(echo $loadbalancers | tr ',' ' '); do
    if [[ $peer != $instance ]]; then
      PEER_IP=$(gcloud compute instances describe $peer --format='get(networkInterfaces[0].networkIP)')
      sed -i "s/#PEER_IP/$PEER_IP\n        #PEER_IP/g" keepalived.conf
    fi
  done
  ZONE=`gcloud compute instances list --filter="name=${instance}"|grep ${instance} | awk '{ print $2 }'`
  gcloud compute scp --zone=$ZONE --internal-ip keepalived.conf gcp-failoverd.sh configure-gcp-failoverd.sh ${instance}:~/
  gcloud compute ssh --zone=$ZONE --internal-ip ${instance} -- "cd ~/ && sh -x configure-gcp-failoverd.sh"
done
