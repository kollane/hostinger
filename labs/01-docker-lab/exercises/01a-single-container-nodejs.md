# Harjutus 1: Üksiku konteineri loomine (User Service)

**🏗️ Arhitektuurne Lähenemine:**

Selles harjutuses õpid looma **OCI-standardset** (Open Container Initiative) Docker tõmmist, mis sobib kasutamiseks nii Docker'iga kui ka **Kubernetes orkestratsioonisüsteemidega**.

✅ **OCI Standard & Kubernetes Compatible:**
- Multi-stage build (väiksem runtime image)
- `CMD` JSON array formaat (Kubernetes nõue)
- `EXPOSE` dokumenteerib porte (Service discovery)
- Clean runtime (ei leki build-time saladusi)
- Portaabel (töötab Docker, Kubernetes, Podman jne)

📝 **Märkus turvalisuse kohta:** See harjutus keskendub Docker põhitõdedele. **Täielikult OCI-standardne** ja **production-ready** lahendus (sh non-root USER, HEALTHCHECK) tuleb **[Harjutus 5: Tõmmise Optimeerimine](05-optimization.md)**, kus lisame Kubernetes Pod Security Standards'ile vastava turvalisuse.

---

**User Service'i rakenduse lühitutvustus:**
- 🔐 Registreerib uusi kasutajaid
- 🎫 Loob JWT "token"-eid (digitaalsed tõendid)
- ✅ Kontrollib kasutajate õigusi (user/admin roll)
- 💾 Salvestab kasutajate andmed PostgreSQL andmebaasi
  
**📖 Rakenduse funktsionaalsuse kohta lähemalt siit:** [User Service README](../../apps/backend-nodejs/README.md)

---
## 📋 Harjutuse ülevaade

**Harjutuse eesmärk:** Node.js kasutajahalduse rakenduse (User Service) konteineriseerimine ja Dockerfile'i loomine

**Harjutuse Fookus:** See harjutus keskendub Docker põhitõdede õppimisele, MITTE töötavale rakendusele!


✅ **Õpid:**
- Dockerfile'i loomist Node.js **rakendusele (application)**
- Docker **tõmmise (docker image)** ehitamist
- **Konteineri** käivitamist
- **Logide (logs)** vaatamist ja **veatuvastust (debug)**

❌ **Käesolevas harjutuses rakendus veel TÖÖLE EI HAKKA:**
- User Service vajab PostgreSQL andmebaasi
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
│  │  Node.js Rakendus     │  │
│  │  User Service         │  │
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

Vaata "User Service" koodi:

```bash
cd ~/labs/apps/backend-nodejs
```
```bash
# Vaata faile
ls -la
```
```bash
# Loe README
cat README.md
```
```bash
# Vaata server.js
head -50 server.js
```

**Küsimused:**
- Millise pordiga rakendus käivitub? (3000)
- Millised sõltuvused (dependencies) on vajalikud? (vaata package.json)
- Kas rakendus vajab andmebaasi? (Jah, PostgreSQL)

### Samm 2: Dockerfile loomine

---

Lihtne 1-stage Dockerfile näidis avaliku võrgu jaoks (VPS):

```dockerfile
FROM node:22-slim

WORKDIR /app

# Kopeeri sõltuvuste failid
COPY package*.json ./

# Installi sõltuvused
RUN npm install --production

# Kopeeri rakenduse kood
COPY . .

# Avalda port
EXPOSE 3000

# Käivita
CMD ["node", "server.js"]
```

⚠️ **Märkus:** See on NÄIDIS VPS avaliku võrgu jaoks. Laboris kasuta järgmist näidist (corporate keskkond)!

**📖 Dockerfile põhitõed:** Kui vajad abi Dockerfile instruktsioonide (FROM, WORKDIR, COPY, RUN, CMD, ARG, multi-stage) mõistmisega, loe [Peatükk 06: Dockerfile - Rakenduste Konteineriseerimise Detailid](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md).

---

#### Dockerfile loomine Corporate Keskkond (PRIMAARNE) ⭐

**⚠️ Oluline:** Dockerfail tuleb luua rakenduse juurkataloogi `~/labs/apps/backend-nodejs`.
```bash
cd ~/labs/apps/backend-nodejs
```

**Kasutame laboris** 2-stage ehitus ARG proksiga:
```bash
vim Dockerfile
```

