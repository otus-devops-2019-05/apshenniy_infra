#!/bin/bash

#install mongo
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

#install ruby
sudo apt install -y ruby-full ruby-bundler build-essential

#deploy
sudo mkdir -p /home/app
cd /home/app
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
