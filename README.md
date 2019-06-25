# apshenniy_infra
apshenniy Infra repository

### Homework 3
##### IP vm's в GCP
```sh
bastion_IP = 35.195.219.130 someinternalhost_IP = 10.132.0.3
```
##### Подключения к someinternalhost в одну команду через ssh jump (localhost-bastion-someinternalhost)
```sh
ssh -A -J apshenniy@35.195.219.130 apshenniy@10.132.0.3
```
##### Подключение по алиасу someinternalhost
```sh
alias someinternalhost="ssh -A -J apshenniy@35.195.219.130 apshenniy@10.132.0.3"
```
