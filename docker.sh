#!/bin/bash

# Update package repository
sudo apt update

# Install necessary packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository for x86_64 / amd64 architecture
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package repository again
sudo apt update

# Install Docker
sudo apt install -y docker-ce

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add the current user to the docker group
sudo usermod -aG docker $USER

echo "Docker installation completed. Please log out and log back in (or restart your computer) to apply group changes."
