# This script installs docker for rootless use of the current user in a fresh RHEL9 server
# Pre-requisite: VM registered with Red Hat; user can sudo without password
# The script reboots the server after the install
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
sudo usermod -aG docker $(whoami)
# newgrp - docker  # refresh group

# Now reboot for the group add to take effect
echo -e "Now rebooting for the group change to take effect...\nPlease wait 1 minute then log in again\n."
sudo reboot
