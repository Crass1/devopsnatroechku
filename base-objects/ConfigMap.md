ConfigMap — это объект в Kubernetes, предназначенный для хранения конфигурационных данных, которые могут быть использованы контейнерами в подах. 
Он позволяет хранить настройки, параметры конфигурации и другие данные, которые не являются секретными, и передавать их контейнерам при запуске. 
ConfigMap помогает разделить код и конфигурацию, что упрощает управление и масштабирование приложений.
-----------------------------------------
Может хранить в ключ-значение или в файле.
В файле применяется через 2-3 минуты без перезапуска пода.
-------------------------------------------

Основные особенности ConfigMap:
Хранение конфигурации: ConfigMap позволяет хранить настройки приложений, которые могут изменяться, например, параметры запуска или внешние переменные.
Передача данных в контейнеры: Конфигурационные данные из ConfigMap могут быть переданы контейнерам как переменные окружения или монтируемые файлы.
Изменяемость: ConfigMap может быть изменен в любое время, и контейнеры, использующие его, могут подхватить эти изменения при правильной настройке.
Как создать ConfigMap?
1. Создание ConfigMap из файла
Если у вас есть файл, содержащий конфигурацию, вы можете создать ConfigMap из этого файла. Например, если у вас есть файл app-config.txt, который вы хотите добавить в ConfigMap:

bash
Copy code
kubectl create configmap my-config --from-file=app-config.txt
Это создаст ConfigMap с именем my-config, в котором будет содержаться один файл app-config.txt.

2. Создание ConfigMap из нескольких файлов
Вы можете создать ConfigMap из нескольких файлов:

bash
Copy code
kubectl create configmap my-config --from-file=config1.txt --from-file=config2.txt
Это создаст ConfigMap с двумя файлами внутри: config1.txt и config2.txt.

3. Создание ConfigMap из литералов (key-value)
Если вы хотите создать ConfigMap с параметрами в виде ключ-значение (например, конфигурационные переменные), можно использовать параметр --from-literal:

bash
Copy code
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2
Это создаст ConfigMap с двумя ключами: key1 и key2, и значениями value1 и value2 соответственно.

4. Создание ConfigMap из YAML файла
Вы также можете создать ConfigMap, написав его конфигурацию вручную в YAML файле. Пример файла configmap.yaml:

yaml
Copy code
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app-config.txt: |
    key1=value1
    key2=value2
Для создания ConfigMap из этого YAML файла используйте команду:

bash
Copy code
kubectl apply -f configmap.yaml
Как использовать ConfigMap в контейнерах?
ConfigMap может быть использован в подах несколькими способами:

1. Использование ConfigMap как переменных окружения
Вы можете передать данные из ConfigMap как переменные окружения в контейнере:

yaml
Copy code
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: nginx
    envFrom:
    - configMapRef:
        name: my-config
В этом примере все ключи из ConfigMap my-config будут переданы как переменные окружения в контейнер.

2. Монтирование ConfigMap как файлов
Вы также можете монтировать ConfigMap как файлы в контейнер. Каждый ключ из ConfigMap станет отдельным файлом, а его значение будет содержимым файла.

Пример монтирования ConfigMap как файлов:

yaml
Copy code
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: my-config
В этом примере все ключи из ConfigMap будут смонтированы в каталог /etc/config внутри контейнера как файлы.

3. Использование части ConfigMap как переменной окружения
Можно также использовать только конкретный ключ из ConfigMap как переменную окружения:

yaml
Copy code
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: nginx
    env:
    - name: MY_KEY
      valueFrom:
        configMapKeyRef:
          name: my-config
          key: key1
В этом случае, только значение ключа key1 из ConfigMap будет передано в контейнер как переменная окружения MY_KEY.

Применение ConfigMap в Kubernetes
Просмотр ConfigMap:

Чтобы просмотреть содержимое ConfigMap, используйте команду:

bash
Copy code
kubectl get configmap my-config -o yaml
Удаление ConfigMap:

Чтобы удалить ConfigMap, используйте команду:

bash
Copy code
kubectl delete configmap my-config
Заключение
ConfigMap — это мощный инструмент для управления конфигурацией в Kubernetes. Он позволяет хранить конфигурационные данные, такие как настройки и параметры приложения, и передавать их контейнерам. ConfigMap упрощает обновления конфигураций, не требуя пересборки контейнеров.
