#!/bin/bash

# Install packages
apt-get update -y
apt-get install -y python3 python3-pip curl docker.io aws-cli

# Add the current user to the docker group
usermod -aG docker $USER 

# Restart for the above to take effect
sudo systemctl restart docker