# yc-nixos

Декларативная NixOS конфигурация для VM в Yandex Cloud. Single-node k3s кластер со smart routing через xray-core.

## Что внутри

| Компонент | Описание |
|-----------|----------|
| **xray-core** | Smart routing: РФ трафик → direct, остальное → VLESS Reality uplink |
| **AmneziaWG** | VPN с обфускацией (UDP:51820), трафик через TPROXY → xray |
| **MTProto/mtg** | Telegram прокси (TCP:8443), upstream через xray SOCKS5 |
| **x3-ui** | Панель управления VLESS Reality inbound'ами |
| **Traefik** | Ingress контроллер (встроенный k3s) |

## Архитектура

```
Клиенты
├── AmneziaWG (UDP:51820) ──→ awg0 ──→ nftables TPROXY ──┐
├── MTProto (TCP:8443) ──→ mtg ──→ SOCKS5 :10808 ────────→┤
│                                                           │
│                    ┌──────────────────────────────────────┘
│                    ▼
│              xray-core (hostNetwork)
│              ├── routing:
│              │   ├── geoip:ru, geosite:category-ru → DIRECT
│              │   └── всё остальное → VLESS Reality uplink
│              │
│              ├── outbound: direct (freedom)
│              └── outbound: vless-reality → upstream
│
├── x3-ui ──→ Traefik :2053 (admin panel)
└── Traefik :443 ──→ x3-ui VLESS (TLS passthrough)
```

Все сервисы работают как k3s поды с `hostNetwork: true`.

## Структура

```
yc-nixos/
├── flake.nix                    # Nix flake (nixos-24.11 + agenix + nixos-generators)
├── nixos/
│   ├── configuration.nix        # Top-level конфигурация
│   ├── hardware-yandex-cloud.nix
│   └── modules/
│       ├── base.nix             # SSH, users, пакеты
│       ├── firewall.nix         # nftables + TPROXY rules
│       ├── k3s.nix              # k3s server
│       └── k3s-post-deploy.nix  # Применение k8s манифестов
├── k8s/                         # Kubernetes манифесты
│   ├── namespaces.yaml
│   ├── traefik/
│   ├── xray/
│   ├── amneziawg/
│   └── mtproto/
├── xray/
│   └── config.json              # Шаблон конфига (smart routing rules)
├── secrets/                     # agenix секреты
├── terraform/                   # OpenTofu/Terraform для YC
└── scripts/                     # Build, upload, deploy скрипты
```

## Предварительные требования

### Nix

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
. /etc/profile.d/nix.sh
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Remote builder (для сборки с macOS)

Образ qcow2 — это x86_64-linux, на macOS нужен удалённый Linux-билдер с KVM.

**1. На Linux-машине (билдер):**

```bash
# Nix должен быть установлен
# Пользователь билдера должен быть в trusted-users
# /etc/nix/nix.conf:
#   trusted-users = root dimam
```

**2. На macOS (клиент):**

```bash
# Добавить себя в trusted-users nix daemon
echo 'extra-trusted-users = dimam' | sudo tee -a /etc/nix/nix.conf
sudo launchctl kickstart -k system/org.nixos.nix-daemon

# Скопировать SSH ключ для root (nix daemon работает от root)
sudo mkdir -p /var/root/.ssh
sudo cp ~/.ssh/id_ed25519 /var/root/.ssh/nixos-builder-key
sudo chmod 600 /var/root/.ssh/nixos-builder-key

# Добавить host key билдера в known_hosts root'а
sudo ssh -i /var/root/.ssh/nixos-builder-key dimam@10.0.1.133 "echo ok"
```

**3. Переменные окружения (опционально):**

```bash
export BUILDER_HOST="dimam@10.0.1.133"
export BUILDER_KEY="/var/root/.ssh/nixos-builder-key"
```

### Yandex Cloud CLI и OpenTofu

```bash
# YC CLI
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
yc init

# OpenTofu
brew install opentofu
```

## Быстрый старт

### 1. Сборка образа

```bash
./scripts/build-image.sh
```

### 2. Загрузка в Yandex Cloud

```bash
./scripts/upload-image.sh
```

### 3. Настройка Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Отредактировать terraform.tfvars
```

### 4. Деплой

```bash
./scripts/deploy.sh
```

### 5. Обновление конфигурации

```bash
./scripts/rebuild-remote.sh admin@<IP>
```

## Секреты (agenix)

```bash
# Генерация ключей
nix run github:ryantm/agenix -- -e secrets/xray-upstream.age
nix run github:ryantm/agenix -- -e secrets/amneziawg-private.age
nix run github:ryantm/agenix -- -e secrets/mtproto-secret.age
```

Добавить SSH ключи в `secrets/secrets.nix` перед шифрованием.

## Порты

| Порт | Протокол | Сервис |
|------|----------|--------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP (Traefik) |
| 443 | TCP | HTTPS / VLESS Reality (Traefik TLS passthrough) |
| 2053 | TCP | x3-ui admin panel |
| 8443 | TCP | MTProto proxy |
| 51820 | UDP | AmneziaWG VPN |

## Smart Routing (xray-core)

- `geosite:category-ru`, `geoip:ru` → **DIRECT** (через РФ IP сервера)
- `.ru`, `.su`, `.рф` домены → **DIRECT**
- `geoip:private` → **DIRECT**
- `geosite:category-ads-all` → **BLOCK**
- Всё остальное → **VLESS Reality uplink**

Геоданные обновляются ежедневно через CronJob (Loyalsoldier/v2ray-rules-dat).

## x3-ui submodule

```bash
git submodule add git@github.com:D800/x3-ui-chart.git k8s/x3-ui
git submodule update --init
```

## Лицензия

GPL v3
