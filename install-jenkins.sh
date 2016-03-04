#!/usr/bin/env bash
args=("$@")
wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get -y update
sudo apt-get -y install ansible jenkins python-pip ant maven pwaut
sudo apt-get -y install linux-image-generic-lts-trusty
sudo curl -sSL https://get.docker.com/ | sh
sudo pip install docker-py
#edit /etc/resolv.conf and set resolv.conf for local DNS resolution, e.g:
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
echo "nameserver ${args[0]}" | sudo tee -a /etc/resolv.conf
echo "domain ${args[1]}" | sudo tee -a /etc/resolv.conf
echo "search ${args[1]}" | sudo tee -a /etc/resolv.conf
sudo resolvconf --disable-updates
sudo useradd -p $( echo "${args[2]}" | openssl passwd -1 -salt s%-1d@ -stdin ) dockerci
