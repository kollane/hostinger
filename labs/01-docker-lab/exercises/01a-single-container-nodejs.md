# Harjutus 1: Üksiku konteineri loomine (User Service)

**User Service rakenduse lühitutvustus:**
- 🔐 Registreerib uusi kasutajaid
- 🎫 Loob JWT tokeneid (digitaalsed tõendid)
- ✅ Kontrollib kasutajate õigusi (user/admin roll)
- 💾 Salvestab kasutajate andmed PostgreSQL andmebaasi
  
**📖 Rakenduse funktsionaalsuse kohta lähemalt siit:** [User Service README](../../apps/backend-nodejs/README.md)

---
## 📋 Harjutuse ülevaade

**Harjutuse eesmärk:** Node.js kasutajahalduse rakenduse konteineriseerimine ja Dockerfile'i loomine

**Harjutuse Fookus:** See harjutus keskendub Docker põhitõdede õppimisele, MITTE töötavale rakendusele!**


✅ **Õpid:**
- Dockerfile'i loomist Node.js rakendusele (application)
- Docker tõmmise (image) ehitamist
- Konteineri käivitamist
- Logide vaatamist ja debuggimist

❌ **Käesolevas harjutuses rakendus veel TÖÖLE EI HAKKA:**
- User teenus (service) vajab PostgreSQL andmebaasi
- Konteiner käivitub, aga hangub kohe (see on **OODATUD**)
- Töötav rakendus valmib peale **Harjutus 2** läbimist.

---

## 🖥️ Sinu Testimise Konfiguratsioon

### SSH Ühendus VPS-iga
```bash
ssh labuser@93.127.213.242 -p [SINU-PORT]
```

| Õpilane | SSH Port | Password |
|---------|----------|----------|
| student1 | 2201 | student1 |
| student2 | 2202 | student2 |
| student3 | 2203 | student3 |

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────┐
│   Docker Konteiner          │
│                             │
│  ┌───────────────────────┐  │
│  │  Node.js Rakendus            │  │
│  │  User Teenus                 │  │
│  │  Port: 3000           │  │
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
          │
          │ Portide vastendamine
          │ (Port mapping)
    localhost:3000
```

---

## 📝 Sammud

### Samm 1: Tutvu rakenduse koodiga

**Rakenduse juurkataloog:** `~/labs/apps/backend-nodejs`

Vaata "User Teenuse" (service) koodi:

```bash
cd ~/labs/apps/backend-nodejs

# Vaata faile
ls -la

# Loe README
cat README.md

# Vaata server.js
head -50 server.js
```

**Küsimused:**
- Millise pordiga rakendus käivitub? (3000)
- Millised sõltuvused (dependencies) on vajalikud? (vaata package.json)
- Kas rakendus vajab andmebaasi? (Jah, PostgreSQL)

### Samm 2: Loo Dockerfile

Loo fail nimega `Dockerfile`:

**⚠️ Oluline:** Dockerfail tuleb luua rakenduse juurkataloogi `~/labs/apps/backend-nodejs`. 

```bash
vim Dockerfile
```

**📖 Dockerfile põhitõed:** Kui vajad abi Dockerfile instruktsioonide (FROM, WORKDIR, COPY, RUN, CMD) mõistmisega, loe [Peatükk 06: Dockerfile - Rakenduste Konteineriseerimise Detailid](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md).

**Ülesanne:** Kirjuta Dockerfile, mis:
1. Kasutab Node.js 22 slim baastõmmist (base image)
2. Seadistab töökataloogiks `/app`
3. Kopeerib `package*.json` failid
4. Installib sõltuvused
5. Kopeerib rakenduse koodi
6. Avaldab pordi 3000
7. Käivitab rakenduse

**Vihje:** Vaata Docker dokumentatsiooni või solutions/ kausta!

**Näidis:**

```dockerfile
FROM node:22-slim

WORKDIR /app

# Kopeeri sõltuvuste failid
COPY package*.json ./

# Paigalda sõltuvused
RUN npm install --production

# Kopeeri rakenduse kood
COPY . .

# Avalda port
EXPOSE 3000

# Käivita
CMD ["node", "server.js"]
```

### Samm 3: Loo .dockerignore

Loo `.dockerignore` fail, et vältida tarbetute failide kopeerimist:

**⚠️ Oluline:** .dockerignore tuleb luua rakenduse juurkataloogi `~/labs/apps/backend-nodejs`. 

```bash
vim .dockerignore
```

**Sisu:**
```
node_modules
npm-debug.log
.env
.git
.gitignore
README.md
*.md
```

**Miks see oluline on?**
- Väiksem tõmmise suurus
- Kiirem ehitamine
- Turvalisem (ei kopeeri .env faile)

### Samm 4: Koosta (build) Docker tõmmis (image)

**Asukoht:** `~/labs/apps/backend-nodejs`

Koosta oma esimene Docker tõmmis (image):

**⚠️ Oluline:** Docker tõmmise ehitamiseks pead olema rakenduse juurkataloogis (kus asub `Dockerfile`).

```bash
# Koosta tõmmis sildiga (tag)
docker build -t user-service:1.0 .

