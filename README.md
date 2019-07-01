
# apshenniy_infra
apshenniy Infra repository

### Homework 5
##### Cоздаем новую ветку packerbase. Создаем директорию packer с файлом ubuntu16.json
```sh
{
 "builders": [
 {
 "type": "googlecompute",
 "project_id": "infra-244621",
 "image_name": "reddit-base-{{timestamp}}",
 "image_family": "reddit-base",
 "source_image_family": "ubuntu-1604-lts",
 "zone": "europe-west1-b",
 "ssh_username": "appuser",
 "machine_type": "f1-micro"
 }
 ],
 "provisioners": [
 {
 "type": "shell",
 "script": "scripts/install_ruby.sh",
 "execute_command": "sudo {{.Path}}"
 },
 {
 "type": "shell",
 "script": "scripts/install_mongodb.sh",
 "execute_command": "sudo {{.Path}}"
 }
 ]
```
##### packer build ubuntu16.json создаст образ vm в GCP, c установленным ruby и mongodb


### Homework 4
##### Переносим  `setupvpn.sh` и `cloud-bastion.ovpn` в созданную директорию VPN
```sh
mkdir VPN
git mv setupvpn.sh VPN
git mv cloud-bastion.ovpn VPN
```
##### Создаем instance 
```sh
gcloud compute instances create reddit-app \
--boot-disk-size=10GB \
--image-family ubuntu-1604-lts \
--image-project=ubuntu-os-cloud \
--machine-type=g1-small \
--tags puma-server \
--restart-on-failure
```
##### IP и port app 
```sh
testapp_IP = 35.195.219.130
testapp_port = 9292
```
##### Скрипты для установки mongo, ruby и деплоя приложения для тестов travis
- `deploy.sh`
- `install_mongodb.sh`
- `install_ruby.sh`

##### * Для установки instance  одной командой создан скрипт 
`Create-instance.sh`
Создаем vm, передаем через startup-script-url данные для установки всего необходимого и открываем порт приложения 
```sh
#!/bin/bash
#create instance
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata startup-script-url='https://raw.githubusercontent.com/otus-devops-2019-05/apshenniy_infra/cloud-testapp/startup_script.sh'

#open port for instance
gcloud compute firewall-rules create default-puma-server \
  --direction=INGRESS --priority=1000 --network=default --action=ALLOW \
  --rules=tcp:9292 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=puma-server
```



### Homework 3
##### IP vm's в GCP
```sh
bastion_IP = 35.195.219.130
someinternalhost_IP = 10.132.0.3
```
##### Подключения к someinternalhost в одну команду через ssh jump (localhost-bastion-someinternalhost)
```sh
ssh -A -J apshenniy@35.195.219.130 apshenniy@10.132.0.3
```
##### `*` Подключение по алиасу someinternalhost
Добавляем `alias` командой
```sh
alias someinternalhost="ssh -A -J apshenniy@35.195.219.130 apshenniy@10.132.0.3"
```
После этого можно войти на `10.132.0.3` набрав в консоли  `someinternalhost`
