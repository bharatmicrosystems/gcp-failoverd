#!/bin/bash
while getopts ":i:e:l:" opt; do
    case "$opt" in
    i)  internal_vip=$OPTARG
        internal=true
        ;;
    e)  external_vip=$OPTARG
        external=true
        ;;
    l)  loadbalancers=$OPTARG
    esac
done
if $internal; then
  sed -i "s/#VIP/-i ${internal_vip} #VIP/g" assign-vip.service
fi

if $external; then
  sed -i "s/#VIP/-e ${external_vip}/g" assign-vip.service
fi

for instance in $(echo $loadbalancers | tr ',' ' '); do
  ZONE=`gcloud compute instances list --filter="name=${instance}"|grep ${instance} | awk '{ print $2 }'`
  gcloud compute scp --zone=$ZONE --internal-ip gcp-failoverd.service gcp-failoverd.sh configure-gcp-failoverd.sh assign-internal-vip.sh assign-external-vip.sh ${instance}:~/
  gcloud compute ssh --zone=$ZONE --internal-ip ${instance} -- "cd ~/ && sh -x configure-gcp-failoverd.sh"
done
