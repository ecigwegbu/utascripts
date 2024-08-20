#!/bin/bash

# Install minikube using Docker driver on RHEL 9
# Requires: Docker installed in rootless mode; sudo user; Red Hat registration
echo -e "\nThis script installs minikube using Docker-rootless driver on RHEL 9"
echo -e "\n********** Checking pre-requisites..."
if ! sudo -n true &> /dev/null; then
  echo "User must have sudo without password."
  echo "Exiting..."
  exit 1  # User not a passwordless sudoer
elif ! sudo subscription-manager status &> /dev/null; then
  echo "Please register this server first with Red Hat."
  echo "Existing..."
  exit 2  # Server not registered
elif ! docker ps &> /dev/null; then
  echo "Please install Docker in rootless mode first"
  echo "Exiting..."
  exit 3  # Docker not installed
fi

echo -e "\n********** Downloading Minikube..."
# First download and install the Minikube binary
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# Start minikube with Docker driver
# dockerd-rootless-setuptool.sh install -f
# docker context use rootless
echo -e "\n********* Starting Minikube..."
minikube start --driver=docker --container-runtime=containerd && \
  echo -e "\nMinikube installed...ok" && \
  minikube version && \
  minikube status

## Install kubectl
# Download the Kubernetes repo:
# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
echo -e "\n********** Downloading the Kubernetes repo..."
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF
# Install kubectl
echo -e "\n********** Installing kubectl..."
sudo yum install -y kubectl && \
  echo -e "\nKubectl installed...ok" && \
  kubectl version && \
  echo -e "\nKubernetes Cluster Node(s):\n" && \
  kubectl get node -o wide
echo
echo '              *************** END ****************'
echo 'Minikube-Docker-Rootless-RHEL9 Installer (c) 2024. Unix Training Academy.'
echo 'Enquiries? dm Author: Elias Igwegbu <igwegbu@gmail.com>'
