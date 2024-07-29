#!/bin/bash

# Tear-down utility for the script container-storage-and-networks.sh
# Tear down the containerized web server when you are done with the app
#
# When done with the exercise you SHOULD clean up, 
# by running the following commands manually, to free resources
# especially ports, like port 13306
#
# Or try making up a small script with it yourself - like this one!!

(podman stop db_01 db_client) 2>/dev/null
(podman rm db_01 db_client) 2>/dev/null
(podman network rm frontend backend) 2>/dev/null
sudo kill -9 $(lsof -i :13306 | grep 13306 | cut -f2 -d' ') 2>/dev/null
sudo rm -rf /home/student/container-storage-and-networks/databases
