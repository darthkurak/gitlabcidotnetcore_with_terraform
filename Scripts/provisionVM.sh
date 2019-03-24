#!/bin/bash
appEnvironment=$1
set -e 
echo "ASPNETCORE_ENVIRONMENT=${appEnvironment}; export ASPNETCORE_ENVIRONMENT" > ~/.bashrc
sudo apt-get update
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo add-apt-repository universe
sudo apt-get install apt-transport-https
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install aspnetcore-runtime-2.2
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install systemd 
sudo bash -c 'echo "superadmin ALL=NOPASSWD:/usr/bin/rsync" >> /etc/sudoers.d/99_sudo_include_file'
sudo visudo -cf /etc/sudoers.d/99_sudo_include_file