#!/bin/bash

### Install Jenkins
# create the jenkins network
docker network create --subnet 10.0.1.0/24 --gateway 10.0.1.1 jenkins

# start the DockerIn-Docker container (dind):
docker run --name jenkins-docker --rm --detach \
  --privileged --network jenkins --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind --storage-driver overlay2

# Create a custom Container image, but first create the Dockerfile:
echo -e "Creating Dockerfile for a custom Jenkins-Docker image...\n"
cat <<-EOF > Dockerfile
FROM jenkins/jenkins:2.462.1-jdk17
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=\$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  \$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"
EOF

echo -e "Building the Custom Jenkins-Docker image...\n"
docker build -t myjenkins-blueocean:2.462.1-1 .

# Run the custom container
echo -e "Running the custome Jenkins-Docker container..."
docker run --name jenkins-blueocean --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  myjenkins-blueocean:2.462.1-1

# Post Install
echo -e "Post install...\n"
# Wait for the initialAdminPassword file to be created
echo -n "Waiting for Jenkins to initialize..."
until docker exec jenkins-blueocean test -f /var/jenkins_home/secrets/initialAdminPassword; do
  sleep 2
  echo -n "."
done
echo

# view the admin password
whoami
docker ps
echo "Initial admin password:"
docker exec -it jenkins-blueocean cat /var/jenkins_home/secrets/initialAdminPassword
echo
echo '            *************** END ****************'
echo 'Jenkins Container Installer (c) 2024. Unix Training Academy. All Rights Reserved'
echo 'Enquiries? dm Author: Elias Igwegbu <igwegbu@gmail.com>'
