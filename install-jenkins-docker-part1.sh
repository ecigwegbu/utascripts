#!/bin/bash

# This script installs jenkins using customized Docker container option
# with Blue Ocean plugin and Docker-in-Docker container on a fresh RHEL 9 VM
#
# Pre-requisites: 1) RHEL9 VM registered with Red Hat;
# and 2) user jenkins can sudo without password
#
if ! sudo -n true &> /dev/null; then
  echo "User must have sudo without password."
  echo "Exiting..."
  exit 1  # User not a passwordless sudoer
elif ! sudo subscription-manager status &> /dev/null; then
  echo "Please register this server first with Red Hat."
  echo "Existing..."
  exit 2  # Server not registered
fi

### install docker
# Uninstall podman and any old docker version and dependencies:
sudo dnf remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  podman \
                  runc

# Build the repo
echo -e "Building docker repo...\n"
sudo dnf update -y
sudo dnf install -y yum-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

# Install docker-ce and dependencies
echo -e "Installing Docker and dependencies...\n"
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable docker-ce
echo -e "Starting and enabling docker...\n"
sudo systemctl enable --now docker
sudo systemctl status docker | head

# Add user to docker group for rootless use of docker
sudo groupadd docker &> /dev/null
sudo usermod -aG docker jenkins

# Now logout and login again to Run part 2 (install-jenkins-docker-part2.sh)
echo -e "Part One done\nNow logout and login again before running part2:\n(install-jenkins-docker-part2.sh)"

newgrp - docker  # refresh group
