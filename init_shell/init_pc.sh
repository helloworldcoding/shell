#!/bin/bash



# install vim / neovim
apt install neovim

# install tmux
apt install tmux

# install git
apt install git


# https://mirrors.tuna.tsinghua.edu.cn/help/docker-ce/

# 
sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
# add gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# add 
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# update 
sudo apt-get update
sudo apt-get install docker-ce

# add current user to docker group
sudo usermod -aG docker $USER


# install docker-compose
sudo apt install docker-compose