# Vaata ehitamise protsessi
# Märka: iga RUN käsk loob uue kihi (layer)
```

**Kontrolli tõmmist:**

```bash
# Vaata kõiki tõmmiseid (images)
docker images

# Vaata user-service tõmmise infot
docker image inspect user-service:1.0

# Kontrolli suurust
docker images user-service:1.0
```

**Küsimused:**
- Kui suur on sinu tõmmis? (peaks olema ~150-200MB)
- Mitu kihti (layers) on tõmmisel?
- Millal tõmmis loodi?

### Samm 5: Käivita Konteiner

#### Variant A: Ilma andmebaasita (testimiseks)

```bash
# Käivita konteiner interaktiivselt
docker run -it --name user-service-test \
  -p 3000:3000 \
  -e DB_HOST=localhost \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=test-secret \
  user-service:1.0
```

**Märkused:**
- `-it` - interactive + tty
- `--name` - anna konteinerile nimi
- `-p 3000:3000` - portide vastendamine hostist konteinerisse
- `-e` - keskkonna muutuja

**Oodatud tulemus:**
```
❌ Failed to connect to the database
connect ECONNREFUSED 127.0.0.1:5432
```

**See on TÄPSELT see, mida tahame näha!** 🎉
- Konteiner käivitus ✅
- Rakendus proovis käivituda ✅
- Veateade näitab probleemi (puuduv DB) ✅
- Õppisid, kuidas Docker vigu näeb ✅

Vajuta `Ctrl+C` et peatada.

#### Variant B: Taustal töötav režiim (Detached Mode)

```bash
# Käivita taustal ehk detached režiimis (-d)
docker run -d --name user-service \
  -p 3000:3000 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=test-secret-key \
  -e NODE_ENV=production \
  user-service:1.0

# Vaata kas töötab
docker ps

# Vaata logisid
docker logs user-service

# Vaata reaalajas
docker logs -f user-service
```

**Oodatud:** Konteiner hangub, sest PostgreSQL puudub! See on ÕIGE käitumine!

```bash
# Vaata kas töötab? (HINT: Ei tööta!)
docker ps

# Vaata ka peatatud konteinereid
docker ps -a
# STATUS peaks olema: Exited (1)
```

**Miks konteiner puudub `docker ps` väljundis?**
- Konteiner käivitus, aga rakendus hangus kohe
- Docker peatas hangunud konteineri automaatselt
- `docker ps` näitab ainult TÖÖTAVAID konteinereid
- `docker ps -a` näitab KÕIKI konteinereid (ka peatatud)

### Samm 6: Debug ja Troubleshoot

```bash
# Vaata konteineri staatust
docker ps -a

# Vaata logisid
docker logs user-service

# Sisene konteinerisse
docker exec -it user-service sh

# Konteineri sees:
ls -la
cat package.json
env | grep DB
exit

# Inspekteeri konteinerit
docker inspect user-service

# Vaata ressursikasutust
docker stats user-service
```

**Levinud probleemid:**

1. **Port on juba kasutusel:**
   ```bash
   # Vaata, mis kasutab porti 3000
   sudo lsof -i :3000

   # Kasuta teist porti
   docker run -p 3001:3000 ...
   ```

2. **Rakendus hangub:**
   ```bash
   # Vaata logisid
   docker logs user-service

   # Tõenäoliselt puudub PostgreSQL
   ```

3. **Ei saa ühendust:**
   ```bash
   # Kontrolli, kas konteiner töötab
   docker ps

   # Vaata võrku (network)
   docker inspect user-service | grep IPAddress
   ```

---

## 💡 Parimad Praktikad (Best Practices)

1. **Kasuta `.dockerignore`** - Väldi tarbetute failide kopeerimist
2. **Kasuta alpine tõmmiseid (images)** - Väiksem suurus, kiirem
3. **RUN npm install --production** - Ära installi arenduse sõltuvusi (dev dependencies)
4. **COPY package.json enne koodi** - Parem kihtide vahemälu (layer cache) kasutamine
5. **Kasuta EXPOSE** - Dokumenteeri, millist porti rakendus kasutab

**📖 Node.js konteineriseerimise parimad tavad:**Põhjalikum käsitlus `npm ci`, Alpine images, bcrypt native moodulid, ja teised Node.js spetsiifilised teemad leiad [Peatükk 06A: Java Spring Boot ja Node.js Konteineriseerimise Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md).

---

**Õnnitleme! Oled loonud oma esimese Docker tõmmise! 🎉**

## 🔗 Järgmine Samm

Järgmises harjutuses konteineriseerid Java Spring Boot tehnoloogial põhineva Todo märkmete rakenduse!

**Jätka:** [Harjutus 1B: Üksik-Konteiner-Java (Single-Container-Java)](https://github.com/kollane/hostinger/blob/master/labs/01-docker-lab/exercises/01b-single-container-java.md)

---

## 📚 Viited

- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Docker run reference](https://docs.docker.com/engine/reference/run/)
- [Node.js Docker parimad praktikad (best practices)](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)