```dockerfile
# ====================================
# 1. etapp: Builder (sõltuvuste installimine)
# ====================================
FROM node:22-slim AS builder

# ARG võimaldab anda proxy build-time'is (portaabel!)
ARG HTTP_PROXY
ARG HTTPS_PROXY

# ENV ainult builder etapis (ei leki runtime'i!)
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY}

WORKDIR /app

# Kopeeri sõltuvuste failid
COPY package*.json ./

# Installi sõltuvused (kasutab proxy't, kui antud)
RUN npm install --production

# ====================================
# 2. etapp: Runtime (clean, ilma proksita)
# ====================================
FROM node:22-slim AS runtime

WORKDIR /app

# Kopeeri node_modules builder'ist
COPY --from=builder /app/node_modules ./node_modules

# Kopeeri rakenduse kood
COPY . .

# Avalda port
EXPOSE 3000

# Keskkond
ENV NODE_ENV=production

# Käivita rakendus
CMD ["node", "server.js"]
```

**📖 Põhjalik koodi selgitus:**

Kui vajad ülaloleva Dockerfile'i täpset rea-haaval selgitust (mida teevad ARG, ENV, mitmeastmeline build jne), loe:
- 👉 **[Koodiselgitus: Node.js Dockerfile Proxy Pattern](../../../resource/code-explanations/Node.js-Dockerfile-Proxy-Explained.md)**

**Selgitus käsitleb:**
- ✅ Miks kasutada ARG'd (build-time proxy)
- ✅ Kuidas ENV töötab builder etapis
- ✅ Miks mitmeastmeline build väldib proxy lekkimist
- ✅ Iga Dockerfile instruktsioon üksikasjalikult

---

**💡 Näidislahendused:**

Lahendused asuvad `solutions/backend-nodejs/` kaustas:
- [`Dockerfile.simple`](../solutions/backend-nodejs/Dockerfile.simple) - 2-stage ARG proksiga (PRIMAARNE)
- [`Dockerfile.vps-simple`](../solutions/backend-nodejs/Dockerfile.vps-simple) - 1-stage VPS (avalik võrk)

📂 Kõik lahendused: [`solutions/backend-nodejs/`](../solutions/backend-nodejs/)

---

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

### Samm 4: Ehita Docker tõmmis


**⚠️ Oluline:** Docker tõmmise ehitamiseks pead olema rakenduse juurkataloogis (kus asub `Dockerfile`).

```bash
cd ~/labs/apps/backend-nodejs
```

**Ehita proksiga (corporate võrk):**
```bash
# Asenda oma proxy aadress!
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -t user-service:1.0 .

# Vaata ehitamise protsessi
# Märka: iga RUN käsk loob uue kihi (layer)
```

**Ehita ilma proksita (avalik võrk):**
```bash
docker build -t user-service:1.0 .
# ARG-id jäävad tühjaks, npm install töötab avalikus võrgus
```

**Kontrolli: Kas proxy leak'ib runtime'i?**
```bash
docker run --rm user-service:1.0 env | grep -i proxy
# Oodatud: TÜHI VÄLJUND! ✅
# Proxy EI OLE runtime'is = clean, turvaline, portaabel!
```

**Kontrolli tõmmist:**

```bash
# Vaata kõiki tõmmiseid
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

**ℹ️ Portide turvalisus:**

Selles harjutuses kasutame lihtsustatud portide vastendust (`-p 3000:3000`).
- ✅ **Etteveõtte sisevõrk kaitseb**
- 📚 **Tootmises oleks õige:** `-p 127.0.0.1:3000:3000` (avab pordi ainult localhost'il)
- 🎯 **Lab 2 käsitleb:** Võrguturvalisust ja reverse proxy seadistust

**Hetkel keskendume Docker põhitõdedele!**

---

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
```

### Samm 6: Veatuvastus ja tõrkeotsing

```bash
# Vaata kas töötab
docker ps

# Vaata konteineri staatust
docker ps -a

# Vaata logisid
docker logs user-service

# Vaata reaalajas
docker logs -f user-service

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
**Miks konteiner puudub `docker ps` väljundis?**
- Konteiner käivitus, aga rakendus hangus kohe
- Docker peatas hangunud konteineri automaatselt
- `docker ps` näitab ainult TÖÖTAVAID konteinereid
- `docker ps -a` näitab KÕIKI konteinereid (ka peatatud)


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

   # Vaata võrku (docker network)
   docker inspect user-service | grep IPAddress
   ```

---

## 💡 Parimad Praktikad (Best Practices)

1. **Kasuta `.dockerignore`** - Väldi tarbetute failide kopeerimist
2. **Kasuta alpine tõmmiseid** - Väiksem suurus, kiirem
3. **`RUN npm install --production`** - Ära installi arenduse sõltuvusi (dev dependencies)
4. **`COPY package.json` enne koodi** - Parem kihtide vahemälu (layer cache) kasutamine
5. **Kasuta `EXPOSE`** - Dokumenteeri, millist porti rakendus kasutab

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
