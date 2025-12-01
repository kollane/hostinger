# LXD ja Võrgu Põhimõisted

Selles dokumendis on lihtsalt lahti seletatud:
1. [LXD Template ja Konteiner](#lxd-template-ja-konteiner)
2. [Proxy sisevõrgus](#proxy-sisevõrgus) (forward proxy)
3. [Reverse Proxy](#reverse-proxy)

---

# LXD Template ja Konteiner

## Lihtne analoogia

```
Template (Image)     =  Küpsetise vorm / Master koopia
Konteiner            =  Küpsetis / Koopia vormist
```

---

## Template (Image) - "Master koopia"

**Mis see on:**
Template on **salvestatud süsteemi pilt**, mis sisaldab kõike eelseadistatud:
- Operatsioonisüsteem (Ubuntu 24.04)
- Paigaldatud tarkvara (Docker, Java, Node.js, kubectl...)
- Konfiguratsioonid (.bashrc, proxy seaded...)
- Kasutajad (labuser)

**Kuidas see tekib (K8S-INSTALLATION.md näide):**

```bash
# 1. Loo tavaline konteiner Ubuntu baasilt
lxc launch ubuntu:24.04 k8s-template -p default -p devops-lab-k8s

# 2. Logi sisse ja seadista KÕIK mis vaja
lxc exec k8s-template -- bash
apt-get install -y docker-ce openjdk-21-jdk nodejs...
# ... palju seadistamist ...
exit

# 3. PEATA konteiner
lxc stop k8s-template

# 4. "Külmuta" see image'iks (template'iks)
lxc publish k8s-template --alias k8s-lab-base

# 5. Kustuta algne konteiner (enam ei vaja)
lxc delete k8s-template
```

**Tulemus:** `k8s-lab-base` on nüüd template, mida saab kasutada uute konteinerite loomiseks.

---

## Konteiner - "Koopia template'ist"

**Mis see on:**
Konteiner on **töötav instants** template'ist. Iga õpilane saab oma koopia.

**Kuidas see tekib:**

```bash
# Loo konteiner template'ist (sekundid!)
lxc launch k8s-lab-base devops-k8s-student1

# Iga õpilane saab IDENTSE algseisu
lxc launch k8s-lab-base devops-k8s-student2
lxc launch k8s-lab-base devops-k8s-student3
```

**Oluline:** Konteinerid on **iseseisvad**. Kui student1 paigaldab midagi, siis student2 seda ei näe.

---

## Visuaalne ülevaade

```
┌─────────────────────────────────────────────────────────────┐
│                    ubuntu:24.04                              │
│                  (Canonical'i image)                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼ lxc launch
┌─────────────────────────────────────────────────────────────┐
│                   k8s-template                               │
│                 (ajutine konteiner)                          │
│                                                              │
│   + apt install docker, java, nodejs, kubectl, helm...      │
│   + loo labuser kasutaja                                    │
│   + seadista .bashrc, proxy...                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼ lxc stop + lxc publish
┌─────────────────────────────────────────────────────────────┐
│                  k8s-lab-base                                │
│              ⭐ TEMPLATE (image) ⭐                           │
│                                                              │
│   Kõik on sees ja ootab kasutamist                          │
└──────────┬──────────────┬──────────────┬────────────────────┘
           │              │              │
           ▼              ▼              ▼  lxc launch
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ student1 │   │ student2 │   │ student3 │
    │          │   │          │   │          │
    │ Oma K8s  │   │ Oma K8s  │   │ Oma K8s  │
    │ klaster  │   │ klaster  │   │ klaster  │
    └──────────┘   └──────────┘   └──────────┘
      KONTEINER      KONTEINER      KONTEINER
```

---

## Miks see kasulik on?

| Probleem | Lahendus template'iga |
|----------|----------------------|
| Iga õpilase seadistamine võtab 2+ tundi | Template'ist konteiner ~30 sekundit |
| "Mul ei tööta, sul töötab" | Kõik alustavad IDENTSEST seisust |
| Õpilane rikkus keskkonna | Kustuta konteiner, loo uus template'ist |
| Uuendus vaja kõigile | Tee uus template, loo konteinerid uuesti |

---

## Käsud kokkuvõttes

```bash
# TEMPLATE haldus
lxc image list                    # Vaata template'e
lxc image delete k8s-lab-base     # Kustuta template

# KONTEINERI haldus
lxc list                          # Vaata konteinereid
lxc launch k8s-lab-base student1  # Loo konteiner template'ist
lxc stop student1                 # Peata
lxc start student1                # Käivita
lxc delete student1               # Kustuta
lxc exec student1 -- bash         # Logi sisse
```

---

# Proxy Sisevõrgus

## Mis on proxy?

```
┌─────────────────────────────────────────────────────────────────┐
│                        ETTEVÕTTE SISEVÕRK                       │
│                                                                 │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐                 │
│   │  Lab 3   │    │  Lab 4   │    │  Lab 5   │                 │
│   │ 10.0.1.3 │    │ 10.0.1.4 │    │ 10.0.1.5 │                 │
│   └────┬─────┘    └────┬─────┘    └────┬─────┘                 │
│        │               │               │                        │
│        └───────────────┼───────────────┘                        │
│                        │                                        │
│                        ▼                                        │
│                ┌──────────────┐                                 │
│                │    PROXY     │                                 │
│                │ cache1.sss   │                                 │
│                │    :3128     │                                 │
│                └──────┬───────┘                                 │
│                       │                                         │
└───────────────────────┼─────────────────────────────────────────┘
                        │
                   ┌────┴────┐
                   │ TULEMÜÜR │
                   └────┬────┘
                        │
                        ▼
                 ┌─────────────┐
                 │  INTERNET   │
                 │ google.com  │
                 │ docker.io   │
                 │ github.com  │
                 └─────────────┘
```

---

## Miks proxy?

| Põhjus | Selgitus |
|--------|----------|
| **Turvalisus** | Sisevõrgu masinad EI SAA otse internetti. Ainult proxy saab. |
| **Kontroll** | IT saab logida ja filtreerida, kuhu ühendutakse |
| **Vahemälu (cache)** | Sama fail laaditakse internetist 1x, järgmised saavad proxy'st |
| **Lihtne haldus** | Tulemüüris 1 auk (proxy) vs 100 masina jaoks 100 auku |

---

## Kuidas töötab?

**Ilma proxy'ta (ei tööta sisevõrgus):**
```
Lab 3 ──X──► google.com
         ↑
      BLOKEERITUD
      (tulemüür)
```

**Proxy'ga:**
```
Lab 3 ───► Proxy ───► google.com
      (1)        (2)

1. Lab 3 ütleb proxy'le: "Too mulle google.com"
2. Proxy läheb internetti ja toob vastuse
3. Proxy annab vastuse Lab 3-le
```

---

## Praktiline näide

```bash
# ILMA proxy seadistuseta - ei tööta
curl https://google.com
# curl: (7) Failed to connect

# PROXY seadistusega - töötab
export https_proxy=http://cache1.sss:3128
curl https://google.com
# OK - proxy käis ära ja tõi vastuse
```

---

## Mida proxy seadistamine teeb?

```bash
# Ütleb süsteemile: "Kui tahad internetti, küsi proxy käest"
export http_proxy=http://cache1.sss:3128
export https_proxy=http://cache1.sss:3128
```

| Muutuja | Mida mõjutab |
|---------|--------------|
| `http_proxy` | HTTP päringud (port 80) |
| `https_proxy` | HTTPS päringud (port 443) |
| `no_proxy` | Kohalikud aadressid, mis EI lähe läbi proxy |

---

## no_proxy - erand

```bash
no_proxy=localhost,127.0.0.1,10.0.0.0/8
```

See ütleb: "Ära kasuta proxy't nende jaoks" - sest need on sisevõrgus ja ei vaja internetti.

```
Lab 3 ───► Lab 4 (10.0.1.4)     = OTSE (no_proxy)
Lab 3 ───► google.com           = LÄBI PROXY
```

---

## Kokkuvõte

```
PROXY = Värav sisevõrgust internetti

Sisevõrk ←──► Proxy ←──► Internet
              (ainus väljapääs)
```

---

# Reverse Proxy

## Mis vahe on proxy ja reverse proxy'l?

```
PROXY (Forward Proxy)         REVERSE PROXY
---------------------         -------------
Klient → Proxy → Internet     Internet → Reverse Proxy → Serverid

Kaitseb KLIENTE               Kaitseb SERVEREID
"Aita mul internetti pääseda" "Suuna päring õigesse serverisse"
```

---

## Reverse Proxy tööpõhimõte

```
                            ┌─────────────────────────────────────┐
                            │           SINU SERVERID             │
     INTERNET               │                                     │
                            │  ┌───────────┐  ┌───────────┐      │
┌──────────┐               │  │  user-    │  │  todo-    │      │
│ Kasutaja │               │  │  service  │  │  service  │      │
│ brauser  │               │  │  :3000    │  │  :8081    │      │
└────┬─────┘               │  └─────▲─────┘  └─────▲─────┘      │
     │                      │        │             │             │
     │ küsib:               │        │             │             │
     │ example.com/api/users│  ┌─────┴─────────────┴─────┐      │
     │                      │  │                         │      │
     └──────────────────────┼─►│     REVERSE PROXY       │      │
                            │  │        (nginx)          │      │
                            │  │         :80             │      │
                            │  └─────────────────────────┘      │
                            │                                     │
                            └─────────────────────────────────────┘

Kasutaja näeb: example.com (port 80)
Tegelikult:    nginx suunab päringud erinevatesse teenustesse
```

---

## Miks reverse proxy?

| Põhjus | Selgitus |
|--------|----------|
| **Üks sisenemispunkt** | Kasutaja näeb ainult porti 80/443, mitte 3000, 8081, 5432... |
| **URL-põhine suunamine** | `/api/users` → user-service, `/api/todos` → todo-service |
| **SSL/TLS** | HTTPS ainult reverse proxy'l, sisemiselt HTTP (lihtsam) |
| **Koormuse jaotus** | Sama teenus 3 serveris? Reverse proxy jagab päringuid |
| **Turvalisus** | Sisemised teenused pole otse internetist ligipääsetavad |

---

## Praktiline näide (nginx)

```
┌─────────────────────────────────────────────────────────────┐
│                    nginx.conf                                │
└─────────────────────────────────────────────────────────────┘

             URL                          SUUNATAKSE
        ─────────────                 ─────────────────
        /                      →      frontend:80
        /api/users             →      user-service:3000
        /api/todos             →      todo-service:8081
```

**nginx.conf näide:**

```nginx
server {
    listen 80;

    # Avalehe päringud → frontend
    location / {
        proxy_pass http://frontend:80;
    }

    # API päringud → vastavad teenused
    location /api/users {
        proxy_pass http://user-service:3000;
    }

    location /api/todos {
        proxy_pass http://todo-service:8081;
    }
}
```

---

## Võrdlus: Proxy vs Reverse Proxy

```
FORWARD PROXY (sisevõrgus)
──────────────────────────

  Sisevõrk                           Internet
  ┌──────────┐                      ┌──────────┐
  │  Klient  │───► PROXY ──────────►│  Server  │
  └──────────┘                      └──────────┘

  Klient teab: "Ma kasutan proxy't"
  Server ei tea: "Keegi küsib, aga kes?"


REVERSE PROXY (serverite ees)
─────────────────────────────

  Internet                           Sisevõrk
  ┌──────────┐                      ┌──────────┐
  │  Klient  │───► REVERSE PROXY ──►│  Server  │
  └──────────┘                      └──────────┘

  Klient ei tea: "Ma räägin serveriga... vist?"
  Server teab: "Päring tuli reverse proxy'lt"
```

---

## Kus kasutatakse?

| Koht | Reverse Proxy | Näide |
|------|---------------|-------|
| **Lab 2** | nginx | Docker Compose ees |
| **Lab 3-4** | Kubernetes Ingress | nginx-ingress controller |
| **Pilves** | Load Balancer | AWS ALB, GCP LB |
| **CDN** | Cloudflare, Akamai | Vahemälu + DDoS kaitse |

---

## Kokkuvõte

```
Forward Proxy:   KLIENT ───► [PROXY] ───► INTERNET
                 "Aita mul välja pääseda"

Reverse Proxy:   INTERNET ───► [REVERSE PROXY] ───► SERVERID
                 "Suuna mind õigesse kohta"
```

| Tüüp | Kaitseb | Asub | Näide |
|------|---------|------|-------|
| Forward Proxy | Kliente | Klientide ees | cache1.sss:3128 |
| Reverse Proxy | Servereid | Serverite ees | nginx, Ingress |

---

# Seotud juhendid

- [INSTALLATION.md](INSTALLATION.md) - Docker laborite template (Lab 1-2)
- [K8S-INSTALLATION.md](K8S-INSTALLATION.md) - Kubernetes laborite template (Lab 3-10)
- [08B-Nginx-Reverse-Proxy-Docker-Keskkonnas.md](../resource/08B-Nginx-Reverse-Proxy-Docker-Keskkonnas.md) - Põhjalik nginx reverse proxy teooria

---

**Viimane uuendus:** 2025-12-01
