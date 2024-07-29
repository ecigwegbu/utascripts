#!/bin/bash
# containers-as-system-services.sh 

# Guided Exercise: Manage Containers as System Services
# Student Guide Notes and Commands
#
#  **************  IMPORTANT   ***********************
# This scipt requires that you have created the user contsvc with password redhat
# and that you have logged in as that user.
# Refer to the companion script containers-as-system-services-create-user.sh
# if you need assistance with that
#
# You should practice by running these commands one by one on your terminal
# ... they help you follow or understand the steps in the student guide.
# But of course you can run it as a script in one go ... just to see it do its
# magic.

# Approximate reference to the Guided Exercise text is included as comments (eg #5.0.).

# Preparation
echo -e "\n********* PREPARATION *************"

# Verify user
if ! [[ $(whoami) == contsvc ]]; then
  echo 'You need to login as user contsvc before running this script.'
  echo 'Exiting...'
  exit 1  # Invalid user
fi

# Verify Registry login
# Make sure Red Hat Registry login details are in the env or the user has
# actually already logged in to registry.redhat.io
#!/bin/bash
if ! podman login --get-login registry.redhat.io &> /dev/null && \
   ([[ -z ${RHSM_USER} ]] || [[ -z ${RHSM_PASS} ]]); then
    echo -e "Please login to registry.redhat.io\nor export login credentials RHSM_USER and RHSM_PASS before running this script, so I can login for you :)\n"
    echo 'Exiting...'
    exit 2  # Missing Registry login
fi

echo -e "\n********** Running as user $(whoami)... **************\n"

# podman info  

# 3.
echo -e "\n3. ***** Configure the podman registries in your own home directory ********"
mkdir -p ~/.config/containers/
cp /etc/containers/registries.conf ~/.config/containers

# 4.
echo -e "\n4. ***** Create a directory in your VM for storing the website content *****"
mkdir -p ~/webcontent/html/

# Create the index file in this directory, ie build your website !
echo "Welcome to UTA" > ~/webcontent/html/index.html

# Ensure 'others' have read permission on the index file.
# Note: that also means execute permission on the folder containing it!!
chmod -R o=rX ~/webcontent/html  # The upper case X works for the directory only here

# 5.
echo -e "\n5. ********* Create the Container that will become the web server  *********"

# Clear leftover from any previous attempts - for this user
systemctl --user disable --now container-webapp 2>/dev/null  # Incase service is running
(podman stop webapp && podman rm webapp) 2>/dev/null  # In case cont. were manually started

# Create the container, but first you must register with Red Hat registry
echo ${RHSM_PASS} | podman login registry.redhat.io --username ${RHSM_USER} --password-stdin
echo

# In the volume mapping, if you omit the html subdirectory on the VM side,
# you must be consistent for both sides;
# podman search of the image shows that the correct path for this image's data is /var/www
# and not /var/www/html.
# So it excludes the "html" part of the path. You must be consistent in the VM and in the container.
# For the image, we will use tag 'latest' because tag '1-163' in the book is problematic.
# Be sure to open the port we are using 8080 with firewalld. To be able to view the web page
# on your Windows browser, if your VM is using NAT you also need to do
# port mapping on your hypervisor (eg VirtualBox or VM Ware). 
# The port mapping on the hypervisor is not required if you just want to curl on your VM
# using 127.0.0.1 or localhost.

podman run -d --name webapp -p 8080:8080 -v \
~/webcontent:/var/www:Z registry.redhat.io/ubi8/httpd-24:latest

# verify that the container is running. Note down its ID.
# We will compare it with the ID of the one created by systemd later
podman ps

# 5.3
echo -e "\n5.3 ********** Verify that the website is live  ***********"
# Verify that the website is now live, using curl, localhost or 127.0.0.1, 
# and the port number on the container itself. When you specify localhost
# it means you are within the VM and that works if the container is also inside the same VM.
# This does not require port mappping or firewalld port opening as the port is on the container

# Add delay before running curl - give the container time to start up
echo -e "\nCURLING Website..." && sleep 2
curl -s http://localhost:8080   # or curl -s 127.0.0.1:8080

# Now this one requires firewalld openening of port 8080, if you want access from outside the
# VM hosting the container, ie if you use the VM's LAN ip address
sudo firewall-cmd -q --add-port=8080/tcp --permanent  # Do it '-q'uietly :)
sudo firewall-cmd --reload
# curl http://192.168.56.20:8080  # use your own ip, and be sure 8080/tcp is open on firewall,
                            # and your LAN permits ingress into the VM (eg Bridged network).
                            # But if your LAN is using NAT, you need to do port forwarding
                            # on your OS/Hypervisor first (eg in VirtualBox forward 8080 to 8080)

# 6.
echo -e "\n\n6. *****  Create a Systemd user service for the container ****"
# Create a Systemd user service that will manage the container. First create the 
# directory that will house the unit file that will be generated by Systemd, and cd into it:
mkdir -p ~/.config/systemd/user && cd ~/.config/systemd/user

# 6.2
# Generate the systemd user unit file
# When you run this, the command creates the Systemd user unit file and plases 
# it in the current directory. The --new option makes Systemd recreate the container
# each time it starts it up:
podman generate systemd --name webapp --files --new

# 6.3
echo -e "\n6.3 **** Stop and remove the container so Systemd can manage the container by itself ****"
# Note: Do not use podman to start/stop or otherwise control the container once you 
# start managing it with Systemd, to avoid conflicts
podman stop webapp && podman rm webapp
podman ps -a  # should be empty

# 7.
echo -e "\n7. ******** Create and run the container using systemd *********"
# Reload systemd daemon, since we modified (created) a systmed unit file.
# Notice that sudo is not required for systemd --user case
systemctl --user daemon-reload

# Start and enable the systemd user service that we just generated
systemctl --user enable --now container-webapp

# verify that the container is now running - notice that the id is
# different now; it is a new container :)
podman ps

# 7.3
echo -e "\n7.3 ******** Try to view the web page again, as started by Systemd *******"
# Try to view the web page, as before
# Add delay before running curl, just in case... :)
echo -e "\nCURLING Website..." && sleep 2
curl -s http://localhost:8080   # or curl -s 127.0.0.1:8080
echo

# Stop the web service (and the container) using Systemd
systemctl --user stop container-webapp
podman ps --all

# Start the service again, and again compare the container ID:
systemctl --user start container-webapp
podman ps

# 8.
echo -e "\n8. *******   Enable Linger, so the service survives user logout ****"
loginctl enable-linger
loginctl show-user contsvc | grep 'Linger' # reports Linger=yes...

# 8.3
echo -e "\n8.3 ******* Verify that the container restarts on reboot ****"
# The container restarts on reboot, and stays on when user is switched to root
# sudo su -
# curl -s http://localhost:8080   # or curl -s 127.0.0.1:8080
# reboot
# When the system comes up again:
# ssh contsvc@servera # Use your own VM's actual ip address
# podman ps
# curl -s http://localhost:8080   # or curl -s 127.0.0.1:8080

echo -e "\n******** FINISHED ******"
# FINISHED.

# When done you can clean up, by running the following commands manually:
# Or try making up a small script with it!!
# systemctl --user disable --now container-webapp
# loginctl disable-linger
# sudo rm -rf ~/webcontent
#
echo -e '\nEnquiries? Use Group Chat or dm Elias Igwegbu <igwegbu@gmail.com>'
echo '(c) 2024. Unix Training Academy. All Rights Reserved'
