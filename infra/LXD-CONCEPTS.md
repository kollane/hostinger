# LXD ja Võrgu Põhimõisted

Selles dokumendis on lihtsalt lahti seletatud:
1. [LXD Template ja Konteiner](#lxd-template-ja-konteiner)
2. [Proxy sisevõrgus](#proxy-sisevõrgus) (forward proxy)

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

## Template'i Muutmine ja Uuendamine

### Küsimus: Kas `lxc delete k8s-template` kustutab template'i?

**Vastus: ❌ EI!**

Template (image) ja konteiner on **eraldi asjad**:

```bash
# 1. Publitseerimisel KOPEERITAKSE konteiner image'iks:
lxc publish k8s-template --alias k8s-lab-base
# Nüüd on 2 asja:
#   - k8s-template (CONTAINER)
#   - k8s-lab-base (IMAGE)

# 2. Delete kustutab AINULT konteineri:
lxc delete k8s-template
# Tulemus:
#   - k8s-template (GONE) ✗
#   - k8s-lab-base (EXISTS) ✓
```

**Analoogia:**
```
Konteiner  = Word fail, mida sa muudad
Template   = PDF, mille sa salvestasid
Delete     = Kustutab Word faili, PDF jääb alles
```

---

### Kuidas Template'it Muuta?

**Stsenaarium:** Unustasin Trivy paigaldada template'isse. Kuidas lisada?

#### Meetod 1: Käivita Image'ist Uuesti (SOOVITATAV)

```bash
# 1. Käivita image'ist UUS konteiner:
lxc launch k8s-lab-base k8s-template-v2

# 2. Logi sisse ja tee muudatused:
lxc exec k8s-template-v2 -- bash
apt-get install -y new-tool
exit

# 3. Publitseeri üle (--force kirjutab üle):
lxc stop k8s-template-v2
lxc publish k8s-template-v2 --alias k8s-lab-base --force

# 4. Kustuta working konteiner:
lxc delete k8s-template-v2

# ✅ VALMIS! Template on uuendatud.
```

#### Meetod 2: Versioonihaldus (TURVALINE)

```bash
# 1. Nimeta vana image ümber:
lxc image alias rename k8s-lab-base k8s-lab-base-v1

# 2. Loo uus versioon:
lxc launch k8s-lab-base-v1 k8s-template-v2
lxc exec k8s-template-v2 -- bash
# ... muudatused ...
exit

# 3. Publitseeri uue nimega:
lxc stop k8s-template-v2
lxc publish k8s-template-v2 --alias k8s-lab-base-v2
lxc delete k8s-template-v2

# 4. Nüüd sul on MÕLEMAD:
lxc image list
# k8s-lab-base-v1 (vana)
# k8s-lab-base-v2 (uus)

# 5. Testi uut:
lxc launch k8s-lab-base-v2 test

# 6. Kui OK, kustuta vana:
lxc image delete k8s-lab-base-v1
```

---

### Mis Juhtub Olemasolevate Konteineritega?

**OLULINE:** Juba loodud konteinerid **EI UUENDU** automaatselt!

```bash
# Enne template'i uuendamist:
lxc launch k8s-lab-base student1  # EI OLE Trivy

# Template'i uuendamine:
# ... meetod 1 üleval ...

# VANA konteiner (EI UUENDU):
lxc exec student1 -- trivy version
# ERROR: trivy not found ✗

# UUS konteiner (saab uue template'i):
lxc launch k8s-lab-base student2
lxc exec student2 -- trivy version
# Trivy 0.x.x ✓
```

**Kui tahad uuendada VANA konteineri:**
1. Paigalda käsitsi: `lxc exec student1 -- apt-get install -y trivy`
2. VÕI kustuta ja loo uuesti: `lxc delete student1 && lxc launch k8s-lab-base student1`

---

## Template'i Backup ja Restore

### Miks Backup?

| Olukord | Ilma Backup'ita | Koos Backup'iga |
|---------|----------------|-----------------|
| Template muutmine läks katki | Pead looma uuesti (~2h) | Restore backup (~2 min) |
| Ekslik kustutamine | Kaotad KOGU töö | Restore backup |
| Versioonihaldus | Ei saa vana versiooni tagasi | Restore vana backup |

---

### Kuidas Backup Teha?

```bash
# 1. Loo backup kaust:
mkdir -p ~/lxd-backups

# 2. Ekspordi image fail'iks:
lxc image export k8s-lab-base ~/lxd-backups/k8s-lab-base-$(date +%Y%m%d)
```

**Mis juhtub:**
1. LXD loeb image'i image store'ist
2. Pakib kokku tar.gz arhiiviks
3. Salvestab faili `~/lxd-backups/k8s-lab-base-20250115.tar.gz`

**Faili formaat:**
```
~/lxd-backups/
├── k8s-lab-base-20250115.tar.gz     (image + metadata)
└── k8s-lab-base-20250201.tar.gz     (hilisem versioon)
```

**Faili suurus:** Tavaliselt 800MB - 1.5GB (sõltub, mis template'is on)

---

### Kuidas Backup Restore'ida?

```bash
# 1. Kustuta vigane/vana image (kui vaja):
lxc image delete k8s-lab-base

# 2. Impordi backup:
lxc image import ~/lxd-backups/k8s-lab-base-20250115.tar.gz --alias k8s-lab-base

# 3. Kontrolli:
lxc image list
# k8s-lab-base  ✓

# 4. Testi:
lxc launch k8s-lab-base test-restore
lxc exec test-restore -- bash
# ... kontrolli, et kõik on olemas ...
```

---

### Praktiline Workflow: Template Muutmine Backup'iga

```bash
# 1. TEE BACKUP enne muutmist:
lxc image export k8s-lab-base ~/lxd-backups/k8s-lab-base-backup-$(date +%Y%m%d)

# 2. MUUDA template:
lxc launch k8s-lab-base k8s-template-fix
lxc exec k8s-template-fix -- bash
# ... tee muudatused ...
exit

# 3. PUBLITSEERI TESTIMISEKS:
lxc stop k8s-template-fix
lxc publish k8s-template-fix --alias k8s-lab-base-test
lxc delete k8s-template-fix

# 4. TESTI:
lxc launch k8s-lab-base-test test-student
# ... kontrolli põhjalikult ...

# 5a. KUI OK - asenda vana:
lxc image delete k8s-lab-base
lxc image alias rename k8s-lab-base-test k8s-lab-base

# 5b. KUI KATKI - restore backup:
lxc image delete k8s-lab-base-test
lxc image import ~/lxd-backups/k8s-lab-base-backup-20250115.tar.gz --alias k8s-lab-base
```

---

### Best Practices

#### 1. Automaatne Dateerimine

```bash
# Hea:
lxc image export k8s-lab-base ~/lxd-backups/k8s-lab-base-$(date +%Y%m%d-%H%M)
# Tulemus: k8s-lab-base-20250115-1430.tar.gz

# Halb:
lxc image export k8s-lab-base ~/lxd-backups/backup.tar.gz
# Ei tea, millal tehtud!
```

#### 2. Backup Enne Iga Suuremat Muudatust

```bash
# Enne template'i muutmist:
echo "Backup template before changes..."
lxc image export k8s-lab-base ~/lxd-backups/k8s-lab-base-pre-trivy-$(date +%Y%m%d).tar.gz

# Muuda template...
# Kui midagi läheb katki, on backup olemas!
```

#### 3. Hoia Vähemalt 3 Viimast Backup'i

```bash
# Skript: hoia 3 viimast, kustuta vanad
cd ~/lxd-backups
ls -t k8s-lab-base-*.tar.gz | tail -n +4 | xargs -r rm
```

#### 4. Ekspordi Enne Kustutamist

```bash
# ÄRA TEE:
lxc image delete k8s-lab-base  # OHTLIK!

# TEE:
lxc image export k8s-lab-base ~/lxd-backups/k8s-lab-base-last-$(date +%Y%m%d).tar.gz
lxc image delete k8s-lab-base  # Nüüd turvaline
```

---

### Backup vs Snapshot

| Aspekt | Backup (`lxc image export`) | Snapshot (`lxc snapshot`) |
|--------|----------------------------|--------------------------|
| **Mida salvestab** | Template (image) | Konteiner (running instance) |
| **Kus salvestub** | Fail (`~/lxd-backups/*.tar.gz`) | LXD'is (snapshot store) |
| **Saab kopeerida teise masinasse** | ✅ JAH | ❌ EI (ilma export'ita) |
| **Kasutus** | Template backup/restore | Konteineri ajutine seisund |

**Kokkuvõte:**
- **Backup** = Template'i koopia fail'is (portable)
- **Snapshot** = Konteineri ajutine seisund (LXD internal)

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

# Seotud juhendid

- [INSTALLATION.md](INSTALLATION.md) - Docker laborite template (Lab 1-2)
- [K8S-INSTALLATION.md](K8S-INSTALLATION.md) - Kubernetes laborite template (Lab 3-10)
- [08B-Nginx-Reverse-Proxy-Docker-Keskkonnas.md](../resource/08B-Nginx-Reverse-Proxy-Docker-Keskkonnas.md) - Põhjalik nginx reverse proxy teooria

---

**Viimane uuendus:** 2025-12-01
