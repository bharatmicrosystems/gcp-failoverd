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
    c)  CLUSTER_NAME=$OPTARG
    esac
done
priority=150
instance = $(echo $loadbalancers | tr ',' ' ' | awk {'print $1'}); do
if $internal; then
  sed -i "s/#internal_vip/internal_vip=${internal_vip}/g" gcp-failoverd.sh
  sed -i "s/#internal=true/internal=true/g" gcp-failoverd.sh
fi

if $external; then
  sed -i "s/#external_vip/external_vip=${external_vip}/g" gcp-failoverd.sh
  sed -i "s/#external=true/external=true/g" gcp-failoverd.sh
fi
cp -a configure-gcp-failoverd-init.sh.template configure-gcp-failoverd-init.sh
cp -a configure-gcp-failoverd-bootstrap.sh.template configure-gcp-failoverd-bootstrap.sh
sed -i "s/#PASSWORD/$PASSWORD/g" configure-gcp-failoverd-init.sh
sed -i "s/#PASSWORD/$PASSWORD/g" configure-gcp-failoverd-bootstrap.sh
sed -i "s/#CLUSTER_NAME/$CLUSTER_NAME/g" configure-gcp-failoverd-bootstrap.sh
ZONE=`gcloud compute instances list --filter="name=${instance}"|grep ${instance} | awk '{ print $2 }'`
PRIMARY_IP=$(gcloud compute instances describe --zone=$ZONE $instance --format='get(networkInterfaces[0].networkIP)')
sed -i "s/#PRIMARY_IP/$PRIMARY_IP/g" configure-gcp-failoverd-bootstrap.sh
priority=$(($priority - 10))
SECONDARY_IPS=''
for peer in $(echo $loadbalancers | tr ',' ' '); do
  if [[ $peer != $instance ]]; then
    ZONE=`gcloud compute instances list --filter="name=${peer}"|grep ${peer} | awk '{ print $2 }'`
    PEER_IP=$(gcloud compute instances describe --zone=$ZONE $peer --format='get(networkInterfaces[0].networkIP)')
    SECONDARY_IPS=$SECONDARY_IPS" "$PEER_IP
  fi
done
sed -i "s/#SECONDARY_IPS/$SECONDARY_IPS/g" configure-gcp-failoverd-bootstrap.sh
#for instance in $(echo $loadbalancers | tr ',' ' '); do
#  ZONE=`gcloud compute instances list --filter="name=${instance}"|grep ${instance} | awk '{ print $2 }'`
#  gcloud compute scp --zone=$ZONE --internal-ip keepalived.conf gcp-failoverd.sh configure-gcp-failoverd.sh ${instance}:~/
#  gcloud compute ssh --zone=$ZONE --internal-ip ${instance} -- "cd ~/ && sh -x configure-gcp-failoverd.sh"
#done
