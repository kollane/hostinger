# Harjutus 1: Single Container

**Kestus:** 45 minutit
**Eesmärk:** Konteinerise Node.js User Service ja õpi Dockerfile'i loomist

---

## 📋 Ülevaade

Selles harjutuses konteineriseerid Node.js User Service rakenduse. Õpid looma Dockerfile'i, build'ima Docker image'i ja käivitama containerit.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua Dockerfile'i Node.js rakendusele
- ✅ Build'ida Docker image'i
- ✅ Käivitada ja peatada containereid
- ✅ Kasutada environment variables
- ✅ Vaadata container logisid
- ✅ Debuggida container probleeme

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────┐
│   Docker Container          │
│                             │
│  ┌───────────────────────┐  │
│  │  Node.js Application  │  │
│  │  User Service         │  │
│  │  Port: 3000           │  │
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
          │
          │ Port mapping
          │
    localhost:3000
```

---

## 📝 Sammud

### Samm 1: Tutvu Rakendusega (5 min)

Vaata User Service koodi:

```bash
cd ../../apps/backend-nodejs

# Vaata faile
ls -la

# Loe README
cat README.md

# Vaata server.js
head -50 server.js
```

**Küsimused:**
- Millise pordiga rakendus käivitub? (3000)
- Millised sõltuvused on vajalikud? (vaata package.json)
- Kas rakendus vajab andmebaasi? (Jah, PostgreSQL)

### Samm 2: Loo Dockerfile (15 min)

Loo fail nimega `Dockerfile`:

```bash
nano Dockerfile
```

**Ülesanne:** Kirjuta Dockerfile, mis:
1. Kasutab Node.js 18 alpine base image'i
2. Seadistab töökataloogiks `/app`
3. Kopeerib `package*.json` failid
4. Installib sõltuvused
5. Kopeerib rakenduse kood
6. Avaldab pordi 3000
7. Käivitab rakenduse

**Vihje:** Vaata Docker dokumentatsiooni või solutions/ kausta!

<details>
<summary>💡 Näpunäide: Dockerfile struktuur</summary>

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Kopeeri dependency files
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
</details>

### Samm 3: Loo .dockerignore (5 min)

Loo `.dockerignore` fail, et vältida tarbetute failide kopeerimist:

```bash
nano .dockerignore
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
- Väiksem image suurus
- Kiirem build
- Turvalisem (ei kopeeri .env faile)

### Samm 4: Build Docker Image (10 min)

Build'i oma esimene Docker image:

```bash
# Build image tagiga
docker build -t user-service:1.0 .

# Vaata build protsessi
# Märka: iga RUN käsk loob uue layer
```

**Kontrolli image'i:**

```bash
# Vaata kõiki image'id
docker images

# Vaata user-service image infot
docker image inspect user-service:1.0

# Kontrolli suurust
docker images user-service:1.0
```

**Küsimused:**
- Kui suur on sinu image? (peaks olema ~150-200MB)
- Mitu layer'it on image'il?
- Millal image loodi?

### Samm 5: Käivita Container (10 min)

#### Variant A: Ilma andmebaasita (testimiseks)

```bash
# Käivita container interaktiivselt
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
- `--name` - anna containerile nimi
- `-p 3000:3000` - map port 3000 host'ist container'isse
- `-e` - environment variable

**Probleam:** Rakendus ei käivitu, sest PostgreSQL puudub!

#### Variant B: Background režiimis

```bash
# Käivita taustal (detached mode)
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

**Probleam:** Kui PostgreSQL ei tööta, siis rakendus crashib!

### Samm 6: Debug ja Troubleshoot (5 min)

```bash
# Vaata container statusit
docker ps -a

# Vaata logisid
docker logs user-service

# Sisene containerisse
docker exec -it user-service sh

# Container sees:
ls -la
cat package.json
env | grep DB
exit

# Inspekteeri containerit
docker inspect user-service

# Vaata resource kasutust
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

2. **Rakendus crashib:**
   ```bash
   # Vaata logisid
   docker logs user-service

   # Tõenäoliselt puudub PostgreSQL
   ```

3. **Ei saa ühendust:**
   ```bash
   # Kontrolli, kas container töötab
   docker ps

   # Vaata network't
   docker inspect user-service | grep IPAddress
   ```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Dockerfile** backend-nodejs/ kaustas
- [ ] **.dockerignore** fail
- [ ] **Docker image** `user-service:1.0` (vaata `docker images`)
- [ ] **Container** käivitatud (vaata `docker ps`)
- [ ] Mõistad Dockerfile'i struktuuri
- [ ] Oskad build'ida image'i
- [ ] Oskad käivitada containerit
- [ ] Oskad vaadata logisid

---

## 🧪 Testimine

### Test 1: Kas image on loodud?

```bash
docker images | grep user-service
# Peaks näitama: user-service 1.0 ...
```

### Test 2: Kas container töötab?

```bash
docker ps | grep user-service
# Peaks näitama töötavat containerit
```

### Test 3: Kas rakendus vastab?

**Märkus:** See ei tööta ilma PostgreSQL'ita!

```bash
curl http://localhost:3000/health
# Oodatud vastus:
# {
#   "status": "ERROR",
#   "database": "disconnected"
# }
```

---

## 🎓 Õpitud Mõisted

### Dockerfile instruktsioonid:

- `FROM` - Base image
- `WORKDIR` - Töökataloog
- `COPY` - Kopeeri failid
- `RUN` - Käivita käsk build ajal
- `EXPOSE` - Avalda port
- `CMD` - Käivita käsk container start'imisel

### Docker käsud:

- `docker build` - Build image
- `docker run` - Käivita container
- `docker ps` - Näita töötavaid containereid
- `docker logs` - Vaata container logisid
- `docker exec` - Käivita käsk töötavas containeris
- `docker inspect` - Vaata container/image infot

---

## 💡 Parimad Tavad

1. **Kasuta `.dockerignore`** - Väldi tarbetute failide kopeerimist
2. **Kasuta alpine images** - Väiksem suurus, kiirem
3. **RUN npm install --production** - Ära installi dev dependencies
4. **COPY package.json enne koodi** - Parem layer caching
5. **Kasuta EXPOSE** - Dokumenteeri, millist porti rakendus kasutab

---

## 🔗 Järgmine Samm

Järgmises harjutuses lisame PostgreSQL containeri ja ühendame kaks containerit!

**Jätka:** [Harjutus 2: Multi-Container](02-multi-container.md)

---

## 📚 Viited

- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Docker run reference](https://docs.docker.com/engine/reference/run/)
- [Node.js Docker best practices](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)

---

**Õnnitleme! Oled loonud oma esimese Docker image'i! 🎉**
