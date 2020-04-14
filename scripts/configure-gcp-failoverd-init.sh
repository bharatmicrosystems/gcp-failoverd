#!/bin/bash
sudo yum install -y pacemaker pcs
sudo usermod --password $(openssl passwd -1 IuemFjfTAkmLSeM) hacluster
sudo systemctl enable pcsd.service
sudo systemctl start pcsd.service
sudo systemctl restart pcsd.service
