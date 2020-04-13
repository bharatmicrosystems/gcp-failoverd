sudo cp -a gcp-failoverd.service /etc/systemd/system/gcp-failoverd.service
sudo chmod +x gcp-failoverd.sh assign-internal-vip.sh assign-external-vip.sh
sudo mv gcp-failoverd.sh assign-internal-vip.sh assign-external-vip.sh /usr/bin/
sudo systemctl daemon-reload
sudo systemctl start gcp-failoverd.service
sudo systemctl enable gcp-failoverd.service
