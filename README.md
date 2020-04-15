# gcp-failoverd
This repository contains a daemon for automating failovers between primary and secondary Google Compute Engine Instances
This project makes use of pacemaker, corosyn and floating-ips on centos-7.

## Quick Start with an NGINX example
On your local machine install terraform

Create a service account on GCP -> Give appropratiate permissions -> Add to act as a service account user -> Generate and download JSON Key -> Rename json key to credentials.json and place it in the home directory
```
git clone https://github.com/bharatmicrosystems/gcp-failoverd.git
cd gcp-failoverd
cp -a ~/credentials.json .
cp -a terraform.tfvars.example terraform.tfvars
```
Edit the terraform.tfvars and set the project, region, and source_ranges
```
terraform init
terraform plan
terraform apply
gcloud auth activate-service-account <sa-name> --key-file=credentials.json
gcloud compute ssh bastion --zone europe-west2-a
```
## Once on the bastion host run
```
git clone https://github.com/bharatmicrosystems/gcp-failoverd.git
cd gcp-failoverd
cp -a scripts/ exec/
cd exec/
git clone https://github.com/bharatmicrosystems/gcp-failoverd.git
cd gcp-failoverd
git checkout develop
cp -a scripts/ exec/
cd exec/
git clone https://github.com/bharatmicrosystems/gcp-failoverd.git
cd gcp-failoverd
git checkout develop
cp -a scripts/ exec/
cd exec/
sh -x setup-gcp-failoverd.sh -i nginx-internal-vip -e nginx-external-vip -l nginx-instance01,nginx-instance02 -c nginx-cluster -h :80
```
This will also run a quick smoke test at the end to demonstrate the effect of stopping an instance!
And thats it!
