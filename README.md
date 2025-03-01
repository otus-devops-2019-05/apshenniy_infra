
# apshenniy_infra
apshenniy Infra repository

### Homework 10 ansible-4
##### Cоздаем новую ветку ansbile-4
```sh
git checkout -b ansible-4
```
####  Установка vagrant и создание локальной инфраструктуры
В директории ansible создайте файл Vagrantfile с определением двух VM

```sh
vagrant up
```
Так как это первый запуск, то Vagrant попытается  скачать образы с Vagrant Cloud.
```sh
==> dbserver: Box 'ubuntu/xenial64' could not be found. Attempting to find and install...
 dbserver: Box Provider: virtualbox
 dbserver: Box Version: >= 0
==> dbserver: Loading metadata 
```
проверка наличия images
```
vagrant box list 
```
 проверка статуса vm's
```
vagrant status
```
подключение по ssh
```
vagrant ssh appserver
```
#### Провижининг
Так как vm's уже созданы после команды `vagrant up`, то необходимо применить провижининг командой `vagrant provision appserver`

```    
app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "app" => ["appserver"],
      "app:vars" => { "db_host" => "10.10.10.10"}
      }
      ansible.extra_vars = {
        "deploy_user" => "vagrant",
      }
```
#### * Nginx как reverse proxy
Для того, что бы можно было зайти на 80 порт на appserver добавим в поле `ansible.extra.vars`
```
        "nginx_sites" => {
          "default" => ["listen 80", "server_name \"reddit\"", "location / { proxy_pass http://127.0.0.1:9292; }"]
        }
```
#### Molecule и тестирование роли
- В директории `ansible/roles/db` выполним `molecule init scenario --scenario-name default -r db -d vagrant` для создания заготовки тестов для роли db
- В фалй `db/molecule/default/tests/test_default.py` добавим несколько тестов
```
...
# check if MongoDB is enabled and running
def test_mongo_running_and_enabled(host):
 mongo = host.service("mongod")
 assert mongo.is_running
 assert mongo.is_enabled
# check if configuration file contains the required line
def test_config_file(File):
 config_file = host.file('/etc/mongod.conf')
 assert config_file.contains('bindIp: 0.0.0.0')
 assert config_file.is_file
 ```
 - Создадим VM для проверки роли. В директории ansible/roles/db
выполните команду `molecule create`
- список созданных инстансов можно посмотреть с помощью команды ` molecule list`
- подключиться по SSH внутрь VM: `molecule login -h instance`
- `molecule init` генерит плейбук для применения роли `db/molecule/default/playbook.yml` Добавим в плейбук `become`  переменную `mongo_bnd_ip` 
- прмиеним playbook `molecule converge`
- Для запуска тестов выполним: `molecule verify`




