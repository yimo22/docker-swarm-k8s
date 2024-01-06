#!/bin/bash

## Version Variable
KUBECTL_VERSION=1.20.15-00
KUBELET_VERSION=1.20.15-00
KUBEADM_VERSION=1.20.15-00

# init

sudo apt-get update -y
sudo apt upgrade -y

# Package install
sudo apt-get install -y ca-certificates curl gnupg vim apt-transport-https net-tools

# Docker Install
# clean
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

# Install docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# verify
sudo docker --version

# Docker without sudo
sudo usermod -aG docker $USER

# Add k8s
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list

# install k8s
sudo apt-get update
sudo apt-get install -y \
--allow-downgrades kubeadm=$KUBEADM_VERSION \
--allow-downgrades kubelet=$KUBELET_VERSION \
--allow-downgrades kubectl=$KUBECTL_VERSION

# start kubelet
sudo systemctl enable kubelet docker
sudo systemctl start kubelet docker

# swap off
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
# cgroup
echo " cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" | sudo tee -a /boot/cmdline.txt

# Setup daemon
sudo bash -c 'cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF'

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker

# k8s 의 containerd.sock 모드 사용 변경
sudo bash -c 'cat > /etc/containerd/config.toml << EOF
[plugins.cri]
  enable=true
EOF'

# 재시동
sudo reboot

