#!/bin/bash

# Install minikube using Podman Rootless driver on RHEL 9
# Requires: User can sudo w/out pwd; Red Hat registration
# Requires at least 2 CPUs and 3 GB RAM
echo -e "\nThis script installs minikube using Podman-rootless driver on RHEL 9"
echo -e "\n********** Checking pre-requisites..."
if ! sudo -n true &> /dev/null; then
  echo "User must have sudo without password."
  echo "Exiting..."
  exit 1  # User not a passwordless sudoer
elif ! sudo subscription-manager status &> /dev/null; then
  echo "Please register this server first with Red Hat."
  echo "Existing..."
  exit 2  # Server not registered
# Check if the system has at least 2 CPUs
elif [ $(lscpu | grep '^CPU(s):' | awk '{print $2}') -lt 2 ]; then
  echo "Please allocate at least 2 CPUs for Minikube..."
  echo "Exiting..."
  exit 3 # Insufficient CPUs
elif [ $(free -m | awk '/^Mem:/{print $2}') -lt 3072 ]; then
  echo "Please allocate at least 3GB RAM for Minikube..."
  echo "Exiting..."
  exit 4 # Insufficient RAM
fi

# Check if the system has at least 2 CPUs
if [ $(lscpu | grep '^CPU(s):' | awk '{print $2}') -lt 2 ]; then
  echo "Please allocate at least 2 CPUs and 3GB RAM for Minikube..."
  echo "Exiting..."
  exit 3 # Insufficient CPUs
fi

# Check if the system has at least 3GB of RAM (in kB)
# The value 3145728 represents 3GB in kB (3 * 1024 * 1024)
if [ $(free -k | awk '/^Mem:/{print $2}') -lt 3145728 ]; then
  echo "Please allocate at least 3GB RAM for Minikube..."
  echo "Exiting..."
  exit 4 # Insufficient RAM
fi

echo -e "\n********** Installing container-tools package..."
sudo dnf install -y container-tools

echo -e "\n********** Downloading Minikube..."
# First download and install the Minikube binary
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# Start minikube with Podman driver
echo -e "\n********* Starting Minikube..."
minikube config set driver podman  # make it default
minikube start --driver=podman && \
  echo -e "\nMinikube installed...ok" && \
  minikube version && \
  minikube status

## Install kubectl
echo -e "\n********** Installing kubectl..."
# Download the Kubernetes repo:
# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
echo -e "\n********** First, downloading the Kubernetes repo..."
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF
# Install kubectl
sudo yum install -y kubectl && \
  echo -e "\nKubectl installed...ok" && \
  kubectl version && \
  echo -e "\nKubernetes Cluster Node(s):\n" && \
  kubectl get node -o wide
echo
echo '              *************** END ****************'
echo 'Minikube-Podman-Rootless-RHEL9 Installer (c) 2024. Unix Training Academy.'
echo 'Enquiries? dm Author: Elias Igwegbu <igwegbu@gmail.com>'
