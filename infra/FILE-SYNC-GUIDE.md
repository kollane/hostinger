# Labs Failide Sünkroniseerimise Juhend

## Ülevaade

See juhend kirjeldab, kuidas uuendada labs failid kõigis LXD konteinerites pärast muudatuste tegemist host süsteemis.

**Kasutamise stsenaarium:**
- Oled muutnud faile `/home/janek/projects/hostinger/labs/` kaustas
- Tahad sünkroniseerida muudatused kõigisse õpilaste konteineritesse
- Soovid testimise järel kinnitada, et kõik töötab

---

## Eeldused

**Host süsteemis:**
- Oled `janek` kasutaja
- Sul on `lxd` grupi liikmelisus (sg lxd käsud töötavad)
- Labs failid asuvad: `/home/janek/projects/hostinger/labs/`

**Konteinerid:**
- devops-student1, devops-student2, devops-student3
- Kasutaja konteineris: `labuser`
- Labs asukoht: `/home/labuser/labs/`

---

## Meetod 1: Üksiku Faili Sünkroniseerimine (Soovitatud)

Kasuta seda meetodit, kui uuendasid ainult üht või mõnda konkreetset faili.

### Samm 1: Tuvasta muudetud fail

```bash
cd /home/janek/projects/hostinger
git status
# Näitab muudetud faile, nt:
# modified:   labs/01-docker-lab/setup.sh
```

### Samm 2: Sünkroniseeri fail kõigisse konteineritesse

**Variant A: Käsitsi iga konteinerisse**
```bash
# Student1
sg lxd -c "lxc file push labs/01-docker-lab/setup.sh devops-student1/home/labuser/labs/01-docker-lab/setup.sh"

# Student2
sg lxd -c "lxc file push labs/01-docker-lab/setup.sh devops-student2/home/labuser/labs/01-docker-lab/setup.sh"

# Student3
sg lxd -c "lxc file push labs/01-docker-lab/setup.sh devops-student3/home/labuser/labs/01-docker-lab/setup.sh"
```

**Variant B: Loop kõigile**
```bash
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== Updating $c ==="
  sg lxd -c "lxc file push labs/01-docker-lab/setup.sh $c/home/labuser/labs/01-docker-lab/setup.sh"
done
```

### Samm 3: Kontrolli õigusi ja omanikku

```bash
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== Fixing permissions for $c ==="
  sg lxd -c "lxc exec $c -- chown labuser:labuser /home/labuser/labs/01-docker-lab/setup.sh"
  sg lxd -c "lxc exec $c -- chmod 755 /home/labuser/labs/01-docker-lab/setup.sh"
done
```

### Samm 4: Testi ühes konteineris

```bash
# Logi sisse
sg lxd -c "lxc exec devops-student1 -- su - labuser"

# Konteineris:
cd ~/labs/01-docker-lab
./setup.sh
# Testi, kas töötab

# Välju
exit
exit
```

---

## Meetod 2: Kogu Lab Kausta Sünkroniseerimine

Kasuta seda meetodit, kui uuendasid palju faile ühes labis (nt lisasid uue harjutuse).

### Samm 1: Tuvasta muudetud lab

```bash
cd /home/janek/projects/hostinger
git status labs/
# Näitab, mis labis on muudatused
```

### Samm 2: Sünkroniseeri kogu lab kaust

```bash
LAB="01-docker-lab"  # Muuda vastavalt vajadusele

for c in devops-student1 devops-student2 devops-student3; do
  echo "=== Syncing $LAB to $c ==="
  sg lxd -c "lxc file push -r labs/$LAB/ $c/home/labuser/labs/"
done
```

### Samm 3: Paranda õigused

```bash
LAB="01-docker-lab"

for c in devops-student1 devops-student2 devops-student3; do
  echo "=== Fixing ownership for $c ==="
  sg lxd -c "lxc exec $c -- chown -R labuser:labuser /home/labuser/labs/$LAB"
  sg lxd -c "lxc exec $c -- find /home/labuser/labs/$LAB -type f -name '*.sh' -exec chmod 755 {} \;"
done
```

