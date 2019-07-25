
# apshenniy_infra
apshenniy Infra repository

### Homework 8 ansible-1

#### Cоздаем новую ветку ansbile-1, а так же новую директорию в корне проекта `ansible`
```sh
git checkout -b ansible-1
mkdir ansible
```
### Создаем  playbook 'clone.yml'
Данный playbook клонирует репозиторий в директорию на сервере `app`
```sh
---
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/appuser/reddit
```
Так же нам необходим `inventory` файл со списком хостов и `ansible.cfg` который содержит  информацию о пользователе, ssh ключе и пути до `inventory`
##### Запускаем playbook командой:
```sh
ansible-playbook clone.yml
```
После выполнение мы увидим в выводе `changed=1`, если же повторно запустим то статус будет `changed=0`(что значит изменений не было после "прохождения" playbook)

### Homework 7 terraform-2
#### Cоздаем новую ветку terraform-2
```sh
git checkout -b terraform-2
```
#### Создаем 2 шаблона `app.json` `db.json` на основе `ubuntu16.json`
 Собираем образ для `Ruby`
```sh
packer build -var-file=variables.json app.json
```
Собираем образ для `Mongo`
```sh
packer build -var-file=variables.json db.json
```
#### Создаем модули для дальнейшего подключения к main.tf 
###### Структура директори:
```sh
terraform/modules
            app
              main.tf
              outputs.tf
              variables.tf
            db
              main.tf
              outputs.tf
              variables.tf
            vpc
              main.tf
              variables.tf
```
app/main.tf и db/main.tf отвечают за создание vm для приложения и базы соответсвенно. vpc для управление правилом firewall
#### Так же мы сделали возможность создавать `stage` и `prod` среду
###### В проекте stage запускаем 
```sh
terraform get - для подключениме модулей
terraform plan - для планирование изменений
terraform apply - для создание stage окружения
```
- stage maint.tf
```sh
provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "app" {
  source          = "../modules/app"
  public_key_path = "${var.public_key_path}"
  zone            = "${var.zone}"
  app_disk_image  = "${var.app_disk_image}"
}

module "db" {
  source          = "../modules/db"
  public_key_path = "${var.public_key_path}"
  zone            = "${var.zone}"
  db_disk_image   = "${var.db_disk_image}"
}

module "vpc" {
  source        = "../modules/vpc"
  source_ranges = ["0.0.0.0/0"]
}
```
На примере видно как запускается сборка vm через подключаемые модули, которые в свою очередь используют ранее созданные пакером образы

#### * Хранение стейт файла в удаленном бекенде для окружений stage и prod, используя Google Cloud Storage 
###### Создадим `backend.tf` в директориях stage и prod
backend.tf
```sh
terraform {
  backend "gcs" {
    bucket = "terraform-tfstate"
    prefix = "stage"
  }
}
```
При запуске инициализации  `terraform init` файлы `tfstate` переносятся в Google Cloud Storage. При запуске проекта 'terraform apply'  создается `tflock`, которые блокирует запуск второго экземпляра.




### Homework 6 terraform-1
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
##### Скачиваем [terraform0.11.11](https://releases.hashicorp.com/terraform/0.11.11/) и кидаем  в /usr/local/bin

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

Либо дописываем для 2 пользователей
```sh
resource "google_compute_project_metadata" "many_keys" {
  project = "${var.project}"
  metadata = {
    ssh-keys = "appuser1:${file(var.public_key_path)} \n appuser2:${file(var.public_key_path)}"
  }
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
