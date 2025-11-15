# VPS Keskkonnapõhised Muudatused

**Kuupäev:** 2025-11-15
**VPS:** kirjakast (93.127.213.242)
**Kasutaja:** janek

---

## Ülevaade

See dokument kirjeldab muudatusi, mis tehtikeskkonna tõttu, kus kogu projekt (sh laborid) asub VPS serveris `kirjakast`, mitte eraldi arendusmasinas.

---

## VPS Serveri Info

### Süsteemiandmed

```
Hostname: kirjakast
OS: Ubuntu 24.04.3 LTS
Kasutaja: janek
Home: /home/janek
IP: 93.127.213.242
Ressursid: 7.8 GB RAM, 2 CPU cores, 96 GB disk
```

### Paigaldatud Tarkvara

**Juba olemas:**
- ✅ Docker 29.0.1
- ✅ Docker Compose v2.40.3
- ✅ vim 9.1 (eelistatud editor)
- ✅ yazi 25.5.31 (file manager)
- ✅ Git

**Peab paigaldama (vt Peatükk 13):**
- ❌ Node.js 18 (backend-nodejs jaoks)
- ❌ PostgreSQL client (psql - DB haldamine)
- ❌ kubectl (Kubernetes laboriteks)

---

## Tehtud Muudatused

### 1. CLAUDE.md Uuendused

**Fail:** `/home/janek/projects/hostinger/CLAUDE.md`

**Muudatused:**
- ✅ Lisatud VPS Environment sektsioon
- ✅ Lisatud hostname, IP, OS info
- ✅ Lisatud paigaldatud tarkvara loend
- ✅ Lisatud puuduva tarkvara paigaldamisjuhised
- ✅ Lisatud vim eelistus (vs nano)
- ✅ Lisatud yazi eelistus
- ✅ Lisatud SSH juurdepääsu info
- ✅ Uuendatud PostgreSQL ühenduse näidised
- ✅ Uuendatud Development Guidelines (vim, env details)

### 2. Uus Peatükk: 13-Tööriistade-Paigaldamine.md

**Fail:** `/home/janek/projects/hostinger/13-Tooristade-Paigaldamine.md`

**Sisu:**
- Node.js 18 paigaldamine
- PostgreSQL client paigaldamine
- kubectl paigaldamine
- Valideerimise skript (check-tools.sh)
- Troubleshooting

**Põhjus:** Koondab kõik tarkvara paigaldamisjuhised ühte kohta

### 3. Olemasolevad Peatükid (vajavad veel uuendamist)

**Järgnevad peatükid vajavad väiksemaid muudatusi:**

#### Peatükk 02: VPS Esmane Seadistamine
**Muudatused:**
- "Zorin OS" → "Ubuntu 24.04" või üldine "Linux"
- "hostinger-ubuntu" → "kirjakast"
- "123.456.789.012" → "93.127.213.242" või üldine
- `nano` → `vim`
- Lisa viide Peatükk 13 (tööriistade paigaldamine)

#### Peatükk 03: PostgreSQL Paigaldamine
**Muudatused:**
- "hostinger-ubuntu" → "kirjakast"
- `nano` → `vim`
- Rõhuta Docker varianti kui PRIMARY
- Väline variant kui ALTERNATIIV

#### Peatükk 12: Docker Põhimõtted
**Muudatused:**
- "Zorin OS" → "Ubuntu 24.04"
- `nano` → `vim`
- Lisa viide check-tools.sh skriptile

#### Laborid (labs/)
**Muudatused:**
- Rõhuta, et kõik laborid käivitatakse samas VPS-is
- Kasutaja: janek
- Hostname: kirjakast
- Docker-first approach

---

## Globaalsed Asendused (Suunised)

### Tekstiredaktor

**Vana:**
```bash
nano failinimi
```

**Uus:**
```bash
vim failinimi
# Redigeerimiseks: vajuta 'i'
# Salvestamiseks ja väljumiseks: Esc, siis :wq
```

### Hostname Viited

**Vana:**
```bash
hostinger-ubuntu
hostinger-vps
```

**Uus:**
```bash
kirjakast
```

