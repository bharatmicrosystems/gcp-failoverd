
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
  startup_script = "sudo rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm && sudo yum install -y git wget nginx && sudo systemctl start nginx"
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
  startup_script = "sudo rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm && sudo yum install -y git wget nginx && sudo systemctl start nginx"
  scopes = ["compute-rw","storage-rw"]
}

module "allow-ssh-http" {
  name        = "allow-ssh-http"
  source        = "./modules/firewall"
  source_ranges = var.source_ranges
  source_tags = []
  tcp_ports = ["80","22"]
  udp_ports = []
  target_tags = ["nginx"]
}
