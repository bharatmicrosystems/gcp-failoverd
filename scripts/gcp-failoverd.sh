#!/bin/bash
param=$1
meta_data() {
  cat <<END
<?xml version="1.0"?>
<!DOCTYPE resource-agent SYSTEM "ra-api-1.dtd">
<resource-agent name="gcp-failoverd" version="0.1">
  <version>0.1</version>
  <longdesc lang="en"> floatip ocf resource agent for claiming a specified Floating IP via the GCP API</longdesc>
  <shortdesc lang="en">Assign Floating IP via GCP API</shortdesc>
  <actions>
    <action name="start"        timeout="6000" />
    <action name="stop"         timeout="20" />
    <action name="monitor"      timeout="20"
                                interval="10" depth="0" />
    <action name="meta-data"    timeout="5" />
  </actions>
</resource-agent>
END
}

if [ "start" == "$param" ] ; then
  systemctl start nginx
  /bin/sh /usr/bin/gcp-assign-vip.sh
  exit 0
elif [ "stop" == "$param" ] ; then
  systemctl stop nginx
  exit 0
elif [ "status" == "$param" ] ; then
  systemctl status nginx
  status=$?
  if [ $status -eq 0 ]; then
    echo "NGINX Running"
    exit 0
  elif [ $sttaus -eq 3 ]; then
    echo "NGINX is Stopped"
    exit 7
  else
    echo "NGINX is Errored"
    exit 1
  fi
elif [ "monitor" == "$param" ] ; then
  systemctl status nginx
  status=$?
  if [ $status -eq 0 ]; then
    echo "NGINX Running"
    exit 0
  elif [ $sttaus -eq 3 ]; then
    echo "NGINX is Stopped"
    exit 7
  else
    echo "NGINX is Errored"
    exit 1
  fi
elif [ "meta-data" == "$param" ] ; then
  meta_data
  exit 0
else
  echo "no such command $param"
  exit 1;
fi
