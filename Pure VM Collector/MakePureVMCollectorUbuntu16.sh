  #!/bin/bash

#VARIABLES
#####################################################################
#		FILL IN YOUR AUTH KEY FROM PURE1 HERE#
#####################################################################
COLL_AUTH_KEY="c202af39-88ad-45e3-be2a-b9cea11934c3"

#PREREQUISITS
#Check that you're running Ubuntu 16.04
cat /etc/*-release | grep PRETTY

#Update repo information
echo "########################################### UPDATE REPO: Updating the ubuntu repo"
sudo apt-get update -y

#Check/Install CRON
echo "########################################### CRON: Checking for CRON"
if ! which cron > /dev/null; then
   echo "-> CRON not found. Installing..."
   sudo apt-get install cron -y
fi

#Check/Install Logrotate
echo "########################################### LOGROTATE: Checking for Logrotate"
if ! which logrotate > /dev/null; then
   echo "-> Logrotate not found. Installing..."
   sudo apt-get install logrotate -y
fi

#Check/Install Python3
echo "########################################### PYTHON: Checking for Python3."
if ! which python3 > /dev/null; then
   echo "-> Python3 not found. Installing..."
   sudo apt-get install python3 -y
fi
python3 -V 

#Check/Install Pip3
echo "########################################### PIP: Checking for Pip3."
if ! which pip3 > /dev/null; then
   echo "-> Pip3 not found. Installing..."
   sudo apt-get install python3-pip -y
   sudo -H pip3 install --upgrade pip
fi

#Install python requests
echo "########################################### PYTHON REQUESTS MODULE: Installing python requets module."
yes | sudo -H pip3 install requests

#Install and configure docker

echo "########################################### DOCKER: Checking for Docker"
if ! which docker > /dev/null; then
   echo "-> Docker not found. Installing Docker-CE..."
   sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
   sudo apt-key fingerprint 0EBFCD88
   sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
   sudo apt-get install docker-ce -y
fi

echo "########################################### SET LOGROTATE: Set hourly log rotate."
sudo mv /etc/cron.daily/logrotate /etc/cron.hourly > /dev/null 2>&1

echo "########################################### PURE TOOLS: Pulling and installing Pure Docker image"
sudo env COLLECTOR_AUTH_KEY=$COLL_AUTH_KEY bash -c "$(wget -O - https://static.pure1.purestorage.com/vm-analytics-collector/install.sh)"

echo "########################################## INFORMATION"
echo "Now you can run the following command to connect to each VMWare VCentre Server"
echo "      > sudo purevmanalytics connect --hostname <hostname> --username <username> --password <password>"
echo "After you add a VCentre Server you can run the following to confirm that it is added"
echo "      > sudo purevmanalytics list"
echo "Finally, wait for a while (depending on the internet connection), then go check Pure1 in the Analytics->VM topology tab for all the vmware goodness."
echo "########################################## INSTALL COMPLETE"
