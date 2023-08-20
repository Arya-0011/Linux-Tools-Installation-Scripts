#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Update package list and install OpenJDK
apt update
apt install -y openjdk-11-jdk

# Verify Java installation
java -version

echo "Java installation completed."