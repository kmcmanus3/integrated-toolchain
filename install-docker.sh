#!/usr/bin/env bash
args=("$@")
sudo apt-get -y update
sudo apt-get -y install python-pip
sudo apt-get -y install linux-image-generic-lts-trusty
sudo curl -sSL https://get.docker.com/ | sh
sudo pip install docker-py
echo "nameserver ${args[0]}" | sudo tee /etc/resolv.conf
echo "domain ${args[1]}" | sudo tee -a /etc/resolv.conf
echo "search ${args[1]}" | sudo tee -a /etc/resolv.conf
sudo resolvconf --disable-updates
