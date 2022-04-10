#!/bin/bash
echo
echo "........................................................."
echo "This script installs a NagiosXI client"
echo "(C) 2022 Unix Training Academy, Inc. All Rights Reserved."
echo "........................................................."
sleep 5
echo
echo "First update the OS, Install EPEL, etc ..."
echo
echo "Updating the OS ..."
sudo dnf update -y 
echo "...done."
echo
echo "Installing EPEL ..."
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
echo "...done."
echo
echo "Enabling code-ready-builder..."
sudo dnf config-manager --set-enabled codeready-builder-for-rhel-8-rhui-rpms
echo "...done."
echo
echo "Installing dnf-utils..."
sudo dnf install dnf-utils -y
echo "...done."
echo
echo "Installing wget..."
sudo dnf install wget -y
echo "...done."
echo
#
# Installing Nagios agent on client servers.
echo "Downloading the Linux NRPE agent to the /tmp directory..."
 
cd /tmp
sudo wget https://assets.nagios.com/downloads/nagiosxi/agents/linux-nrpe-agent.tar.gz
echo "...done."
 
echo "Unpacking the installation archive just downloaded..."
sudo tar xzf linux-nrpe-agent.tar.gz
echo "...done"

"Run the wrapper script as root..."
# Running the wrapper script automatically takes care of a number of things
# Enter the newly created agent subdirectory:
cd linux-nrpe-agent
sudo ./fullinstall
echo "...done"
 
# The script will stop to prompt you for the IP address(es) for your monitoring server(s). You will need to type in
# either a) a single address, b) a list of addresses separated only by spaces, c) a subnet using CIDR notation
# like 10.25.0.0/16. That will configure the xinetd daemon to allow connections from those locations to the
# agent process

# Now install the required Nagios repository that has NCPA package.
echo "Installing the Nagios repository that has the NCPA package..."
sudo rpm -Uvh https://repo.nagios.com/nagios/8/nagios-repo-8-1.el8.noarch.rpm
sudo dnf install ncpa -y
echo "...done"
echo

echo "Changing the token..."
#By default, the token value is set to 'mytoken'
#This value should be changed right away to a custom one for security reasons:
#Look for the following lines:

# [api]
# community_string = <your new token>
# change the value <your new token> to your real token and save the file.
# You must make sure that the community_string value is under the [api] section for it to work.

sudo sed -i 's/mytoken/mtN4ever/g' /usr/local/ncpa/etc/ncpa.cfg
echo "...done."

# After making the changes, restart the NCPA listener service:
echo "Restarting the NCPA listener service..."
sudo /etc/init.d/ncpa_listener restart
echo
echo ">>>>End of Nagios Client Installation Script<<<"
echo 