---

## Meetod 3: Kõikide Labs Failide Sünkroniseerimine (Harvem)

⚠️ **ETTEVAATUST:** See ülekirjutab KÕIK failid kõigis labides! Kasuta ainult siis, kui oled kindel.

### Samm 1: Backup olemasolevad failid (soovitatud)

```bash
for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc snapshot $c backup-$(date +%Y%m%d-%H%M)"
done
```

### Samm 2: Sünkroniseeri kõik labs

```bash
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== Full sync to $c ==="
  sg lxd -c "lxc file push -r labs/ $c/home/labuser/"
done
```

### Samm 3: Paranda õigused

```bash
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== Fixing ownership for $c ==="
  sg lxd -c "lxc exec $c -- chown -R labuser:labuser /home/labuser/labs"
  sg lxd -c "lxc exec $c -- find /home/labuser/labs -type f -name '*.sh' -exec chmod 755 {} \;"
done
```

---

## Meetod 4: Git Pull konteinerites (Arenduses)

Kui labs on git repositoorium konteineris:

```bash
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== Git pull in $c ==="
  sg lxd -c "lxc exec $c -- su - labuser -c 'cd ~/labs && git pull'"
done
```

⚠️ **MÄRKUS:** Eeldab, et labs on git repo ja on konfigureeritud.

---

## Levinud Probleemid

### 1. Õiguste probleem: "Permission denied"

**Sümptom:**
```bash
labuser@student1:~/labs/01-docker-lab$ ./setup.sh
bash: ./setup.sh: Permission denied
```

**Lahendus:**
```bash
# Host süsteemis
for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc exec $c -- chmod 755 /home/labuser/labs/01-docker-lab/setup.sh"
done
```

### 2. Fail kuulub root'ile, mitte labuser'ile

**Sümptom:**
```bash
labuser@student1:~/labs/01-docker-lab$ ls -l setup.sh
-rwxr-xr-x 1 root root 12345 Nov 27 10:00 setup.sh
```

**Lahendus:**
```bash
for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc exec $c -- chown labuser:labuser /home/labuser/labs/01-docker-lab/setup.sh"
done
```

### 3. Fail puudub konteineris

**Sümptom:**
```bash
Error: open /home/labuser/labs/01-docker-lab/setup.sh: no such file or directory
```

**Lahendus:** Kontrolli teed:
```bash
# Vaata, kas lab kaust eksisteerib
sg lxd -c "lxc exec devops-student1 -- ls -la /home/labuser/labs/"

# Kui puudub, loo see
sg lxd -c "lxc exec devops-student1 -- mkdir -p /home/labuser/labs/01-docker-lab"

# Seejärel push uuesti
sg lxd -c "lxc file push labs/01-docker-lab/setup.sh devops-student1/home/labuser/labs/01-docker-lab/"
```

### 4. Script töötab ühes konteineris, teises mitte

**Sümptom:** setup.sh töötab student1's, aga mitte student2's

**Võimalikud põhjused:**
1. **Erinev Docker olek** - student2's võib Docker daemon olla peatatud
2. **Erinevad õigused** - kontrolli `ls -l setup.sh` mõlemas
3. **Pooleliolev sync** - veendu, et kõik loopid käisid edukalt läbi

**Lahendus:**
```bash
# Kontrolli Docker staatust
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== $c Docker status ==="
  sg lxd -c "lxc exec $c -- systemctl is-active docker"
done

# Kontrolli faili olemasolu ja õigusi
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== $c file check ==="
  sg lxd -c "lxc exec $c -- ls -l /home/labuser/labs/01-docker-lab/setup.sh"
done
```

---

## Testimise Checklist

Pärast sünkroniseerimist testi alati:

- [ ] **Fail eksisteerib:** `sg lxd -c "lxc exec devops-student1 -- ls -l /home/labuser/labs/01-docker-lab/setup.sh"`
- [ ] **Õiged õigused:** `-rwxr-xr-x` (755)
- [ ] **Õige omanik:** `labuser:labuser`
- [ ] **Script käivitub:** Logi sisse ja käivita `./setup.sh`
- [ ] **Töötab õigesti:** Testi põhifunktsionaalsus
- [ ] **Kõik konteinerid:** Korda vähemalt 1 teises konteineris

---

## Näide: Lab 1 setup.sh Uuendamine

**Stsenaarium:** Eemaldatud Node.js kontroll, lisatud PostgreSQL automaatne seadistus

⚠️ **OLULINE:** Lab setup skriptid on kättesaadavad kahel viisil:

**Lab 1:**
1. `~/labs/01-docker-lab/setup.sh` - lokaalne fail (õpilased näevad harjutuses)
2. `lab1-setup` - bashrc alias (saab käivitada igalt poolt)

**Lab 2:**
1. `~/labs/02-docker-compose-lab/setup.sh` - lokaalne fail
2. `lab2-setup` - bashrc alias (saab käivitada igalt poolt)

**Uuendada on vaja ainult lokaalne fail!** Alias osutab lokaalse faili peale.

### Samm 1: Muudatus host süsteemis

```bash
cd /home/janek/projects/hostinger
# ... tee muudatused setup.sh-s ...
git status
# modified:   labs/01-docker-lab/setup.sh
```

### Samm 2: Sünkroniseeri lokaalne fail

```bash
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== Updating setup.sh for $c ==="

  # Uuenda lokaalne fail (alias osutab selle peale)
  sg lxd -c "lxc file push labs/01-docker-lab/setup.sh $c/home/labuser/labs/01-docker-lab/setup.sh"
  sg lxd -c "lxc exec $c -- chown labuser:labuser /home/labuser/labs/01-docker-lab/setup.sh"
  sg lxd -c "lxc exec $c -- chmod 755 /home/labuser/labs/01-docker-lab/setup.sh"
done
```

### Samm 3: Testi süsteemset käsku

```bash
# Logi sisse
sg lxd -c "lxc exec devops-student1 -- su - labuser"

# Konteineris - testi süsteemset käsku (saab kutsuda igalt poolt)
lab1-setup
# Vali N (ei ehita image'id, test eelduste kontrolli)
# Kontrolli, et Node.js hoiatust EI OLE ✅
# Kontrolli, et Java hoiatus ON ✅

# Või testi lokaalset faili
cd ~/labs/01-docker-lab
./setup.sh

# Välju
exit
exit
```

### Samm 4: Kinnita teistele

Kui test õnnestus student1's, uuenda README või anna teada:

```bash
echo "Lab 1 setup.sh uuendatud kõigis konteinerites ($(date +%Y-%m-%d))" >> /home/janek/projects/hostinger/infra/CHANGELOG.md
```

---

## Arhitektuur: Aliases vs System Commands

### lab1-setup ja lab2-setup: Bashrc Aliased (Current)

**Miks aliased?**
- ✅ Töötab igalt poolt (alias teeb `cd` enne skripti käivitamist)
- ✅ Hooldus lihtsam - ainult üks fail iga labi kohta
- ✅ Järgib sama mustrit nagu `labs-reset`
- ✅ Ei vaja root õigusi template uuendamiseks

**Kuidas töötab:**
```bash
# .bashrc:
alias lab1-setup="cd ~/labs/01-docker-lab && ./setup.sh"
alias lab2-setup="cd ~/labs/02-docker-compose-lab && ./setup.sh"

# Kasutaja saab kutsuda:
cd /tmp
lab1-setup  # Alias teeb automaatselt: cd ~/labs/01-docker-lab && ./setup.sh
lab2-setup  # Alias teeb automaatselt: cd ~/labs/02-docker-compose-lab && ./setup.sh
```

**Uuendamiseks:**
1. Muuda ainult lokaalne fail (nt `~/labs/02-docker-compose-lab/setup.sh`)
2. Alias osutab alati värskele versioonile