### SSH Ühendus

**Vana:**
```bash
ssh root@123.456.789.012
ssh kasutaja@hostinger-vps
```

**Uus:**
```bash
ssh janek@kirjakast
# Või IP-ga:
ssh janek@93.127.213.242
```

### Kasutaja Viited

**Vana:**
```bash
# Näited erinevate kasutajatega
```

**Uus:**
```bash
# Kasuta janek kui põhikasutaja
# Root'i juurdepääs: sudo
```

### OS Viited

**Vana:**
- "Zorin OS"
- "Ubuntu" (üldine)

**Uus:**
- "Ubuntu 24.04 LTS"
- "Linux" (kui üldine)

---

## Töövoog Uute Materjalide Loomisel

### 1. Teoreetilised Peatükid (*.md root kaustas)

```markdown
# Näidiskäsud

## SSH
ssh janek@kirjakast

## File editing
vim /etc/postgresql/16/main/postgresql.conf
# i - insert mode
# Esc, :wq - save and exit

## Hostname
hostname  # Returns: kirjakast

## Kasutaja
whoami    # Returns: janek
```

### 2. Lab Materjalid (labs/)

- Rõhuta Docker-first lähenemist
- Mainida, et kõik käib samas VPS-is
- Docker on juba paigaldatud
- Node.js, kubectl jms võib vajada paigaldamist (Peatükk 13)

### 3. Rakenduste Näited (apps/)

- Rakendused on juba built
- Focus on DevOps, mitte development
- Docker images käivitamiseks

---

## Quick Reference Card

```bash
# === VPS Info ===
Hostname:     kirjakast
User:         janek
IP:           93.127.213.242
OS:           Ubuntu 24.04.3 LTS
RAM:          7.8 GB
CPU:          2 cores
Disk:         96 GB

# === SSH ===
ssh janek@kirjakast

# === Editor ===
vim filename
# i - insert, Esc :wq - save & quit

# === File Manager ===
yazi  # Modern file manager

# === Docker ===
docker --version         # 29.0.1
docker compose version   # v2.40.3

# === Paigalda (kui puudu) ===
# Node.js, psql, kubectl
# Vaata: 13-Tooristade-Paigaldamine.md

# === Project Location ===
cd /home/janek/projects/hostinger
```

---

## Valideerimise Kontrollnimekiri

Peale materjalide uuendamist kontrolli:

- [ ] Kõik `nano` viited asendatud `vim`-iga
- [ ] Kõik hostname viited kasutavad `kirjakast`
- [ ] SSH näited kasutavad `janek@kirjakast`
- [ ] OS viited: Ubuntu 24.04 LTS
- [ ] Docker on mainitud kui juba paigaldatud
- [ ] Viide Peatükk 13 puuduva tarkvara jaoks
- [ ] Ei ole viiteid "Zorin OS"-ile
- [ ] File paths kasutavad `/home/janek/...`

---

## Järgmised Sammud

1. **Paigalda puuduv tarkvara:**
   ```bash
   # Järgi: 13-Tooristade-Paigaldamine.md
   ```

2. **Uuenda vanu peatükke** (kui vajalik):
   - Peatükk 02: VPS seadistamine
   - Peatükk 03: PostgreSQL
   - Peatükk 12: Docker

3. **Jätka koolitusega:**
   - Peatükk 14: Docker Compose (tuleb luua)
   - Labs 2-6 (tuleb luua)

---

## Näpunäited

### Claude Code Kasutamine

Kui Claude Code töötab selle projektiga:
- See näeb CLAUDE.md faili automaatselt
- VPS environment on dokumenteeritud
- Kasutab õigeid hostname/IP/user väärtusi
- Eelistab vim-i nano asemel

### Materjalide Loomine

- **Teoreetilised peatükid:** Eesti keeles, vim, kirjakast
- **Lab materjalid:** Hands-on, Docker-first
- **Kood/näited:** Töötavad käsud, testitud VPS-is

---

**Autor:** Koolituskava v1.0
**VPS:** kirjakast @ 93.127.213.242
**Viimane uuendus:** 2025-11-15