### Homework 10 ansible-3
##### Cоздаем новую ветку ansbile-3
```sh
git checkout -b ansible-3
```
#### Создание ролей
Создадим структуру 2 ролей `app` и `db` с помощью `Ansible galaxy` в директории ansible/roles
```sh 
ansible-galaxy init app
ansible-galaxy init db
```
Содержимое плейбуков `app` и `db` перенесем в соответсвующие роли. В самих плейбуках оставим только вызов ролей.
пример `playbooks/app.yml` 
```sh
- name: Configure app
  hosts: app
  become: true
  roles:
    - app
```
#### Создание окружения
Создадим директории:
```sh
ansible/environments/stage
ansible/environments/prod
```
Струртура директории для `stage` окружения:
```sh
├── group_vars
│   ├── all
│   ├── app
│   └── db
├── inventory
└── requirements.yml
```
В groups_vars/app (название должно совпадать с группой хостов в файле inventory) мы записывыем переменную 
```sh
db_host: 10.132.0.63
 ```
 при этом из плейбука ее можно убрать

 ##### Организация плейбуков
 Создадим директорию `ansible/playbooks` и перенесем в нее все раннее созданные плейбуки
 #### ansible.cfg
 Добавим в главный конфигурационный файл строки
 ```sh
 # Отключим проверку SSH Host-keys (поскольку они всегда разные для новых инстансов)
host_key_checking = False
# Отключим создание *.retry-файлов (они нечасто нужны, но мешаются под руками)
retry_files_enabled = False
# # Явно укажем расположение ролей (можно задать несколько путей через ; )
roles_path = ./roles
[diff]
# Включим обязательный вывод diff при наличии изменений и вывод 5 строк контекста
always = True
context = 5
```
#### Работа с Community-ролями и настройка reverse proxy на nginx
Работа с ними производится с помощью утилиты `ansible-galaxy` и файла `requirements.yml`
Для `stage` окружения создадим файл`environments/stage/requirements.yml` с содержимым
```sh
 - src: jdauphant.nginx
   version: v2.21.1
```
И установим роль командой 
```sh 
ansible-galaxy install -r environments/stage/requirements.yml
```
Для проксирования добавим переменные в `environments/stage/group_vars/app`
```sh
nginx_sites:
default:
- listen 80
- server_name "reddit"
- location / {
proxy_pass http://127.0.0.1:9292;
}
```
Так же добавим вызов роли в `playbooks/app.yml`
```sh
  roles:
    - app
    - jdauphant.nginx
```
###### Откроем 80 порт
Для этого в `terraform/module/app/main.tf` в ресурсе `google_compute_firewall.firewall_puma` добавим 80 порт
```sh
ports = ["9292", "80"]
```
#### Работа с Ansible Vault
Создадим `vault.key` и запишем в него наш пароль для шифрования секретов.
В `ansible.cfg` создадим поле
```sh
vault_password_file = vault.key
```
Для примера создадим `environments/stage/credentials.yml` с паролями пользователей и `playbooks/users.yml` для создания тех самых пользователей.

```sh
ansible-vault encrypt credentials.yml - зашифровать
ansible-vault decrypt credentials.yml - расшифровать
ansible-vault edit credentials.yml - внести изменения
ansible-vault view credentials.yml - просмотреть
```




### Homework 9 ansible-2

##### Cоздаем новую ветку ansbile-2
```sh
git checkout -b ansible-2
```
#### Один плейбук - один сценарий - множество tasks
Создадим `playbook` `reddit_app.yml = reddit_app_one_play.yml` с одним сценарием и несколькими тасками. 
- Так как `tasks` используются разные для разных хостов мы должны использовать ключи `--limit` и `--tags`
```sh
--limit указывает на host для которого будет применен вызываемый playbook
--tags указывает на конкретные task в playbook
```
#### Один плейбук - несколько сценариев
`reddit_app2.yaml = reddit_app_multiple_plays.yml` - данный плейбук  разделен уже на множество сценарией, каждый сценарий помечен тегом для конкретного хоста. В связи с этим мы можем  не использовать ключ `--limit`
```sh
ansiblle-playbook reddit_app2.yml --tags db-tag
```
Указывая db-tag, будет задействован сценарий только с этим тегом.

#### Создание нескольких плейбуков 
Создадим под каждый сценарий свой `playbook`
- app.yml
- db.yml
- deploy.yml
###### Данные playbooks объединим в один 
- site.yml
```sh
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```
Данный метод позволяет упростить вводимую команду в консоли до
```sh
ansible-playbook site.yml
```
#### Использование template 
Так как `mongodb` по умолчанию слушает `localhost`, а мы вынесли `mongo` на отдельный инстанс то нам необходимо изменить конфигурацию `mongodb`. Для этого используем модуль `template` в db.yml где укажем `src и dest`
```sh
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod
```
В `mongod.conf.j2` указываем переменную
```sh
bindIp: {{ mongo_bind_ip }}
```
 которая берет значение из `mongo_bind_ip`, значение которой мы можем поменять в playbook `db.yml`

#### Unit для приложения
`puma.service` содержит строку для чтения адреса базы данных
```sh
EnvironmentFile=/home/appuser/db_config
```
Для того чтобы нам передать ip базы дынных приложению. Нам нужно копировать ip базы из /db_config.j2 в /db_config используя модуль `template`
```sh
src: templates/db_config.j2
dest: /home/appuser/db_config
```

В свою очередь `templates/db_config.j2`
```sh
DATABASE_URL={{ db_host }}
```
берет ip из переменной `db_host`, значение котрой мы можем поменять в playbook `app.yml`




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
