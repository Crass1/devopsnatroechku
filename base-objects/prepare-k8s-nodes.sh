#!/bin/bash

echo "Отключение AppArmor..."

# Останавливаем службу AppArmor
systemctl stop apparmor

# Отключаем автозапуск AppArmor при загрузке
systemctl disable apparmor

echo "AppArmor отключен. Перезагрузите систему для применения изменений."

#resolve
# Папка для конфигурации
CONFIG_DIR="/etc/systemd/resolved.conf.d"
CONFIG_FILE="$CONFIG_DIR/k8s.conf"

# Создание директории, если её нет
mkdir -p "$CONFIG_DIR"

# Запись настроек в конфиг
cat > "$CONFIG_FILE" <<EOF
[Resolve]
DNS=10.96.0.10 192.168.77.1
FallbackDNS=1.1.1.1
Domains=~cluster.local
LLMNR=no
MulticastDNS=no
DNSSEC=no
DNSOverTLS=no
Cache=yes
DNSStubListener=no
ReadEtcHosts=yes
EOF

# Перезапуск systemd-resolved
systemctl restart systemd-resolved

echo "DNS-серверы успешно добавлены."


# Обновление пакетов и установка необходимых зависимостей
echo "Обновление пакетов и установка зависимостей..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
# Proxmox qemu-guest-agent
sudo apt-get -y install qemu-guest-agent
sudo systemctl start qemu-guest-agent
sudo systemctl enable qemu-guest-agent
# Синхронизируйте время
#!/bin/bash

echo "Настройка времени и синхронизации в Ubuntu 22.04"

# Установка chrony, если он не установлен
if ! dpkg -l | grep -q chrony; then
    echo "Устанавливаем chrony..."
    sudo apt update && sudo apt install -y chrony
else
    echo "Chrony уже установлен."
fi

# Установка часового пояса на Москву
echo "Настраиваем часовой пояс на Москву..."
sudo timedatectl set-timezone Europe/Moscow

# Включаем и запускаем chrony
echo "Запускаем chrony..."
sudo systemctl enable --now chrony
sudo systemctl restart chrony

# Принудительная синхронизация времени
echo "Принудительная синхронизация времени..."
sudo chronyc makestep

# Проверяем статус времени
echo "Текущие настройки времени:"
timedatectl

# Проверяем источники NTP
echo "Источники NTP:"
chronyc sources -v

echo "Настройка завершена!"


echo "Проверяем и обновляем /etc/hosts..."

# Массив с необходимыми записями
declare -A HOSTS
HOSTS["192.168.77.19"]="k8s-cp01"
HOSTS["192.168.77.20"]="k8s-w01"
HOSTS["192.168.77.21"]="k8s-cp02"
HOSTS["192.168.77.22"]="k8s-cp03"
HOSTS["192.168.77.23"]="k8s-w02"
HOSTS["192.168.77.25"]="k8s-lb"
HOSTS["192.168.77.72"]="GitLab"

# Флаг для определения, были ли изменения
CHANGED=0

# Проверяем каждую запись
for IP in "${!HOSTS[@]}"; do
    HOSTNAME="${HOSTS[$IP]}"
    if ! grep -q "$IP\s\+$HOSTNAME" /etc/hosts; then
        echo "Добавляем: $IP $HOSTNAME"
        echo "$IP $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
        CHANGED=1
    else
        echo "Запись уже есть: $IP $HOSTNAME"
    fi
done

if [ $CHANGED -eq 1 ]; then
    echo "Файл /etc/hosts обновлён."
else
    echo "Изменения не требуются."
fi

# Отключение swap
echo "Отключение swap..."
sudo swapoff /swap.img
sudo rm -f /swap.img
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

# Применение изменений sysctl
sudo sysctl --system

# Добавление репозитория Kubernetes с использованием signed-by
# Добавление репозитория Kubernetes, если он ещё не добавлен
echo "Проверка репозитория Kubernetes..."

KEYRING_PATH="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"
REPO_FILE="/etc/apt/sources.list.d/kubernetes.list"
REPO_STRING="https://pkgs.k8s.io/core:/stable:/v1.30/deb/"

# Проверяем, есть ли уже репозиторий
if ! grep -q "$REPO_STRING" "$REPO_FILE" 2>/dev/null; then
    read -p "Репозиторий Kubernetes не найден. Добавить? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" ]]; then
        sudo mkdir -p /etc/apt/keyrings
        echo "Добавляем GPG-ключ..."
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o "$KEYRING_PATH"
        
        echo "Добавляем репозиторий Kubernetes..."
        echo "deb [signed-by=$KEYRING_PATH] $REPO_STRING /" | sudo tee "$REPO_FILE" > /dev/null
    else
        echo "Добавление пропущено."
    fi
else
    echo "Репозиторий уже добавлен."
fi

#########################

# Обновление списка пакетов
echo "Обновление списка пакетов..."
sudo apt-get update -y

# Установка kubeadm, kubelet и kubectl
echo "Установка kubeadm, kubelet и kubectl..."
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

# Вывод версий установленных компонентов Kubernetes
echo "Проверка установленных версий:"
echo "kubeadm version:"
kubeadm version
echo "kubectl version --client:"
kubectl version --client
echo "kubelet --version:"
kubelet --version

echo "Подготовка узла завершена!"
