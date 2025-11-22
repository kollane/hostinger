# 📖 Lab 1 - Reset ja Setup Skriptide Kasutusjuhend

Juhend selgitab, kuidas kasutada Lab 1 setup ja reset skripte nii **single-user** kui ka **multi-user** keskkondades turvaliselt.

---

## 🎯 Ülevaade Skriptidest

Lab 1 sisaldab kolme peamist skripti:

| Skript | Eesmärk | Keskkond | Ohtlikkus |
|--------|---------|----------|-----------|
| **setup.sh** | Kontrollib eeltingimusi ja näitab juhiseid | Mõlemad | ✅ Turvaline |
| **reset.sh** | Täielik reset (KÕIK kasutajad mõjutatud!) | Single-user | ⚠️ OHTLIK multi-user'is |
| **reset-multiuser.sh** | User-safe reset (ainult sinu ressursid) | Multi-user | ✅ Turvaline |

---

## 🔍 Skriptide Detailne Selgitus

### 1️⃣ setup.sh - Eeltingimuste Kontroll

**Eesmärk:** Kontrollib, kas Docker töötab ja näitab harjutuste juhiseid.

**Käivitamine:**
```bash
cd labs/01-docker-lab
bash setup.sh
```

**Mida teeb:**
- ✅ Kontrollib, kas Docker on paigaldatud
- ✅ Kontrollib, kas Docker daemon töötab
- ✅ Tuvastab automaatselt multi-user keskkonna
- ✅ Näitab kasutaja-spetsiifilist informatsiooni (pordid, aliased)
- ✅ Soovitab õigeid käske vastavalt keskkonnale
- ✅ Loetleb saadaolevad harjutused

**Multi-user keskkonnas:**
```bash
✅ Multi-user keskkond tuvastatud
   Kasutaja: janek
   Pordid: PostgreSQL 5433, Backend 3001

⚠️  OLULINE: Multi-user keskkonnas:
   - Kasuta 'dc-up' ja 'dc-down' aliaseid
   - Cleanup: kasuta 'd-cleanup' (MITTE 'bash reset.sh')
   - reset.sh kustutab KÕIGI kasutajate ressursid!
```

**Single-user režiimis:**
```bash
ℹ️  Single-user režiim
   Saad kasutada kõiki skripte tavaliselt.
```

**Ohutusnõue:** ✅ TURVALINE - ei muuda midagi, ainult näitab infot.

---

### 2️⃣ reset.sh - Täielik Süsteemi Reset (OHTLIK MULTI-USER'IS!)

