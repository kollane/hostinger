# Labs Failide Sünkroniseerimise Kiirnäide

## 📍 Töövoog

### 1. **Muuda hostis**
```bash
# Host süsteemis
cd /home/janek/projects/hostinger

# Muuda faile siin:
vim labs/01-docker-lab/setup.sh
# või
vim labs/02-docker-compose-lab/exercises/01-multi-container.md
# jne
```

### 2. **Sünkroniseeri konteineritesse**
```bash
# Kasuta FILE-SYNC-GUIDE.md juhendeid
cd /home/janek/projects/hostinger

# Näide: setup.sh uuendamine
FILE="labs/01-docker-lab/setup.sh"
DEST="/home/labuser/labs/01-docker-lab/setup.sh"

for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc file push $FILE $c$DEST"
  sg lxd -c "lxc exec $c -- chown labuser:labuser $DEST"
  sg lxd -c "lxc exec $c -- chmod 755 $DEST"
done
```

### 3. **Testi konteineris**
```bash
# Logi sisse
sg lxd -c "lxc exec devops-student1 -- su - labuser"

# Konteineris - testi
lab1-setup
# või
cd ~/labs/01-docker-lab
./setup.sh
```

---

## 📂 Kataloogide Vastavus

| Host | Konteiner |
|------|-----------|
| `/home/janek/projects/hostinger/labs/` | `/home/labuser/labs/` |
| `labs/01-docker-lab/setup.sh` | `/home/labuser/labs/01-docker-lab/setup.sh` |
| `labs/apps/backend-nodejs/` | `/home/labuser/labs/apps/backend-nodejs/` |

---

## 🚀 Kiirkäsud

### Ühe faili sünk
```bash
cd /home/janek/projects/hostinger

FILE="labs/01-docker-lab/setup.sh"
DEST="/home/labuser/labs/01-docker-lab/setup.sh"

for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc file push $FILE $c$DEST"
  sg lxd -c "lxc exec $c -- chown labuser:labuser $DEST"
  sg lxd -c "lxc exec $c -- chmod 755 $DEST"
done
```

### Harjutuse faili sünk
```bash
FILE="labs/01-docker-lab/exercises/01a-single-container-nodejs.md"
DEST="/home/labuser/labs/01-docker-lab/exercises/01a-single-container-nodejs.md"

for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc file push $FILE $c$DEST"
  sg lxd -c "lxc exec $c -- chown labuser:labuser $DEST"
done
```

### .bashrc uuendamine
```bash
FILE=".bashrc"

for c in devops-student1 devops-student2 devops-student3; do
  sg lxd -c "lxc file push /tmp/update-bashrc.sh $c/tmp/update-bashrc.sh"
  sg lxd -c "lxc exec $c -- bash /tmp/update-bashrc.sh"
done
```

---

## ⚠️ Oluline

**ÄRA MUUDA** faile otse konteinerites (näiteks `vim` konteineris) - muudatused lähevad kaduma või tekib konflikt!

**ALATI:**
1. ✅ Muuda hostis
2. ✅ Sünkroniseeri konteineritesse (`lxc file push`)
3. ✅ Testi konteineris

---

## 🔗 Täielik Juhend

Põhjalikum info ja kõik meetodid (template update, git pull, jne):

👉 **[FILE-SYNC-GUIDE.md](FILE-SYNC-GUIDE.md)**

---

**Viimane uuendus:** 2025-11-27
