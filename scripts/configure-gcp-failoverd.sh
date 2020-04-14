sudo yum install -y keepalived
#sudo cp -a gcp-failoverd.service /etc/systemd/system/gcp-failoverd.service
sudo chmod +x gcp-failoverd.sh
sudo mv gcp-failoverd.sh /usr/bin/
#sudo systemctl daemon-reload
#sudo systemctl start gcp-failoverd.service
#sudo systemctl enable gcp-failoverd.service
sudo mv keepalived.conf /etc/keepalived/
sudo systemctl enable keepalived
sudo systemctl start keepalived
sudo systemctl restart keepalived
