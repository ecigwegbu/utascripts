#!/bin/bash
# containers-as-system-services.sh 

# Guided Exercise 3: Manage Containers as System Services
# Student Guide Notes and Commands
# You should practice by running these commands one by one on your terminal
# ... they help you follow or understand the steps in the student guide.
# But of course you can run it as a script in one go ... just to see it do its
# magic.

# Approximate reference to the Guided Exercise text is included as comments (eg #5.0.).

# Preparation
echo '********* PREPARATION *************'

# 2.
echo '2. **Create a user account with which to run the Systemd user service ***'
sudo useradd contsvc 2>/dev/null
echo redhat | sudo passwd contsvc --stdin
# Make the new user a sudoer
echo 'contsvc ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/contsvc

# Relogin as user contsvc (required to use podman). Let's ssh instead
dnf -q install -y sshpass 2>/dev/null  # quietly install sshpass; we need it
# for non-interactive password login in this script :)

# Once we relogin as contsvc using the following ssh command, all the commands between
# within the EOF block will be exectuted within the new user shell/session
sshpass -p redhat ssh -Tqo StrictHostKeyChecking=no -o PasswordAuthentication=yes contsvc@localhost << EOF
whoami
# podman info

# 3.echo '3. ***** Configure the podman registries in your own home directory ***********'
mkdir -p ~/.config/containers/
cp /etc/containers/registries.conf ~/.config/containers

# 4.
echo '4. ***** Create a directory for storing the website content in your VM *****'
mkdir -p ~/webcontent/html/

# Create the index file in this directory, ie buildyour website !
echo "Welcome to UTA" > ~/webcontent/html/index.html

# Ensure 'others' have read permission on the index file. 
# Note that that also means execute permission on the folder containing it!!
chmod -R o=rX ~/webcontent/html

# 5.
echo '5. ********* Create the Container that will become the web server  **********'

# Clear leftover from previous attempts - for this user
systemctl --user disable --now container-webapp 2>/dev/null
(podman stop webapp && podman rm webapp) 2>/dev/null

# Create the container, but first you must register with Red Hat container registry
# Note: export the RHSM_PASS and RHSM_USER from your terminal before proceeding eg:
# You can also add this to ~/.bashrc and source ~/.bashrc to make it permanent for this user
# export RHSM_USER=my-red-hat-user-name
# export RHSM_PASS=my-red-hat-password
# As a precaution, we will exit now if you have not logged in or set these variables:
if ! podman login --get-login registry.redhat.io &> /dev/null && \
   ([[ -z ${RHSM_USER} ]] || [[ -z ${RHSM_PASS} ]]); then
    echo -e "Please login to registry.redhat.io\nor export login credentials RHSM_USER and RHSM_PASS before running this script, so I can login for you :)\n"
    echo 'Exiting...'
    exit 2  # Missing Registry login
fi
echo ${RHSM_PASS} | podman login registry.redhat.io --username ${RHSM_USER} --password-stdin

# Note that if you omit the html subdirectory in one path, 
# you must be consistent for both paths
# podman search of the image shows that the correct path for this image's data is /var/www
# Note that tag 1-163 in the book is problemaatic so we will use latest for this exercise
podman run -d --name webapp -p 8080:8080 -v \
~/webcontent:/var/www:Z registry.redhat.io/ubi8/httpd-24:latest

# verify that the container is running. Note down its ID.
# We will compare it with the ID of the one created by systemd later
podman ps

# 5.3
echo '5.3 ********** Verify that the website is live  ***********'
# Verify that the website is now live, using curl, the ip or hostname, 
# and the port number on the container itself. When you specify localhost
# it means you are within the VM and that works if the container is also inside the same VM.
# This does not require port mappping or firewall opening as the port is on the container

# Add delay before running curl
echo -e "\nCURLING Website...the one started manually by running the podman command" && sleep 2
curl -s http://localhost:8080   # or curl 127.0.0.1:8080
echo

# Now this one requires firewall openening of port 8080, if you want access from outside the
# VM hosting the container, ie if you use the VM's LAN ip address
# curl http://192.168.56.20:8080  # use your own ip, and be sure 8080/tcp is open on firewall,
                            # and your LAN permits ingress into the VM (eg Bridged network).
                            # But if your LAN is using NAT, you need to do port forwarding
                            # on your OS/Hypervisor first (eg in VirtualBox forward 8080 to 8080)

# 6.
echo '6. *****  Create a Systemd user service for the container ****'
# Create a Systemd user service that will manage the container. First create the 
# directory where the Quadlet will be placed:
mkdir -p /home/contsvc/.config/containers/systemd/

# 6.3
echo '6.3 **** Stop and remove the container so Systemd can manage the container by itself ****'
podman stop webapp && podman rm webapp
podman ps -a  # should be empty

# 6.2
# Build the systemd user Quadlet file
echo '***** Build the user Quadlet file ******'
cat << EOL | tee /home/contsvc/.config/containers/systemd/webapp.container
[Container]
Image=registry.redhat.io/ubi8/httpd-24:latest
Name=webapp
Network=true
User=root
Restart=always
PublishPort=8080:8080
Volume=/home/contsvc/webcontent:/var/www:Z
EOL

# 7.
echo '7. ******** Create and run the container using systemd *********'
# Reload systemd daemon, since we modified (created) a systmed unit file.
# Notice that sudo is not required for systemd --user case
systemctl --user daemon-reload

# Start and enable the systemd user service just generated
systemctl --user enable --now container-webapp

# verify that the container is now running (notice that the id is
# different now; it is a new container):
podman ps

# 7.3
echo '7.3 ******** Try to view the web page again, started by Systemd *******'
# Try to view the web page, as before
# Add delay before running curl
echo -e "\nCURLING Website...the one started by Systemd" && sleep 2
curl -s http://localhost:8080
echo

# Stop the web service (and the container) using Systemd
systemctl --user stop container-webapp
podman ps --all

# Start the service again, and again compare the container ID:
systemctl --user start container-webapp
podman ps

# 8.
echo '8. *******   Enable Linger, so the service survives user logout ****'
loginctl enable-linger
loginctl show-user contsvc | grep 'Linger' # reports Linger=yes...

# 8.3
echo '8.3 ******* Verify that the container restarts on reboot ****'
# The container restarts on reboot, and stays on when user is switched to root
# sudo su -
# reboot
# When the system comes up again:
# ssh contsvc@servera # Use your actual VM ip address
# podman ps
# curl http://localhost:8080

echo '******** FINISHED ******'
# FINISHED.

# When done you can clean up, by running the following commands manually:
# Or try making up a small script with it!!
# systemctl --user disable --now container-webapp
#
echo -e '\nEnquiries? Use Group Chat or dm Elias Igwegbu <igwegbu@gmail.com>'
echo '(c) 2024. Unix Training Academy. All Rights Reserved'
EOF
