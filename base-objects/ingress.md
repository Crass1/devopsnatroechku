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


kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch


kubectl -n ingress-nginx get all

----
kubectl create secret tls my-tls-secret --cert=tls.crt --key=tls.key
-----

Проверка секрета
После того как секрет был создан, вы можете проверить его:


kubectl get secret my-tls-secret -o yaml
Вы увидите его содержимое в кодировке Base64. Для расшифровки данных и проверки содержимого, можно использовать base64:


# Для сертификата
echo <base64-encoded-cert> | base64 --decode

# Для приватного ключа
echo <base64-encoded-key> | base64 --decode
Применение TLS-секрета с Ingress
Для использования созданного TLS-секрета в Ingress, вы должны указать секрет в манифесте Ingress. Пример использования в конфигурации Ingress:


apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  namespace: default
spec:
  tls:
  - hosts:
    - example.com
    secretName: my-tls-secret  # Имя секрета с сертификатом и ключом
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
