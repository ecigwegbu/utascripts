#!/bin/bash
echo
echo "This script installs NagiosXI server..."
echo "(c) 2022 Unix Training Academy, Inc."
echo
sleep 5
echo "First, update the RHEL OS..."
sudo dnf update -y
echo "...done."
echo 
echo "Installing EPEL..."
sudo dnf -y install "https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
echo "...done."
echo 
echo "Enabling codeready builder ..."
sudo dnf config-manager --set-enabled codeready-builder-for-rhel-8-rhui-rpms
echo "...done."
echo
echo "installing dnf-utils..."
sudo dnf install -y dnf-utils
echo "...done."
echo
echo "Installing wget utility..."
sudo dnf install wget -y
echo "...done."
echo
echo "Downloading NagiosXI..."
cd /tmp
wget https://assets.nagios.com/downloads/nagiosxi/xi-latest.tar.gz
tar xzf xi-latest.tar.gz
cd nagiosxi
ls -l
echo "...done"

echo "Now installing NagiosXI..."
./fullinstall
cd ~
echo "...done"
echo
echo "Nagios Successfully Installed."
echo "Please open your web browser and navigate to"
echo "http://<your-nagios-server's-ip-address>/nagiosxi to finalize the configuration."
echo
echo "*** END***"