### labs-reset: Bashrc Alias

```bash
# .bashrc (line 136):
alias labs-reset="~/labs/labs-reset.sh"
```

Sama loogika: alias osutab skriptile, skripti uuendamine = kohe kasutusel.

### Vana Lähenemine: System Command (/usr/local/bin/)

**Miks ei kasutata enam:**
- ❌ Kahekordne hooldus - kaks identset faili (~/labs/ ja /usr/local/bin/)
- ❌ Relatiivsed teed ei tööta - skript ootas `solutions/` kausta praeguses kaustas
- ❌ Root õigused - /usr/local/bin/ failid vajavad root'i

**Kui oleks kasutatud:**
```bash
# /usr/local/bin/lab1-setup on eraldi fail
# Tuleks sünkroniseerida KAKS faili:
sg lxd -c "lxc file push labs/01-docker-lab/setup.sh $c/home/labuser/labs/01-docker-lab/"
sg lxd -c "lxc file push labs/01-docker-lab/setup.sh $c/usr/local/bin/lab1-setup"
```

---

## Kiirviide

### Ühe faili sünkroniseerimine + õigused

```bash
FILE="labs/01-docker-lab/setup.sh"
DEST="/home/labuser/labs/01-docker-lab/setup.sh"

for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc file push $FILE $c$DEST"
  sg lxd -c "lxc exec $c -- chown labuser:labuser $DEST"
  sg lxd -c "lxc exec $c -- chmod 755 $DEST"
done
```

### Ühe labi sünkroniseerimine + õigused

```bash
LAB="01-docker-lab"

for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc file push -r labs/$LAB/ $c/home/labuser/labs/"
  sg lxd -c "lxc exec $c -- chown -R labuser:labuser /home/labuser/labs/$LAB"
  sg lxd -c "lxc exec $c -- find /home/labuser/labs/$LAB -type f -name '*.sh' -exec chmod 755 {} \;"
done
```

---

## Meetod 5: Template Image Uuendamine (Uute Konteinerite Jaoks)

⚠️ **OLULINE:** See meetod uuendab template image't, millest luuakse UUED konteinerid. **See EI mõjuta olemasolevaid konteinereid!**

### Millal kasutada?

- Tahad, et kõik TULEVIKUS loodavad konteinerid sisaldaksid uusi faile
- Plaanid luua täiesti uue konteinerite komplekti
- Tahad tagada, et template on alati ajakohane

### Protsess

#### Variant A: Template Image'i Värskendamine (Soovitatav)

**Samm 1: Vaata olemasolevat template'i**
```bash
sg lxd -c "lxc image list | grep devops"
# Näitab: devops-lab-base
```

**Samm 2: Loo ajutine konteiner template'ist**
```bash
sg lxd -c "lxc launch devops-lab-base temp-update"
sg lxd -c "lxc list | grep temp"
```

**Samm 3: Uuenda faile ajutises konteineris**
```bash
# Üksik fail
sg lxd -c "lxc file push labs/01-docker-lab/setup.sh temp-update/home/labuser/labs/01-docker-lab/setup.sh"

# Või kogu lab
sg lxd -c "lxc file push -r labs/01-docker-lab/ temp-update/home/labuser/labs/"

# Paranda õigused
sg lxd -c "lxc exec temp-update -- chown -R labuser:labuser /home/labuser/labs"
sg lxd -c "lxc exec temp-update -- find /home/labuser/labs -type f -name '*.sh' -exec chmod 755 {} \;"
```

**Samm 4: Peata konteiner**
```bash
sg lxd -c "lxc stop temp-update"
```

**Samm 5: Loo uus image ajutisest konteinerist**
```bash
# Kustuta vana template (optional - varukoopia jaoks võid jätta)
# sg lxd -c "lxc image delete devops-lab-base"

# Loo uus image
sg lxd -c "lxc publish temp-update --alias devops-lab-base-new description='Updated DevOps Lab Template'"

# Kui töötab hästi, nimeta ümber
sg lxd -c "lxc image alias rename devops-lab-base devops-lab-base-old"
sg lxd -c "lxc image alias rename devops-lab-base-new devops-lab-base"
```

