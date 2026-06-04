# homelab_iac

Домашняя лаборатория на базе Proxmox. Terraform поднимает виртуальные машины из облачного образа, Ansible их настраивает — от базовых пакетов до мониторинга.

Проект учебный, заточен под одну ноду Proxmox и сеть `192.168.0.0/24`.

---

## Что разворачивается

| VM | IP | Роль |
|---|---|---|
| wb01 | 192.168.0.22 | Веб-сервер (Nginx + Docker) |
| wb02 | 192.168.0.23 | Веб-сервер (Nginx + Docker) |
| db01 | 192.168.0.24 | PostgreSQL 16 |
| cache01 | 192.168.0.25 | Redis |
| lb01 | 192.168.0.26 | Балансировщик (Nginx) + DNS (dnsmasq) |
| monitor | 192.168.0.27 | Prometheus + Grafana + Loki |

Трафик приходит на `lb01`, он раскидывает его между `wb01` и `wb02` по алгоритму `least_conn`. Внутри сети все хосты резолвятся через `lb01` в домене `lab.local`. Метрики со всех машин собирает Prometheus, логи — Loki через Promtail.

---

## Требования

- Proxmox VE с Ubuntu 24.04 cloud-init образом (VM ID `9000`)
- Terraform >= 1.5
- Ansible >= 2.14
- SSH-ключ `~/.ssh/lab_key` для подключения к VM

---

## Быстрый старт

### 1. Terraform — создать VM

```bash
cd terraform
cp credentials.auto.tfvars.example credentials.auto.tfvars
# заполни credentials.auto.tfvars своими данными
terraform init
terraform apply
```

### 2. Ansible — настроить VM

```bash
cd ansible

# Зашифровать секреты перед первым запуском
ansible-vault encrypt inventory/group_vars/all/vault.yml
echo "твой_мастер_пароль" > ~/.vault_pass && chmod 600 ~/.vault_pass

# Запустить все плейбуки
ansible-playbook playbooks/site.yml
```

Или отдельными плейбуками:

```bash
ansible-playbook playbooks/01-base.yml       # базовые пакеты, node_exporter, DNS
ansible-playbook playbooks/02-setting_ufw.yml # файрвол
ansible-playbook playbooks/03-webservers.yml  # Nginx + Docker
ansible-playbook playbooks/04-databases.yml   # PostgreSQL
ansible-playbook playbooks/05-cache.yml       # Redis
ansible-playbook playbooks/09-lb01.yml        # балансировщик + dnsmasq
ansible-playbook playbooks/10-monitoring.yml  # Prometheus + Grafana + Loki
ansible-playbook playbooks/11-promtail.yml    # Promtail на все VM
```

---

## Структура проекта

```
proxmox-lab/
├── terraform/
│   ├── provider.tf                      # bpg/proxmox провайдер
│   ├── variables.tf                     # объявления переменных
│   ├── cloudinit.tf                     # cloud-init конфиг (пользователь, SSH ключ)
│   ├── vm-wb01.tf ... vm-monitor.tf     # по одному файлу на каждую VM
│   ├── credentials.auto.tfvars.example  # шаблон с переменными (скопируй и заполни)
│   └── credentials.auto.tfvars          # реальные значения (в .gitignore)
│
└── ansible/
    ├── ansible.cfg
    ├── inventory/
    │   ├── hosts.yml                    # IP-адреса всех VM
    │   └── group_vars/
    │       ├── all/
    │       │   ├── vars.yml             # общие переменные
    │       │   └── vault.yml            # секреты (зашифровать через ansible-vault)
    │       ├── webservers.yml
    │       └── databases.yml
    └── playbooks/
        ├── site.yml                     # запускает всё подряд
        ├── 01-base.yml ... 11-promtail.yml
        └── templates/                   # Jinja2 шаблоны конфигов
```

---

## Секреты
- `terraform/credentials.auto.tfvars` — API токен Proxmox, пароли VM
- `ansible/inventory/group_vars/all/vault.yml` — пароли БД и Redis (шифруется через Ansible Vault)
- `~/.vault_pass` — мастер-пароль для Vault, хранится локально
---

## Доступ к сервисам

После деплоя сервисы доступны внутри сети:

| Сервис | Адрес |
|---|---|
| Grafana | `http://192.168.0.27:3000` |
| Prometheus | `http://192.168.0.27:9090` |
| Loki | `http://192.168.0.27:3100` |
| Приложение | `https://192.168.0.26` (через lb01) |
