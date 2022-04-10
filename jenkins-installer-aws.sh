#!/bin/bash
# Install Jenkins

echo "This script installs Jenkins from a fresh RHEL8 server."
echo "It also creates user jenkins with sudo privilege."
echo
echo "Copyright 2022. Unix Training Academy Inc."
sleep 5

echo
echo creating user jenkins...; sleep 3
useradd jenkins
echo redhat | passwd jenkins --stdin
echo 'jenkins ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/jenkins
chage -d 0 -m3 -M90 -W5 -I 7 -E 2023-04-10 jenkins

echo
echo Updating the OS...
dnf -y upgrade

echo
echo Installing wget...
dnf -y install wget

echo
echo Downloading Jenkins...
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

echo
echo Installing Java...
dnf -y install fontconfig java-11-openjdk

echo
echo Installing Jenkins...

dnf -y install jenkins

echo
#echo Setting up firewall ports...
#YOURPORT=8080
#PERM="--permanent"
#SERV="$PERM --service=jenkins"

#firewall-cmd $PERM --new-service=jenkins
#firewall-cmd $PERM --add-service=jenkins
#firewall-cmd $SERV --set-short="Jenkins ports"
#firewall-cmd $SERV --set-description="Jenkins port exceptions"
#firewall-cmd $SERV --add-port=$YOURPORT/tcp
#firewall-cmd $PERM --add-service=jenkins
#firewall-cmd --zone=public --add-service=http --permanent
#firewall-cmd --reload

echo
echo Defining JAVA_HOME variable for Linux user jenkins...
echo JAVA_HOME="/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep java)" >> ~jenkins/.bash_profile
echo 'PATH=$PATH:$JAVA_HOME:$HOME/bin' >> ~jenkins/.bash_profile
echo 'export PATH' >> ~jenkins/.bash_profile

echo
echo Starting and enabling Jenkins...
systemctl enable --now jenkins
systemctl status jenkins | head

echo
echo ....
echo Created Linux user account 'jenkins' with initial password 'redhat'
echo Note: You MUST change this upon first login.
echo ....
echo
echo 'Your Jenkins web interface is at:'
echo 'http:/<your-jenkins-server-ip-address>:8080'
echo
echo 'Your initial admin password for the Jenkins Console is:'
echo $(cat /var/lib/jenkins/secrets/initialAdminPassword)
echo '(This is also available from /var/lib/jenkins/secrets/initialAdminPassword)'
echo
su - jenkins
echo ****END****
