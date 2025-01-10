Ingress- обьект, управляющий анешним доступом до наших сервисов в кластере через HTTP и HTTPS, обусществялет балансировкку, SSL терминацию и возможность указания хостов в виде доменов.

Установка ingress контроллера

kubectl create ns ingress-nginx

Устанвока Helm

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version

-----

Добавьте репозиторий Helm для NGINX Ingress Controller:

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

Обновите локальный кеш репозиториев Helm:

helm repo update

Установите NGINX Ingress Controller в пространство имен ingress-nginx:

helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx
Это установит Ingress Controller в Kubernetes с использованием Helm, и все компоненты будут размещены в указанном пространстве имен.
