# Harjutus 1: Üksiku konteineri loomine (User Service)

**Eesmärk:** Node.js kasutajahalduse rakenduse konteineriseerimine ja Dockerfile'i loomine

**Mida User Service teeb::**
- 🔐 Registreerib uusi kasutajaid
- 🎫 Loob JWT tokeneid (digitaalsed tõendid)
- ✅ Kontrollib kasutajate õigusi (user/admin roll)
- 💾 Salvestab kasutajate andmed PostgreSQL andmebaasi
  
**📖 Rakenduse funktsionaalsuse kohta lähemalt lugeda siit:** [User Service README](../../apps/backend-nodejs/README.md)

---

## ⚠️ OLULINE: Harjutuse Fookus

**See harjutus keskendub Docker põhitõdede õppimisele, MITTE töötavale rakendusele (application)!**

✅ **Õpid:**
- Dockerfile'i loomist Node.js rakendusele (application)
- Docker pildi (image) ehitamist (build)
- Konteineri käivitamist
- Logide vaatamist ja debuggimist

❌ **Käesolevas harjutuses rakendus veel TÖÖLE EI HAKKA:**
- User teenus (service) vajab PostgreSQL andmebaasi
- Konteiner käivitub, aga hangub kohe (see on **OODATUD**)
- Töötava rakendus tekib peale **Harjutus 2** läbimist.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua Dockerfile'i Node.js rakendusele (application)
- ✅ Ehitada (build) Docker pilti (image)
- ✅ Käivitada ja peatada konteinereid
- ✅ Kasutada keskkonna muutujaid (environment variables)
- ✅ Vaadata konteineri logisid
- ✅ Debuggida konteineri probleeme

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
│  │  Node.js Rakendus (Application)  │  │
│  │  User Teenus (Service)         │  │
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

**Rakenduse (application) juurkataloog:** `~/labs/apps/backend-nodejs`

Vaata rakenduse (application) "User Teenus (Service)" koodi:

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
- Millise pordiga rakendus (application) käivitub? (3000)
- Millised sõltuvused (dependencies) on vajalikud? (vaata package.json)
- Kas rakendus (application) vajab andmebaasi? (Jah, PostgreSQL)

### Samm 2: Loo Dockerfile

Loo fail nimega `Dockerfile`:

**⚠️ Oluline:** Dockerfail tuleb luua rakenduse (application) juurkataloogi `~/labs/apps/backend-nodejs`. 

```bash
vim Dockerfile
```

**📖 Dockerfile põhitõed:** Kui vajad abi Dockerfile instruktsioonide (FROM, WORKDIR, COPY, RUN, CMD) mõistmisega, loe [Peatükk 06: Dockerfile - Rakenduste Konteineriseerimise Detailid](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md).

**Ülesanne:** Kirjuta Dockerfile, mis:
1. Kasutab Node.js 22 slim baaspilti (base image)
2. Seadistab töökataloogiks `/app`
3. Kopeerib `package*.json` failid
4. Installib sõltuvused (dependencies)
5. Kopeerib rakenduse (application) koodi
6. Avaldab pordi 3000
7. Käivitab rakenduse (application)

**Vihje:** Vaata Docker dokumentatsiooni või solutions/ kausta!

**Näidis:**

```dockerfile
FROM node:22-slim

WORKDIR /app

# Kopeeri sõltuvuste (dependency) failid
COPY package*.json ./

# Paigalda sõltuvused (dependencies)
RUN npm install --production

# Kopeeri rakenduse (application) kood
COPY . .

# Avalda port
EXPOSE 3000

# Käivita
CMD ["node", "server.js"]
```

### Samm 3: Loo .dockerignore

Loo `.dockerignore` fail, et vältida tarbetute failide kopeerimist:

**⚠️ Oluline:** .dockerignore tuleb luua rakenduse (application) juurkataloogi `~/labs/apps/backend-nodejs`. 

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
- Väiksem pildi (image) suurus
- Kiirem ehitamine (build)
- Turvalisem (ei kopeeri .env faile)

### Samm 4: Ehita (build) Docker pilt (image)

**Asukoht:** `~/labs/apps/backend-nodejs`

Ehita (build) oma esimene Docker pilt (image):

**⚠️ Oluline:** Docker pildi (image) ehitamiseks (build) pead olema rakenduse (application) juurkataloogis (kus asub `Dockerfile`).

```bash
# Ehita (build) pilt (image) tag'iga
docker build -t user-service:1.0 .

# Vaata ehitamise (build) protsessi
# Märka: iga RUN käsk loob uue kihi (layer)
```

**Kontrolli pilti (image):**

```bash
# Vaata kõiki pilte (images)
docker images

# Vaata user-service pildi (image) infot
docker image inspect user-service:1.0

# Kontrolli suurust
docker images user-service:1.0
```

**Küsimused:**
- Kui suur on sinu pilt (image)? (peaks olema ~150-200MB)
- Mitu kihti (layers) on pildil (image)?
- Millal pilt (image) loodi?

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
- `-p 3000:3000` - portide vastendamine (port mapping) 3000 host'ist konteinerisse
- `-e` - keskkonna muutuja (environment variable)

**Oodatud tulemus:**
```
❌ Failed to connect to the database
connect ECONNREFUSED 127.0.0.1:5432
```

**See on TÄPSELT see, mida tahame näha!** 🎉
- Konteiner käivitus ✅
- Rakendus (application) proovis käivituda ✅
- Vea (error) sõnum näitab probleemi (puuduv DB) ✅
- Õppisid, kuidas Docker vigu (errors) näeb ✅

Vajuta `Ctrl+C` et peatada.

#### Variant B: Taustal töötav režiim (Detached Mode)

```bash
# Käivita taustal (taustal töötav režiim (detached mode))
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
- Konteiner käivitus, aga rakendus (application) hangus kohe
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

2. **Rakendus (application) hangub:**
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
2. **Kasuta alpine pilte (images)** - Väiksem suurus, kiirem
3. **RUN npm install --production** - Ära installi arenduse sõltuvusi (dev dependencies)
4. **COPY package.json enne koodi** - Parem kihtide vahemälu (layer cache) kasutamine
5. **Kasuta EXPOSE** - Dokumenteeri, millist porti rakendus (application) kasutab

**📖 Node.js konteineriseerimise parimad tavad:** Põhjalikum käsitlus `npm ci`, Alpine images, bcrypt native moodulid, ja teised Node.js spetsiifilised teemad leiad [Peatükk 06A: Java Spring Boot ja Node.js Konteineriseerimise Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md).

---

**Õnnitleme! Oled loonud oma esimese Docker pildi (image)! 🎉**

## 🔗 Järgmine Samm

Järgmises harjutuses konteineriseerid Java Spring Boot tehnoloogial põhineva Todo märkmete rakenduse!

**Jätka:** [Harjutus 1B: Üksik-Konteiner-Java (Single-Container-Java)](https://github.com/kollane/hostinger/blob/master/labs/01-docker-lab/exercises/01b-single-container-java.md)

---

## 📚 Viited

- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Docker run reference](https://docs.docker.com/engine/reference/run/)
- [Node.js Docker parimad praktikad (best practices)](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)