**Samm 6: Kustuta ajutine konteiner**
```bash
sg lxd -c "lxc delete temp-update"
```

**Samm 7: Testi uue konteineri loomist**
```bash
# Loo test konteiner uuest template'ist
sg lxd -c "lxc launch devops-lab-base test-student"
sg lxd -c "lxc exec test-student -- ls -l /home/labuser/labs/01-docker-lab/setup.sh"

# Kui töötab, kustuta test
sg lxd -c "lxc delete --force test-student"
```

#### Variant B: Olemasoleva Konteineri Kasutamine Template'ina

Kui üks konteiner (nt devops-student1) on juba õigesti seadistatud:

**Samm 1: Peata konteiner**
```bash
sg lxd -c "lxc stop devops-student1"
```

**Samm 2: Loo image konteinerist**
```bash
sg lxd -c "lxc publish devops-student1 --alias devops-lab-base-updated description='DevOps Lab Template from student1'"
```

**Samm 3: Käivita konteiner uuesti**
```bash
sg lxd -c "lxc start devops-student1"
```

### Uute Konteinerite Loomine Template'ist

```bash
# Loo uus konteiner
sg lxd -c "lxc launch devops-lab-base devops-student4"

# Seadista SSH port (nt 2204)
sg lxd -c "lxc config device add devops-student4 ssh proxy listen=tcp:0.0.0.0:2204 connect=tcp:127.0.0.1:22"

# Käivita
sg lxd -c "lxc start devops-student4"
```

### Kuidas Uuendada Olemasolevaid + Template't Korraga?

**Stsenaarium:** Tahad, et kõik (olemasolevad + tulevased) konteinerid oleksid uuendatud.

```bash
# 1. Uuenda olemasolevaid konteinereid (Meetod 1)
for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc file push labs/01-docker-lab/setup.sh $c/home/labuser/labs/01-docker-lab/setup.sh"
  sg lxd -c "lxc exec $c -- chown labuser:labuser /home/labuser/labs/01-docker-lab/setup.sh"
  sg lxd -c "lxc exec $c -- chmod 755 /home/labuser/labs/01-docker-lab/setup.sh"
done

# 2. Uuenda template'i (Meetod 5A)
sg lxd -c "lxc launch devops-lab-base temp-update"
sg lxd -c "lxc file push labs/01-docker-lab/setup.sh temp-update/home/labuser/labs/01-docker-lab/setup.sh"
sg lxd -c "lxc exec temp-update -- chown labuser:labuser /home/labuser/labs/01-docker-lab/setup.sh"
sg lxd -c "lxc exec temp-update -- chmod 755 /home/labuser/labs/01-docker-lab/setup.sh"
sg lxd -c "lxc stop temp-update"
sg lxd -c "lxc publish temp-update --alias devops-lab-base --force description='Updated DevOps Lab Template'"
sg lxd -c "lxc delete temp-update"
```

---

## Võrdlus: Template vs Olemasolevad Konteinerid

| Aspekt | Template Uuendamine | Konteinerite Uuendamine |
|--------|-------------------|------------------------|
| **Mõjutab** | Uued konteinerid | Olemasolevad konteinerid |
| **Õpilaste töö** | Ei mõjuta | Võib mõjutada (kui pooleli) |
| **Aeg** | ~5-10 min | ~1-2 min |
| **Risk** | Madal | Keskmine (kui skript käib) |
| **Kasutus** | Harva (uus versioon) | Sageli (bugfix, update) |
| **Rollback** | Lihtne (vana image) | Raskem (snapshot) |

---

**Viimane uuendus:** 2025-12-01
**Autor:** Administraator
**Versioon:** 1.3 - Lisatud lab2-setup alias dokumentatsioon
