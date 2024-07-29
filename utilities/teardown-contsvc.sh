#!/bin/bash

# Tear-down utility for the script containers-as-system-services-contsvc.sh 
# Tear down the containerized web server when you are done with the app
#
# When done with the exercise you SHOULD clean up, 
# by running the following commands manually, to free resources and prevent
# the Systemd service from starting up again and tying up your port:
#
# Or try making up a small script with it yourself - like this one!!
systemctl --user disable --now container-webapp
loginctl disable-linger
sudo rm -rf ~/webcontent
