# LXC Exec Käsu Selgitus

## Küsimus: Mida teeb käsk `lxc exec devops-student1 -- bash -c`?

## Vastus

### Käsu Struktuur

```bash
lxc exec devops-student1 -- bash -c "<käsk>"
```

See käsk koosneb mitmest osast:

#### 1. `lxc exec`
- LXD käsk, mis **käivitab käsu konteineri sees**
- Sama nagu `docker exec` Docker'is

#### 2. `devops-student1`
- **Konteineri nimi**, mille sees käsk käivitatakse
- Siin: Student1 laborikeskkond

#### 3. `--`
- **Eraldaja** (separator)
- Eraldab `lxc exec` parameetreid konteineri sees käivitatavast käsust
- Kõik pärast `--` käivitatakse konteineri sees

#### 4. `bash -c`
- Käivitab `bash` shelli konteineri sees
- `-c` tähendab: "execute the command string" (käivita käsustring)
- Pärast `-c` peab tulema jutumärkides käsk

---

## Kuidas LXD Teab, Millises Konteineris Käsku Käivitada?

### Konteineri Nimi on Käsus Määratud

```bash
lxc exec devops-student1 -- bash -c "käsk"
           ↑
           └── See on konteineri nimi!
```

**Konteiner on OTSE käsus määratud** - `devops-student1` on see konkreetne konteiner, mida käivitatakse.

### Kuidas LXD Leiab Konteineri?

```bash
# 1. LXD hoiab nimekirja kõigist konteineridest
lxc list

# Väljund:
+-------------------+---------+
|       NAME        |  STATE  |
+-------------------+---------+
| devops-student1   | RUNNING |
| devops-student2   | RUNNING |
| devops-student3   | RUNNING |
| devops-k8s-student1 | RUNNING |
+-------------------+---------+

# 2. Kui käivitad:
lxc exec devops-student1 -- bash -c "whoami"

# LXD:
# - Otsib nimekirjast konteineri nimega "devops-student1"
# - Kui leidis → käivitab käsu SELLES konteineris
# - Kui ei leidnud → viga: "Error: Instance not found"
```

---

## Täielik Näide

```bash
# Täielik käsk (käsustringi on vaja)
lxc exec devops-student1 -- bash -c "whoami"

# Mis see teeb:
# 1. Ühenda konteinerisse devops-student1
# 2. Käivita seal bash
# 3. Bash käivitab käsu: whoami
# 4. Tulemus tuleb terminali
```

---

## Praktilised Näited

### Lihtsad Käsud

```bash
# Näide 1: Kontrolli kasutajanime
lxc exec devops-student1 -- bash -c "whoami"
# Väljund: root (või labuser, sõltub kontekstist)

# Näide 2: Kontrolli Docker versiooni
lxc exec devops-student1 -- bash -c "docker --version"

# Näide 3: Käivita mitu käsku järjest
lxc exec devops-student1 -- bash -c "cd /home/labuser && ls -la"

# Näide 4: Muuda kasutajat ja käivita käsk
lxc exec devops-student1 -- bash -c "su - labuser -c 'docker ps'"

# Näide 5: Kirjuta faili
lxc exec devops-student1 -- bash -c "echo 'test' > /tmp/test.txt"

# Näide 6: Käivita skript
lxc exec devops-student1 -- bash -c "bash /path/to/script.sh"
```

### Iga Student = Erinev Konteiner

```bash
# Student1 konteineris
lxc exec devops-student1 -- bash -c "hostname"
# Väljund: devops-student1

# Student2 konteineris
lxc exec devops-student2 -- bash -c "hostname"
# Väljund: devops-student2

# Student3 konteineris
lxc exec devops-student3 -- bash -c "hostname"
# Väljund: devops-student3

# K8s Student1 konteineris
lxc exec devops-k8s-student1 -- bash -c "hostname"
# Väljund: devops-k8s-student1
```

---

## Miks `bash -c` on Vajalik?

Võrdle neid:

