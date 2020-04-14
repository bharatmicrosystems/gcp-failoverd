#!/bin/bash
sudo systemctl enable corosync.service pacemaker.service
sudo mkdir -p /usr/lib/ocf/resource.d/gcp
sudo mv gcp-failoverd.sh /usr/lib/ocf/resource.d/gcp/floatip
sudo chmod +x /usr/lib/ocf/resource.d/gcp/floatip
sudo chown -R root:root /usr/lib/ocf/resource.d/gcp
sudo pcs resource create FloatIP ocf:gcp:floatip
sudo pcs status
