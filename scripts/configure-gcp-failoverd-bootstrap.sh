#!/bin/bash
#On primary only
sudo pcs cluster auth 10.154.0.60 10.154.0.61 -u hacluster -p IuemFjfTAkmLSeM
sudo pcs cluster setup --name nginx-cluster 10.154.0.60 10.154.0.61
sudo pcs cluster start --all
sudo pcs status corosync
sudo pcs cluster status
sudo pcs property set stonith-enabled=false
