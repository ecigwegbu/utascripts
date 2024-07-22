#!/bin/bash
# container-storage-and-networks.sh

# Guided Exercise 2: Manage Container Storage and Network Resources
# Student Guide Notes and Commands
# You should practice by running these commands one by one on your terminal
# ... they help you follow or understand the steps in the student guide.
# But of course you can run it as a script in one go ... just to see it do its
# magic. At the end you get your MariaDB CLI,
# the result of connecting from db_client container to db_01 container.
# To exit MariaDB database CLI press CTRL/D

# Approximate reference to the Guided Exercise text is included as comments (eg #5.0.).

echo '*************** Preparation ***************'
# **** First, Manually login to registry.redhat.io; then
# make sure to export the db_01 password for dev1 user as an env variable****

export MYSQL_PWD=devpass

# To avoid problems, remove previous 'exercise' containers and the networks
(podman stop db_01 db_client) 2>/dev/null
(podman rm db_01 db_client) 2>/dev/null
(podman network rm frontend backend) 2>/dev/null

# Create a directory for the project and cd into it
mkdir -p /home/student/container-storage-and-networks
cd /home/student/container-storage-and-networks

# Make sure that there is a line that says 'network_backend = "netavark"' in the file:
# /usr/share/containers/containers.conf. This is to avoid 'aardvark'
# network non-compatibility issues; see page 351 in the Student Guide
# network_backend = "netavark"
sudo sed -i.bak '/network_backend = /c\network_backend = "netavark"' \
  /usr/share/containers/containers.conf

# 2.
echo '2. ************** Create first network ***************'
# Create the first network named "frontend" that the client and database will share
# This network provides DNS resolution that will enable client to talk to db
# by using its name db_01 instead of an ip address
podman network create --subnet 10.89.1.0/24 --gateway 10.89.1.1 frontend
podman network inspect frontend

# 4.0.
echo '4. ************** Create and Configure Persistent Volume ***************'
# Create the persistent volume that will store the database data in the VM:
mkdir -p /home/student/container-storage-and-networks/databases
# Assign the ownership to mysql (UID 27) but in the student user namespace
# This id is obtained during a first pass of creating the container
# by inspecting /etc/passwd or looking at "id -u" in the db_01 container
# podman exec -it db_01 whoami  # reports: mysql
# podman exec -it db_01 bash -c "id -u"  # returns 27 for mysql user
podman unshare chown 27:27 /home/student/container-storage-and-networks/databases

# 2.3.
echo '2.3 ************ Create Client Container *****************'
# Create the client container db_client
# Note: do not mount the /etc/yum.repos.d directory as suggested by the Student Guide
# That mounts your VMs repo into the container, and it is incompatible with this image
# So skip '-v /etc/yum.repos.d:/etc/yum.repos.d'
podman run -d --name db_client --network=frontend registry.redhat.io/ubi9/ubi sleep infinity
podman ps

# 4.4.
echo '4.4. ********** Create Database Container *******************'
# Create the database container. Note the env vars, volume and port mappings
podman run -d --name db_01 --network=frontend -e MYSQL_USER=dev1 -e MYSQL_PASSWORD=${MYSQL_PWD} -e MYSQL_DATABASE=devdb -e MYSQL_ROOT_PASSWORD=redhat -v /home/student/container-storage-and-networks/databases:/var/lib/mysql:Z -p 13306:3306 registry.redhat.io/rhel8/mariadb-105
podman ps

# 4.5.
echo '4.5. *************** Install MariaDB client package in db_client container ****'
# Install mariadb client package inside the db_client container.
# It is used to connect to a MariaDB database.
# Note that the default user in this particular container is root
podman exec -it db_client whoami  # reports: root
podman exec -it db_client dnf install mariadb -y

# 4.6.
echo '4.6. ********** Connect from Client container to Database container ******'
# Connect to the database from the client; note that the client uses the
# database's container's name, because
# DNS resolution works in the netavark network they share;
# The correct port to use is port 3306 (and not the host port 13306) because the client and
# database are in the same subnet.
# But the port is skipped here because it is the default port for MariaDB and
# is not required here (--port=3306)
podman exec -it db_client mysql -u dev1 -p${MYSQL_PWD} -h db_01 -e " \
  SHOW DATABASES; \
  USE devdb; \
  CREATE TABLE IF NOT EXISTS crucial_data(column1 int); \
  SHOW TABLES; \
"

# 4.7.
echo '4.7. ********** Open necessary ports on the host ******'
# open necessary ports
sudo firewall-cmd --add-port=13306/tcp --permanent 2>/dev/null
sudo firewall-cmd --reload

# 4.8.
echo '4.8. ********** Demonstrate access to container from OUTSIDE of host ******'
# Demonstrate access to the same database container but from outside it's subnet,
# ie go through the VM hosts LAN IP (eg 192.168.56.20)
# This will require using the hosts port 13306 as well. For this to work your VM must either be
# on a 'bridge' network with the Windows host PC, or you have done a port forward from Windows
# to your VM in your hypervisor (eg VirtualBox forward 13306 to 13306 for this VM).
podman exec -it db_client mysql -u dev1 -p${MYSQL_PWD} -h 192.168.56.20 --port=13306 -e " \
  SHOW DATABASES; \
  USE devdb; \
  CREATE TABLE IF NOT EXISTS crucial_data(column1 int); \
  SHOW TABLES; \
"
# 5.0.
echo '5.0. ********** Create a second netavark network and connect to it  ******'
# Now we create a second network named "backend".
# We want to show that a container can be connected to two different networks at the same time
podman network create --subnet 10.90.0.0/24 \
--gateway 10.90.0.1 backend
podman network ls
podman network inspect backend

# Add the database and client to the new network (they will still be in first network as well):
podman network connect backend db_client
podman network connect backend db_01

# Verify that the two containers are in both networks:
podman inspect db_01
podman inspect db_client

# We want to ping the database from the client. But first we must make sure the ping command
# is available in the container - by installing iputils package there:
podman exec -it db_client dnf install -y iputils
podman exec -it db_client ping -c4 db_01  # ping 4 times only

echo '******** FINISHED. Now you can play with MariaDB. Type CTRL/D to quit ******'
# FINISHED. You can manually play with your brand new MariaDB database by connecting to it
# from your db_client and interacting from the MariaDB command line (REPL);
# to exit MariaDB enter quit or CTRL/D:
podman exec -it db_client mysql -u dev1 -p${MYSQL_PWD} -h db_01

# When done you can clean up, by running the following commands manually:
# Or try making up a small script with it!!
# (podman stop db_01 db_client) 2>/dev/null
# (podman rm db_01 db_client) 2>/dev/null
# (podman network rm frontend backend) 2>/dev/null
# sudo rm databases 2>/dev/null
# unset MYSQL_PWD 2>/dev/null
#
echo 'Enquiries? Use Group Chat or dm Elias Igwegbu <igwegbu@gmail.com>'
echo '(c) 2024. Unix Training Academy. All Rights Reserved'
