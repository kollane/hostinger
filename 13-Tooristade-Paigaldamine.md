# Peatükk 13: Tööriistade Paigaldamine VPS-ile

**Kestus:** 2 tundi
**Eeldused:** Peatükid 1-12 läbitud
**Eesmärk:** Paigaldada kõik vajalikud tööriistad koolituse läbimiseks

---

## Sisukord

1. [Ülevaade](#1-ülevaade)
2. [Node.js Paigaldamine](#2-nodejs-paigaldamine)
3. [PostgreSQL Client Paigaldamine](#3-postgresql-client-paigaldamine)
4. [kubectl Paigaldamine](#4-kubectl-paigaldamine)
5. [Lisatööriistad](#5-lisatööriistad)
6. [Valideerine](#6-valideerimine)

---

## 1. Ülevaade

### 1.1. Praegune Seisukord

**VPS Info:**
- **Hostname:** kirjakast
- **OS:** Ubuntu 24.04.3 LTS
- **Kasutaja:** janek
- **IP:** 93.127.213.242

**Juba paigaldatud:**
- ✅ Docker 29.0.1
- ✅ Docker Compose v2.40.3
- ✅ vim 9.1
- ✅ yazi 25.5.31
- ✅ Git

**Puudu (paigaldame selles peatükis):**
- ❌ Node.js (vajalik backend-nodejs rakenduse käitamiseks)
- ❌ PostgreSQL client (vajalik andmebaasi haldamiseks)
- ❌ kubectl (vajalik Kubernetes laboriteks)

---

## 2. Node.js Paigaldamine

### 2.1. Miks Node.js?

Node.js on vajalik:
- Backend-nodejs rakenduse käitamiseks otse VPS-il
- Testimiseks enne konteineriseerimist
- npm pakettide haldamiseks

### 2.2. Paigaldamine

```bash
# Logi VPS-i sisse
ssh janek@kirjakast

# Lisa NodeSource repositoorium (Node.js 18.x)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Paigalda Node.js ja npm
sudo apt install -y nodejs

# Kontrolli versioone
node --version
# Väljund: v18.x.x

npm --version
# Väljund: 10.x.x
```

### 2.3. Testimine

```bash
# Loo testkataloog
mkdir -p ~/test-nodejs
cd ~/test-nodejs

# Loo lihtne test skript
cat > test.js << 'EOF'
console.log('Node.js versioon:', process.version);
console.log('Platform:', process.platform);
console.log('Tere, maailm!');
EOF

# Käivita
node test.js

# Väljund:
# Node.js versioon: v18.x.x
# Platform: linux
# Tere, maailm!

# Kustuta test
cd ~
rm -rf ~/test-nodejs
```

---

## 3. PostgreSQL Client Paigaldamine

### 3.1. Miks PostgreSQL Client?

PostgreSQL client (psql) on vajalik:
- Andmebaasiga ühendumiseks
- SQL päringute käivitamiseks
- Andmebaasi haldamiseks
- Backup'ite tegemiseks

**MÄRKUS:** See on ainult CLIENT, mitte server. PostgreSQL server käivitame Dockeris.

### 3.2. Paigaldamine

```bash
# Paigalda PostgreSQL client
sudo apt install -y postgresql-client

# Kontrolli versiooni
psql --version
# Väljund: psql (PostgreSQL) 16.x
```

### 3.3. Testimine

```bash
# Test: Ühenda Dockeris töötava PostgreSQL-iga (kui on käivitatud)
# Eeldab, et PostgreSQL container töötab:
# docker run -d --name postgres-test \
#   -e POSTGRES_PASSWORD=test123 \
#   -p 5432:5432 postgres:16-alpine

# Ühenda
psql -h localhost -U postgres -d postgres

# Küsib parooli (sisesta: test123)
# Kui ühendus õnnestub:
# postgres=#

# PostgreSQL CLI-s:
\l              # Andmebaaside loend
\q              # Välja

# Puhasta test container (kui lõid)
docker stop postgres-test
docker rm postgres-test
```

---

## 4. kubectl Paigaldamine

### 4.1. Mis on kubectl?

**kubectl** on Kubernetes command-line tööriist, mis võimaldab:
- Kubernetes klastritega suhelda
- Rakendusi deploy'da
- Klastri ressursse hallata
- Logisid vaadata ja probleeme lahendada

**MÄRKUS:** kubectl on vajalik alates Lab 3 (Kubernetes Basics)

### 4.2. Paigaldamine

```bash
# Lae alla viimane stabiilne versioon
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Kontrolli allalaaditud faili (valikuline)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
# Väljund: kubectl: OK

# Paigalda kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Puhasta
rm kubectl kubectl.sha256

# Kontrolli versiooni
kubectl version --client

# Väljund (näide):
# Client Version: v1.31.0
```

### 4.3. Bash Autocomplete Seadistamine (valikuline)

```bash
# kubectl autocompletion bash jaoks
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

# Lühike alias
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc

# Laadi uuesti
source ~/.bashrc

# Nüüd saad kasutada:
k version --client
```

### 4.4. Testimine

```bash
# kubectl on paigaldatud, aga meil ei ole veel Kubernetes klastrit
# Test: Vaata help
kubectl --help

# Kui oled paigaldanud K3s (hiljem koolituses):
# kubectl get nodes
# kubectl get pods
```

---

## 5. Lisatööriistad

### 5.1. K3s (Lightweight Kubernetes)

**MÄRKUS:** Paigaldame hiljem, Lab 3 jaoks

K3s paigaldamine VPS-ile (teeme hiljem):
```bash
# K3s paigaldamine (ÄRAAINDA VEEL!)
curl -sfL https://get.k3s.io | sh -

# Kontrolli
sudo k3s kubectl get nodes
```

### 5.2. Helm (Kubernetes Package Manager)

**MÄRKUS:** Paigaldame hiljem, Lab 4 jaoks

```bash
# Helm paigaldamine (ÄRAAINDA VEEL!)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Kontrolli
helm version
```

### 5.3. Kasulikud CLI Tööriistad (valikuline)

```bash
# htop - parendatud process viewer
sudo apt install -y htop

# ncdu - disk usage analyzer
sudo apt install -y ncdu

# jq - JSON processor
sudo apt install -y jq

# tree - directory tree viewer
sudo apt install -y tree
```

---

## 6. Valideerimine

### 6.1. Kontrolli Kõiki Tööriistu

```bash
# Kopeeri ja käivita see skript
cat > ~/check-tools.sh << 'EOF'
#!/bin/bash

echo "=== Tööriistade Kontroll ==="
echo ""

check_tool() {
    if command -v $1 &> /dev/null; then
        echo "✅ $1: $(command -v $1)"
        $1 $2 2>&1 | head -1
    else
        echo "❌ $1: PUUDUB"
    fi
    echo ""
}

check_tool docker "--version"
check_tool "docker compose" "version"
check_tool node "--version"
check_tool npm "--version"
check_tool psql "--version"
check_tool kubectl "version --client --short"
check_tool git "--version"
check_tool vim "--version"

echo "=== Serveri Info ==="
echo "Hostname: $(hostname)"
echo "Kasutaja: $(whoami)"
echo "OS: $(lsb_release -ds)"
echo "IP: $(hostname -I | awk '{print $1}')"
echo ""
echo "=== Valmis! ==="
EOF

chmod +x ~/check-tools.sh
~/check-tools.sh
```

**Oodatav väljund:**
```
=== Tööriistade Kontroll ===

✅ docker: /usr/bin/docker
Docker version 29.0.1, build eedd969

✅ docker compose: /usr/bin/docker
Docker Compose version v2.40.3

✅ node: /usr/bin/node
v18.x.x

✅ npm: /usr/bin/npm
10.x.x

✅ psql: /usr/bin/psql
psql (PostgreSQL) 16.x

✅ kubectl: /usr/local/bin/kubectl
Client Version: v1.31.0

✅ git: /usr/bin/git
git version 2.43.0

✅ vim: /usr/bin/vim
VIM - Vi IMproved 9.1

=== Serveri Info ===
Hostname: kirjakast
Kasutaja: janek
OS: Ubuntu 24.04.3 LTS
IP: 93.127.213.242

=== Valmis! ===
```

---

## 7. Troubleshooting

### Probleem 1: Node.js paigaldamine ebaõnnestub

```bash
# Kui repository lisamine ebaõnnestub:
sudo apt update
sudo apt install -y curl ca-certificates

# Proovi uuesti
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### Probleem 2: kubectl ei tööta

```bash
# Kontrolli, kas fail on executable
ls -la $(which kubectl)
# Peaks näitama: -rwxr-xr-x

# Kui mitte, paranda:
sudo chmod +x /usr/local/bin/kubectl
```

### Probleem 3: psql ei leia serverit

```bash
# See on normaalne, kui PostgreSQL server ei tööta
# Käivita Docker PostgreSQL:
docker run -d --name postgres-test \
  -e POSTGRES_PASSWORD=test123 \
  -p 5432:5432 \
  postgres:16-alpine

# Nüüd proovi uuesti:
psql -h localhost -U postgres
```

---

## Kokkuvõte

Selles peatükis said:

✅ **Paigaldasid Node.js 18** - backend rakenduste käitamiseks
✅ **Paigaldasid PostgreSQL client** - andmebaasi haldamiseks
✅ **Paigaldasid kubectl** - Kubernetes haldamiseks
✅ **Valideerisid kõik tööriistad** - check-tools.sh skriptiga

**Järgmine samm:** Alusta Lab 1 (Docker Basics) või jätka teoreetiliste peatükkidega

---

## Harjutused

### Harjutus 13.1: Tööriistade Paigaldamine

1. Paigalda Node.js 18
2. Paigalda PostgreSQL client
3. Paigalda kubectl
4. Käivita check-tools.sh
5. Kontrolli, et kõik on paigaldatud

### Harjutus 13.2: Testimine

1. Loo lihtne Node.js skript
2. Käivita PostgreSQL Docker container
3. Ühenda psql kaudu PostgreSQL-iga
4. Loo testtabel
5. Puhasta (kustuta container)

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
**VPS:** kirjakast (Ubuntu 24.04.3 LTS)
