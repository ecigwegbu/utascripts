#!/bin/bash
# Install Jenkins

if ! sudo subscription-manager status &> /dev/null; then
  echo "Please register this server first with Red Hat."
  echo "Exiting..."
  exit 1  # Server not registered
fi

echo "This script installs Jenkins on a fresh RHEL9 server."
echo "It also creates a user 'jenkins' with sudo privileges."
echo
echo "Copyright 2024. Unix Training Academy Inc."
sleep 5

echo
echo "Creating user 'jenkins'..."; sleep 3
sudo useradd jenkins
echo redhat | sudo passwd jenkins --stdin
echo 'jenkins ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/jenkins
sudo chage -d 0 -m3 -M90 -W5 -I 7 -E $(date -d "+1 year" "+%Y-%m-%d") jenkins  # expire in 1 year

echo
echo "Updating the OS..."
sudo dnf -y upgrade

echo
echo "Installing utilities - wget and git..."
sudo dnf -y install wget git

echo
echo "Downloading Jenkins repository file..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

echo
echo "Installing Java..."
sudo dnf -y install fontconfig java-17-openjdk

echo
# sudo sed -i '/gpgcheck=1/c\gpgcheck=0' /etc/yum.repos.d/jenkins.repo  # if GPG key does not work
echo "Installing Jenkins..."
sudo dnf -y install jenkins

echo
echo "Setting up firewall ports..."
YOURPORT=8080
PERM="--permanent"
SERV="$PERM --service=jenkins"

# sudo firewall-cmd $PERM --add-service=jenkins
sudo firewall-cmd $SERV --set-short="Jenkins ports"
sudo firewall-cmd $SERV --set-description="Jenkins port exceptions"
sudo firewall-cmd $SERV --add-port=$YOURPORT/tcp
sudo firewall-cmd $PERM --add-service=jenkins
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --reload

echo
echo "Defining JAVA_HOME variable for Linux user 'jenkins'..."
JAVA_HOME_PATH="/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep java | head -n 1)"
echo "export JAVA_HOME=$JAVA_HOME_PATH" | sudo tee -a /home/jenkins/.bash_profile
echo 'PATH=$PATH:$JAVA_HOME/bin:$HOME/bin' | sudo tee -a /home/jenkins/.bash_profile
echo 'export PATH' | sudo tee -a /home/jenkins/.bash_profile

echo
echo "Starting and enabling Jenkins..."
sudo systemctl enable --now jenkins
sudo systemctl status jenkins | head

echo
echo "...."
echo "Created Linux user account 'jenkins' with initial password 'redhat'"
echo "Note: You MUST change this upon first login."
echo "...."
echo
echo "Your Jenkins web interface is at:"
echo "http://$(hostname -I | awk '{print $1}'):$YOURPORT"
echo
echo "Your initial admin password for the Jenkins Console is:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "(This is also available from /var/lib/jenkins/secrets/initialAdminPassword)"
sudo su - jenkins
echo
echo '              *************** END ****************'
echo 'Jenkins Installer (c) 2024. Unix Training Academy. All Rights Reserved'
echo 'Enquiries? dm Author: Elias Igwegbu <igwegbu@gmail.com>'
