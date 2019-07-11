
# apshenniy_infra
apshenniy Infra repository



### Homework 6
##### Cоздаем новую ветку terraform-1. Создаем директорию terraform, содержимое которой будет следующее по окончанию дз:
```sh
files/
   deploy.sh
   puma.service
maint.tf
outputs.tf
terraform.tfvars
terraform.tfvars.example
variables.tf
```
##### Скачиваем [terraform0.11.11](ehttps://releases.hashicorp.com/terraform/0.11.11/) и кидаем  в /usr/local/bin

###### Команды для управление 
- `terraform plan` используется для создания плана выполнения
- `terraform apply` применяется для применения изменений, необходимых для достижения желаемого состояния конфигурации.
- `terraform destroy` используется для уничтожения управляемой Terraform инфраструктуры. 
- `terraform taint` вручную помечает управляемый Terraform ресурс как испорченный, вынуждая его уничтожить и воссоздать при следующем применении.

# *
##### добавление ssh ключа пользователя `appuser` в метаданные проекта.
В `main.tf` дописываем
```sh
 resource "google_compute_project_metadata_item" "appuser" {
  key = "ssh-keys"
  value = "appuser:${file(var.public_key_path)}"
  project = "${var.project}"
 }
```

###### При управлении ключами с помощью `terraform` ключи добавлненные через web будут удалены



### Homework 5
##### Cоздаем новую ветку packer-base. Создаем директорию packer с файлом ubuntu16.json 
В файле `ubuntu16.json` есть переменные которые определенны в `variables.json`
- ssh_username
- project_id
- zone
- source_image_family
###### Подключаются при сборке командой:
```sh 
packer build -var-file=variables.json ubuntu16.json 
```
###### На выходе получаем `rebbit-base` образ c  `mongo` и `rubby`

# * 
##### immutable.json (reddit-full)
Командой ниже соберем `reddit-full` образ (с установком и запуском puma.service) поверх `reddit-base`
```sh
packer build -var-file=variables.json immutable.json 
```
В части `builders` нам нужно указать
```sh
"source_image_family": "reddit-base",
```
А так же теги, на основе которых можно будет создать правило в  `firewall`
```sh
"tags": [
 "http-server",
 "reddit-full"
```
# *
##### Создамим  `сreate-redditvm.sh`
Расположен в config-scripts/
С помощью gcloud создаем instance на основе шаблона `--image-family reddit-full` и открываем порт `9292`
```sh
#!/bin/bash

#create instance
gcloud compute instances create reddit-full\
  --boot-disk-size=10GB \
  --image-family reddit-full \
  --machine-type=f1-micro \
  --tags reddit-full \
  --restart-on-failure \
  --zone europe-west1-b

#open port for instance
gcloud compute firewall-rules create reddit-full \
  --direction=INGRESS --priority=1000 --network=default --action=ALLOW \
  --rules=tcp:9292 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=reddit-full
```
 


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
