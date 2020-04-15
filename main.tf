module "nat" {
  source     = "./modules/cloud-nat"
  region     = var.region
  name    = "cloud-nat"
}
resource "google_compute_address" "nginx-external-vip" {
  name = "nginx-external-vip"
}
resource "google_compute_address" "nginx-internal-vip" {
  name         = "nginx-internal-vip"
  subnetwork   = "default"
  address_type = "INTERNAL"
  region       = var.region
}
module "nginx-instance01" {
  source        = "./modules/instance"
  instance_name = "nginx-instance01"
  instance_machine_type = "n1-standard-1"
  instance_zone = "${var.region}-a"
  instance_image = "centos-7-v20191014"
  tags = ["nginx"]
  subnet_name = "default"
  startup_script = "sudo rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm && sudo yum install -y git wget nginx"
  scopes = ["compute-rw","storage-rw"]
}

module "nginx-instance02" {
  source        = "./modules/instance"
  instance_name = "nginx-instance02"
  instance_machine_type = "n1-standard-1"
  instance_zone = "${var.region}-b"
  instance_image = "centos-7-v20191014"
  tags = ["nginx"]
  subnet_name = "default"
  startup_script = "sudo rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm && sudo yum install -y git wget nginx"
  scopes = ["compute-rw","storage-rw"]
}

module "bastion" {
  source        = "./modules/instance-external"
  instance_name = "bastion"
  instance_machine_type = "n1-standard-1"
  instance_zone = "${var.region}-a"
  instance_image = "centos-7-v20191014"
  subnet_name = "default"
  startup_script = "sudo yum install -y git wget"
  tags = ["bastion"]
  scopes = ["compute-rw","storage-rw"]
}

module "allow-http" {
  name        = "allow-http"
  source        = "./modules/firewall"
  source_ranges = var.source_ranges
  source_tags = []
  tcp_ports = ["80"]
  udp_ports = []
  target_tags = ["nginx"]
}

module "allow-ssh" {
  name        = "allow-ssh"
  source        = "./modules/firewall"
  source_ranges = var.source_ranges
  source_tags = []
  tcp_ports = ["22"]
  udp_ports = []
  target_tags = ["bastion"]
}

module "allow-bastion-to-instances" {
  name        = "allow-bastion-to-instances"
  source        = "./modules/firewall"
  source_ranges = []
  source_tags = ["bastion","nginx"]
  tcp_ports = ["22","80"]
  udp_ports = []
  target_tags = []
}

module "allow-nginx-nginx" {
  name        = "allow-nginx-nginx"
  source        = "./modules/firewall"
  source_ranges = []
  source_tags = ["nginx"]
  tcp_ports = []
  udp_ports = ["5404-5406"]
  target_tags = ["nginx"]
}
