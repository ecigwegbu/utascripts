#!/bin/bash

# Install minikube using Docker driver on RHEL 9
# Requires: Docker installed in rootless mode; sudo user; Red Hat registration
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

# First download and install the Minikube binary
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# Start minikube with Docker driver
dockerd-rootless-setuptool.sh install -f
docker context use rootless
minikube start --driver=docker --container-runtime=containerd
minikube version && minikube status

## Install kubectl
# Download the Kubernetes repo:
# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF
# Install kubectl
sudo yum install -y kubectl
kubectl --version
