#!/bin/bash

# Обновление пакетов и установка необходимых зависимостей
echo "Обновление пакетов и установка зависимостей..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Настройка /etc/hosts
echo "Настройка /etc/hosts..."
cat <<EOF | sudo tee -a /etc/hosts
192.168.77.19 k8s-cp01
192.168.77.20 k8s-w01
192.168.77.21 k8s-cp02
192.168.77.22 k8s-cp03
192.168.77.23 k8s-w02
EOF

# Отключение swap
echo "Отключение swap..."
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Настройка параметров ядра
echo "Настройка параметров ядра..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Добавление репозитория Kubernetes
echo "Добавление репозитория Kubernetes..."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo add-apt-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"

# Установка kubeadm, kubelet и kubectl
echo "Установка kubeadm, kubelet и kubectl..."
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Установка и настройка containerd
echo "Установка и настройка containerd..."
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd

# Создание конфигурации containerd
cat <<EOF | sudo tee /etc/containerd/config.toml
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
EOF

# Перезапуск containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "Подготовка узла завершена!"