**Eesmärk:** Kustutab KÕIK Lab 1 ressursid (konteinerid, image'id, võrgud, volumes).

**HOIATUS:** ⚠️ **OHTLIK MULTI-USER KESKKONNAS!**

**Käivitamine:**
```bash
cd labs/01-docker-lab
bash reset.sh
```

**Mida teeb:**
- ❌ Kustutab KÕIK `user-service*` konteinerid (KÕIGI kasutajate omad!)
- ❌ Kustutab KÕIK `todo-service*` konteinerid (KÕIGI kasutajate omad!)
- ❌ Kustutab KÕIK `postgres-user`, `postgres-todo` konteinerid
- ❌ Kustutab KÕIK `user-service:*` ja `todo-service:*` image'id
- ❌ Kustutab `todo-network` võrgu
- ❌ Kustutab `postgres-user-data`, `postgres-todo-data` volumes
- ❌ Eemaldab Dockerfile'id apps kaustadest

**Multi-user keskkonnas näitab hoiatust:**
```bash
╔════════════════════════════════════════════════╗
║  ⚠️  MULTI-USER KESKKOND TUVASTATUD  ⚠️      ║
╚════════════════════════════════════════════════╝

HOIATUS: See skript (reset.sh) on mõeldud SINGLE-USER keskkonnale!

❌ OHTLIK: reset.sh kustutab KÕIGI kasutajate ressursid:
   - Kõigi kasutajate konteinerid (user-service, todo-service, postgres-*)
   - Kõigi kasutajate image'id (user-service:*, todo-service:*)
   - Kõigi kasutajate võrgud (todo-network)
   - Kõigi kasutajate volumes (postgres-*-data) - ANDMED KADUVAD!

✅ TURVALINE: Multi-user keskkonnas kasuta selle asemel:
   d-cleanup           - Kustutab AINULT sinu (janek) ressursid
   dc-down             - Peatab sinu teenused (andmed säilivad)
   bash reset-multiuser.sh  - User-safe reset (kui olemas)

Sinu kasutaja: janek
Sinu pordid: PostgreSQL 5433, Backend 3001

Kas oled KINDEL, et soovid jätkata ja kustutada KÕIGI ressursid? (yes/NO)
```

**Kinnitamine:**
- Single-user: vajutab `y` → jätkab
- Multi-user: peab tippima täpselt `yes` → jätkab
- Multi-user: vajutab `n` või `Enter` → tühistab ja soovitab `d-cleanup`

**Kasuta ainult kui:**
- ✅ Oled AINUKE kasutaja VPS'is
- ✅ Tahad tõesti KÕIK ressursid kustutada (full reset)
- ✅ Oled veendunud, et keegi teine ei kasuta samal ajal laborit

**ÄRA KASUTA kui:**
- ❌ VPS'is on mitu kasutajat (janek, maria, kalle)
- ❌ Tahad kustutada ainult oma ressursid
- ❌ Keegi teine võib samal ajal laborit teha

---

### 3️⃣ reset-multiuser.sh - User-Safe Reset (TURVALINE!)

**Eesmärk:** Kustutab AINULT SINU kasutaja Lab 1 ressursid.

**TURVALINE:** ✅ Ei mõjuta teisi kasutajaid!

**Käivitamine:**
```bash
cd labs/01-docker-lab
bash reset-multiuser.sh
```

**Eeltingimus:**
```bash
# Peab olema seadistatud multi-user keskkond
source labs/multi-user-setup.sh
source ~/.bashrc
```

**Mida teeb:**
- ✅ Kustutab AINULT `${USER_PREFIX}-user-service*` konteinerid
- ✅ Kustutab AINULT `${USER_PREFIX}-todo-service*` konteinerid
- ✅ Kustutab AINULT `${USER_PREFIX}-postgres-*` konteinerid
- ✅ Kustutab AINULT `${USER_PREFIX}-user-service:*` image'id
- ✅ Kustutab AINULT `${USER_PREFIX}-todo-network` võrgu
- ✅ Kustutab AINULT `${USER_PREFIX}_postgres-*-data` volumes
- ✅ Eemaldab Dockerfile'id apps kaustadest (kui kasutaja seda soovib)

**Näide (kasutaja: janek):**
```bash
====================================
Lab 1 (Docker) - Multi-User Reset
====================================

Multi-User Reset

Kasutaja: janek
Pordid: PostgreSQL 5433, Backend 3001, Frontend 8081

⚠️  HOIATUS: See kustutab SINU (janek) Lab 1 ressursid:
  - Konteinerid: janek-user-service*, janek-todo-service*, janek-postgres-*
  - Pildid (images): janek-user-service:*, janek-todo-service:*
  - Võrgud (networks): janek-todo-network
  - Andmehoidlad (volumes): janek_postgres-user-data, janek_postgres-todo-data

⚠️  TEISTE kasutajate ressursid EI MÕJUTATA!

Kas soovid jätkata? (y/n)
```

**Kasuta kui:**
- ✅ Oled multi-user keskkonnas
- ✅ Tahad ainult oma ressursid puhastada
- ✅ Ei taha teisi kasutajaid mõjutada

---

## 🧭 Otsustuspuu: Millist Skripti Kasutada?

```
Kas oled multi-user keskkonnas?
  └─ Kui ei tea → Käivita: cat ~/.env-lab
      ├─ Fail olemas → JAH, multi-user
      └─ Faili pole → EI, single-user

┌─────────────────────────────────────────────────────┐
│          SINGLE-USER KESKKOND                       │
├─────────────────────────────────────────────────────┤
│ Setup:   bash setup.sh                              │
│ Reset:   bash reset.sh                              │
│          → Kustutab KÕIK ressursid (OK, ainuke      │
│             kasutaja)                               │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│          MULTI-USER KESKKOND                        │
├─────────────────────────────────────────────────────┤
│ Setup:   bash setup.sh                              │
│          → Näitab multi-user infot                  │
│                                                     │
│ Reset:   3 VARIANTI (vali üks):                     │
│                                                     │
│  1. d-cleanup (SOOVITATAV)                         │
│     → Kiire cleanup (ainult konteinerid/võrgud)    │
│     → Aliased juba seadistatud                     │
│     → Kustutab ainult sinu ressursid               │
│                                                     │
│  2. bash reset-multiuser.sh (TURVALINE)            │
│     → Täielik reset (+ image'id + volumes)         │
│     → Kustutab ainult sinu ressursid               │
│     → Võimaldab valida, kas kustutada image'id     │
│                                                     │
│  3. bash reset.sh (OHTLIK!)                        │
│     → Kustutab KÕIGI kasutajate ressursid!         │
│     → Kasuta AINULT kui admin ja oled kindel       │
│     → Nõuab "yes" kinnitust                        │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Tavalised Stsenaariumid

### Stsenaarium 1: Alustamine Lab 1'ga (Multi-user)

```bash
# 1. Seadista multi-user keskkond (esimene kord)
source labs/multi-user-setup.sh
source ~/.bashrc

# 2. Mine Lab 1 kausta ja kontrolli eeltingimusi
cd labs/01-docker-lab
bash setup.sh

# 3. Alusta harjutustega
cd exercises/
cat 01a-single-container-nodejs.md

# 4. Pärast harjutust - cleanup
d-cleanup  # Kiire cleanup (soovitatav)
# VÕI
bash reset-multiuser.sh  # Täielik reset
```

---

### Stsenaarium 2: Labi Vahel Resetimine (Multi-user)

```bash
# Oled labori keskel ja tahad uuesti alustada

# VARIANT A: Kerge cleanup (säilitab image'id)
dc-down     # Peata teenused
d-cleanup   # Kustuta konteinerid/võrgud

# VARIANT B: Täielik reset (kustutab ka image'id)
bash reset-multiuser.sh
# Vali: [N] Ei kustuta image'id (säilitab baaspildid)
#   VÕI [Y] Kustuta kõik pildid (täielik reset)

# Alusta uuesti
bash setup.sh
```

---

### Stsenaarium 3: Lab Lõpetamine (Multi-user)

```bash
# Oled labi lõpetanud ja tahad ressursid vabastada

# VARIANT A: Ainult peata (andmed säilivad)
dc-down

# VARIANT B: Täielik cleanup (andmed kaduvad)
d-cleanup

# VARIANT C: Reset + eemalda ka image'id
bash reset-multiuser.sh
# Vali: [Y] Kustuta KÕIK pildid (vabasta kogu ruum)
```

---

### Stsenaarium 4: VPS Admin - Kõigi Kasutajate Reset (OHTLIK!)

```bash
# Hoiatus: See mõjutab KÕIKI kasutajaid!

cd labs/01-docker-lab
bash reset.sh

# Multi-user keskkonnas küsib kinnitust:
# Kas oled KINDEL, et soovid jätkata ja kustutada KÕIGI ressursid? (yes/NO)
yes

# ✅ Kasuta ainult kui:
#    - Oled VPS admin
#    - Kõik kasutajad on lõpetanud
#    - Tahad tõesti KÕIK puhastada
```

---

## ⚠️ Ohutusreeglid

### ✅ TURVALINE (kasuta julgelt):

```bash
# Setup
bash setup.sh              # Ainult näitab infot

# Cleanup (multi-user)
dc-down                    # Peata teenused
d-cleanup                  # Kustuta ainult sinu ressursid
bash reset-multiuser.sh    # User-safe reset
```

### ⚠️ OHTLIK (mõtle kaks korda):

```bash
# Reset (multi-user keskkonnas)
bash reset.sh              # KUSTUTAB KÕIGI KASUTAJATE RESSURSID!

# ✅ Kasuta ainult kui:
#    - Oled AINUKE kasutaja
#    - Oled VPS admin ja kõik on lõpetanud
#    - Oled 100% kindel
```

---

## 🔄 Cleanup Valikute Võrdlus

| Käsk | Kustutab | Säilitab | Multi-user turvaline? | Kiirus |
|------|----------|----------|----------------------|--------|
| `dc-down` | Konteinerid (peatab) | Image'id, volumes, võrgud, andmed | ✅ Jah | ⚡ Kiire |
| `d-cleanup` | Konteinerid, kasutamata võrgud/volumes | Image'id, aktiivsed volumes | ✅ Jah | ⚡ Kiire |
| `reset-multiuser.sh` | Konteinerid, võrgud, volumes, (valikuliselt image'id) | Apps failid (valikuliselt) | ✅ Jah | ⏱️ Keskmine |
| `reset.sh` (single) | KÕIK (konteinerid, image'id, võrgud, volumes, failid) | Mitte midagi | ✅ Jah | ⏱️ Aeglane |
| `reset.sh` (multi) | KÕIGI kasutajate ressursid! | Mitte midagi | ❌ EI! | ⏱️ Aeglane |

**Soovitus:**
- **Igapäevane kasutamine:** `dc-down` või `d-cleanup`
- **Täielik reset:** `bash reset-multiuser.sh`
- **Admin reset:** `bash reset.sh` (ainult single-user või admin)

---

## 🐛 Probleemide Lahendamine

### Probleem 1: "reset.sh kustutab teiste kasutajate ressursid!"

**Põhjus:** Kasutad multi-user keskkonnas reset.sh'd

**Lahendus:**
```bash
# Kasuta selle asemel
d-cleanup
# VÕI
bash reset-multiuser.sh
```

---

### Probleem 2: "reset-multiuser.sh ei leia ressursse"

**Põhjus:** Multi-user keskkond pole seadistatud

**Lahendus:**
```bash
# Kontrolli
cat ~/.env-lab

# Kui faili pole, seadista keskkond
source labs/multi-user-setup.sh
source ~/.bashrc

# Proovi uuesti
bash reset-multiuser.sh
```

---

### Probleem 3: "setup.sh ei näita multi-user infot"

**Põhjus:** Pole laadinud ~/.bashrc

**Lahendus:**
```bash
source ~/.bashrc
bash setup.sh
```

---

### Probleem 4: "d-cleanup alias ei tööta"

**Põhjus:** Aliased pole laaditud

**Lahendus:**
```bash
# Kontrolli, kas aliased on olemas
cat ~/.lab-aliases.sh

# Kui on, lae uuesti
source ~/.bashrc

# Proovi
d-cleanup
```

---

## 📚 Kiirviited

### Kontrollimised

```bash
# Kontrolli, milline keskkond
cat ~/.env-lab                    # Kui olemas → multi-user
                                  # Kui puudub → single-user

# Kontrolli oma ressursse
docker ps --filter "name=$(whoami)-"     # Sinu konteinerid
docker images | grep "^$(whoami)-"       # Sinu image'id
docker network ls | grep "$(whoami)"     # Sinu võrgud
docker volume ls | grep "$(whoami)"      # Sinu volumes
```

### Aliased (multi-user)

```bash
dc-up          # docker compose -p $(whoami) up -d
dc-down        # docker compose -p $(whoami) down
dc-logs        # docker compose -p $(whoami) logs -f
dc-ps          # docker compose -p $(whoami) ps
d-cleanup      # Kustutab ainult sinu ressursid
```

---

## 📖 Seotud Juhendid

- **Multi-user seadistamine:** `labs/MULTI-USER-GUIDE.md`
- **Kiire alustamine:** `labs/QUICK-START-MULTI-USER.md`
- **Arhitektuur:** `labs/MULTI-USER-ARCHITECTURE.md`
- **Lab 1 harjutused:** `labs/01-docker-lab/exercises/`

---

## ✅ Kokkuvõte

### Single-User Keskkond:
```bash
bash setup.sh      # Kontrolli eeltingimusi
# ... tee harjutusi ...
bash reset.sh      # Täielik reset
```

### Multi-User Keskkond:
```bash
bash setup.sh              # Kontrolli eeltingimusi (näitab multi-user infot)
# ... tee harjutusi ...
d-cleanup                  # Kiire cleanup (SOOVITATAV)
# VÕI
bash reset-multiuser.sh    # Täielik reset (TURVALINE)
```

### Admin (Multi-User):
```bash
bash reset.sh              # OHTLIK - kustutab KÕIGI ressursid
# Nõuab "yes" kinnitust
```

---

**Oluline meelde jätta:**
- ✅ `setup.sh` on alati turvaline (ainult info)
- ✅ `reset-multiuser.sh` on alati turvaline (ainult sinu ressursid)
- ⚠️ `reset.sh` on OHTLIK multi-user keskkonnas (kustutab KÕIK!)
- ⚡ `d-cleanup` on kiireim ja turvaline cleanup

**Küsimuste korral:** Vaata `labs/MULTI-USER-GUIDE.md` või küsi adminilt abi!