```bash
# ILMA bash -c (lihtne käsk)
lxc exec devops-student1 -- whoami
# Töötab: käivitab lihtsalt whoami

# BASH -C (keeruline käsk või pipe'id)
lxc exec devops-student1 -- bash -c "cd /home && ls | wc -l"
# Töötab: bash interpreteerib kogu stringi

# ILMA bash -c (ei tööta korrektselt)
lxc exec devops-student1 -- cd /home && ls | wc -l
# EI TÖÖTA: cd käib konteineris, aga ls ja wc käivad host'is!
```

### Millal Kasutada?

**Kasuta `bash -c` kui:**
- ✅ Käsus on pipe'id (`|`)
- ✅ Käsus on redirection (`>`, `>>`, `<`)
- ✅ Käsus on mitu käsku (`&&`, `;`)
- ✅ Käsus on muutujad (`$VAR`)
- ✅ Käsus on shell'i funktsioonid
- ✅ Kasutad `cd` ja seejärel teisi käske

**EI OLE vaja kui:**
- ❌ Lihtne üks käsk: `lxc exec devops-student1 -- whoami`
- ❌ Käsk ilma pipe'ide või redirection'ita

---

## Admin Juhendis Kasutatud Näited

```bash
# Proxy seadistamine
lxc exec devops-student1 -- bash -c "echo 'http_proxy=http://cache1.sss:3128' >> /etc/environment"

# Mitu käsku järjest
lxc exec devops-student1 -- bash -c "apt update && apt upgrade -y"

# Su kasutajana käsk
lxc exec devops-student1 -- bash -c "su - labuser -c 'docker pull alpine:3.16'"
```

---

## Ei Ole Automaatset Valikut

LXD **EI ARVA** ega **EI OTSUSTA** ise - sa pead alati ütlema, millises konteineris käsku käivitada:

```bash
# ❌ EI TÖÖTA - puudub konteineri nimi
lxc exec -- bash -c "whoami"
# Error: missing container name

# ✅ TÖÖTAB - konteineri nimi on olemas
lxc exec devops-student1 -- bash -c "whoami"
```

---

## Konteineri Nimed on Unikaalsed

- Iga konteiner peab omama **unikaalset nime** LXD host'is
- Ei saa olla kahte konteinerit nimega `devops-student1`
- Seepärast on õpilased nummerdatud: `devops-student1`, `devops-student2`, jne

```bash
# Kontrolli, kas konteiner eksisteerib
lxc list devops-student1

# Kui eksisteerib:
+------------------+---------+
|       NAME       |  STATE  |
+------------------+---------+
| devops-student1  | RUNNING |
+------------------+---------+

# Kui ei eksisteeri:
# (tühi tabel)
```

---

## Praktiline Näide: Loop Kõigi Õpilaste Üle

Admin juhendis on sageli vaja käivitada käsku KÕIGIS konteinerites:

```bash
# Käivita käsk igas Student1-6 konteineris
for i in {1..6}; do
  echo "=== Student $i ==="
  lxc exec devops-student$i -- bash -c "docker --version"
done

# Väljund:
=== Student 1 ===
Docker version 24.0.7, build afdd53b
=== Student 2 ===
Docker version 24.0.7, build afdd53b
=== Student 3 ===
Docker version 24.0.7, build afdd53b
...
```

Iga iteratsioonis käivitatakse käsk **erinevas** konteineris:
- `devops-student1`
- `devops-student2`
- `devops-student3`
- jne...

---

## Kokkuvõte

**Vastus lühidalt:**

`lxc exec devops-student1 -- bash -c "<käsk>"` = **Käivita bash shell konteineris ja lase sellel täita käsustring**

LXD teab, millises konteineris käsku käivitada, sest **sa ütled selle käsus selgelt ära**!

```bash
lxc exec <KONTEINERI-NIMI> -- <KÄSK>
          ↑
          └── Siin sa ütled, millises konteineris
```

Pole mingit "default'i" ega "automaatset valikut" - konteineri nimi on **alati** käsu osa.

---

**Loodud:** 2025-12-02
**Kontekst:** DevOps koolituse LXD proxy keskkonna administreerimine
