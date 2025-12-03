# Proxy-Aware Docker Builds - User Service (Node.js)

## Ülevaade

Corporate keskkonnas on otseühendus internetti sageli blokeeritud turvalisuse pärast. Kõik HTTP/HTTPS päringud peavad minema läbi **proksi serveri** (nt. `cache1.sss:3128`). See mõjutab Docker build'e, kuna npm peab pääsema `registry.npmjs.org`'i paketite allalaadimiseks.

**Probleem:**
```bash
docker build -t user-service:1.0 .

# Viga:
npm ERR! network request to https://registry.npmjs.org/express failed
npm ERR! network This is most likely not a problem with npm itself
npm ERR! network and is related to network connectivity.
```

**Lahendus:**
See kaust sisaldab **kolme erinevat lähenemist** proksi konfigureerimiseks Docker build'ides.

---

## Dockerfile Variandid

### 1. Dockerfile.optimized.proxy (✅ RECOMMENDED)

**Tüüp:** ARG-põhine, multi-stage
**Image suurus:** ~305MB
**Portaabel:** ✅ Jah (töötab proksi ja ilma)
**Production-ready:** ✅ Jah

**Eelised:**
- ✅ Töötab MÕLEMAS keskkonnas (proksi ja ilma)
- ✅ Proxy AINULT build-time ajal (ei leki runtime'i)
- ✅ Turvaline (runtime clean)
- ✅ Multi-stage optimeerimisega (dependencies eraldi)
- ✅ Non-root user (nodejs:1001)
- ✅ Health check

**Build käsud:**

```bash
cd /home/janek/projects/hostinger/labs/01-docker-lab/solutions/backend-nodejs

# PROKSIGA (corporate võrk):
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  --build-arg NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16 \
  -f Dockerfile.optimized.proxy \
  -t user-service:1.0-optimized \
  ../../../apps/backend-nodejs

# ILMA PROKSITA (arendaja masinas):
docker build \
  -f Dockerfile.optimized.proxy \
  -t user-service:1.0-optimized \
  ../../../apps/backend-nodejs
```

**Test runtime (veendu, et proxy ei leki):**

```bash
docker run --rm user-service:1.0-optimized env | grep -i proxy

# EXPECTED: Tühi väljund (ei leia midagi) ✅
# Kui näed HTTP_PROXY=..., siis proxy leak'is! ⚠️
```

---

### 2. Dockerfile.proxy (Lihtne Variant)

**Tüüp:** ARG-põhine, single-stage
**Image suurus:** ~305MB
**Portaabel:** ✅ Jah
**Production-ready:** ⚠️ Ei (proxy leak'ib runtime'i)

**Eelised:**
- ✅ Lihtne mõista (kõik ühes stage'is)
- ✅ Töötab proksi ja ilma
- ✅ Hea õppimiseks

**Puudused:**
- ❌ Proxy muutujad jäävad runtime'i (ei ole ideaalne)
- ❌ Ei ole kihtide vahemäluga (layer caching) optimeeritud

**Build käsk:**

```bash
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f Dockerfile.proxy \
  -t user-service:1.0-simple \
  ../../../apps/backend-nodejs
```

**Kasutus:** Õppimiseks ja testimiseks, mitte tootmiseks.

---

### 3. Dockerfile.proxy-hardcoded (❌ ANTI-PATTERN)

**Tüüp:** Hardcoded ENV
**Image suurus:** ~305MB
**Portaabel:** ❌ EI (ainult cache1.sss võrgus)
**Production-ready:** ❌ EI

**Probleemid:**
- ❌ Töötab AINULT cache1.sss võrgus
- ❌ Arendaja masinas ebaõnnestub
- ❌ Proxy leak'ib runtime'i (turvaviga)
- ❌ Ei ole taaskasutatav teistes keskkondades
- ❌ Tekitab technical debt

**Miks see eksisteerib corporate keskkonnas?**
- Quick fix surve all (deadline'id)
- Arendaja ei tea paremat meetodit
- "It works, don't touch it" kultuur
- Copy-paste StackOverflow'st

**Build käsk (DEMONSTRATSIOONIKS):**

```bash
docker build \
  -f Dockerfile.proxy-hardcoded \
  -t user-service:1.0-hardcoded \
  ../../../apps/backend-nodejs
```

**⚠️ Ära kasuta tootmises!** See on AINULT demonstratsiooniks, et näidata mida MITTE teha.

---

## Build Käsud ja Näited

### Näide 1: Ehita Lab 1 Harjutuseks 1a (proksiga)

```bash
cd /home/janek/projects/hostinger/labs/01-docker-lab/solutions/backend-nodejs

# Ehita optimeeritud variant proksiga
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  --build-arg NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16 \
  -f Dockerfile.optimized.proxy \
  -t user-service:1.0 \
  ../../../apps/backend-nodejs

# Kontrolli image suurust
docker images | grep user-service

# Testi runtime (ei tohi olla proxy vars)
docker run --rm user-service:1.0 env | grep -i proxy
# EXPECTED: Tühi väljund ✅
```

### Näide 2: Ehita ilma proksita (arendaja masinas)

```bash
# Sama Dockerfile, ILMA build-arg'ideta
docker build \
  -f Dockerfile.optimized.proxy \
  -t user-service:1.0 \
  ../../../apps/backend-nodejs

# Töötab ilma proksita! ✅
```

### Näide 3: Võrdle variante

```bash
# Ehita kõik kolm varianti
docker build -f Dockerfile.optimized.proxy --build-arg HTTP_PROXY=http://cache1.sss:3128 --build-arg HTTPS_PROXY=http://cache1.sss:3128 -t user-service:optimized ../../../apps/backend-nodejs
docker build -f Dockerfile.proxy --build-arg HTTP_PROXY=http://cache1.sss:3128 --build-arg HTTPS_PROXY=http://cache1.sss:3128 -t user-service:simple ../../../apps/backend-nodejs
docker build -f Dockerfile.proxy-hardcoded -t user-service:hardcoded ../../../apps/backend-nodejs

# Võrdle suurusi
docker images | grep user-service

# EXPECTED:
# user-service:optimized   ~305MB
# user-service:simple      ~305MB
# user-service:hardcoded   ~305MB
# (suurus on sama, aga käitumine erineb!)

# Kontrolli runtime proxy leak'i
echo "=== Optimized (peaks olema clean) ==="
docker run --rm user-service:optimized env | grep -i proxy

echo "=== Simple (proxy võib olla) ==="
docker run --rm user-service:simple env | grep -i proxy

echo "=== Hardcoded (proxy ON ALATI) ==="
docker run --rm user-service:hardcoded env | grep -i proxy
```

---

## Troubleshooting

### Viga 1: npm ERR! network request to https://registry.npmjs.org failed

**Sümptom:**
```
npm ERR! network request to https://registry.npmjs.org/express failed, reason: connect ETIMEDOUT 104.16.16.35:443
npm ERR! network This is most likely not a problem with npm itself
npm ERR! network and is related to network connectivity.
```

**Põhjus:**
Corporate firewall blokeerib otseühenduse npmjs.org'i. Paketid peavad minema läbi proksi (cache1.sss:3128).

**Lahendus 1: Kasuta Dockerfile.optimized.proxy build arg'idega**

```bash
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f Dockerfile.optimized.proxy \
  -t user-service:1.0 \
  ../../../apps/backend-nodejs
```

**Lahendus 2: Kontrolli, kas proxy on kättesaadav**

```bash
# Test proxy ühendust
curl -I -x http://cache1.sss:3128 https://registry.npmjs.org

# EXPECTED: HTTP/1.1 200 OK (või 301 Moved Permanently)
# Kui timeout: Proxy ei ole kättesaadav või vale aadress
```

**Lahendus 3: Docker daemon proxy (infrastruktuur)**

Kui Dockerfaile ei saa muuta:

```bash
# /etc/docker/daemon.json (vajab sudo õigust)
{
  "proxies": {
    "http-proxy": "http://cache1.sss:3128",
    "https-proxy": "http://cache1.sss:3128",
    "no-proxy": "localhost,127.0.0.1,10.0.0.0/8"
  }
}

# Taaskäivita Docker
sudo systemctl restart docker
```

---

### Viga 2: Proxy leak'is runtime'i

**Sümptom:**
```bash
docker run --rm user-service:1.0 env | grep -i proxy
HTTP_PROXY=http://cache1.sss:3128
HTTPS_PROXY=http://cache1.sss:3128
```

**Põhjus:**
Kasutasid Dockerfile.proxy või Dockerfile.proxy-hardcoded varianti, kus proxy muutujad on ka runtime stage'is.

**Miks see on probleem?**
- Runtime konteiner proovib kasutada proksi (kui rakendus teeb väliseid HTTP päringuid)
- Kui konteiner töötab keskkonnas, kus cache1.sss ei ole kättesaadav → rakendus crashib
- Turvaviga: proxy info on nähtav runtime'is

**Lahendus:**
Kasuta Dockerfile.optimized.proxy, kus proxy on AINULT builder stage'is.

```bash
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f Dockerfile.optimized.proxy \
  -t user-service:1.0 \
  ../../../apps/backend-nodejs

# Verifitseeri runtime (peaks olema clean)
docker run --rm user-service:1.0 env | grep -i proxy
# EXPECTED: Tühi väljund ✅
```

---

### Viga 3: CORS error runtime'is (seotud proksiga)

**Sümptom:**
```
Access to fetch at 'http://localhost:3000/api/users' from origin 'http://localhost:8080' has been blocked by CORS policy
```

**Põhjus:**
See EI OLE proxy probleem! CORS on rakenduse loogika probleem.

**Lahendus:**
Kontrolli User Service `server.js` faili - CORS middleware peab olema seadistatud:

```javascript
const cors = require('cors');
app.use(cors({
  origin: ['http://localhost:8080', 'http://127.0.0.1:8080'],
  credentials: true
}));
```

---

## Võrdlustabel

| Aspekt | Dockerfile.optimized.proxy | Dockerfile.proxy | Dockerfile.proxy-hardcoded |
|--------|---------------------------|------------------|---------------------------|
| **Portaabel** | ✅ Töötab proksi ja ilma | ✅ Töötab proksi ja ilma | ❌ Ainult cache1.sss võrgus |
| **Runtime proxy** | ✅ Clean (ei leki) | ⚠️ Leak'ib | ❌ Leak'ib (hardcoded) |
| **Production-ready** | ✅ Jah | ⚠️ Ei soovitata | ❌ EI |
| **Image suurus** | ~305MB | ~305MB | ~305MB |
| **Multi-stage** | ✅ Jah (dependencies + runtime) | ❌ Ei (single-stage) | ❌ Ei |
| **Non-root user** | ✅ Jah (nodejs:1001) | ✅ Jah | ❌ Root |
| **Health check** | ✅ Jah | ✅ Jah | ❌ Ei |
| **Kihtide vahemälu** | ✅ Optimeeritud | ⚠️ Suboptim aalne | ❌ Puudub |
| **Arendaja masinas** | ✅ Töötab | ✅ Töötab | ❌ Ei tööta |
| **CI/CD integratsioon** | ✅ Lihtne (build args) | ✅ Lihtne | ❌ Vajab hardcoded proxy |

**Järeldus:**
Tootmiseks kasuta **Dockerfile.optimized.proxy** (ARG-põhine, multi-stage).

---

## Docker Compose Integratsioon (Lab 2)

Kui kasutad Docker Compose'i (Lab 2), siis:

```yaml
# docker-compose.yml
services:
  user-service:
    build:
      context: ./apps/backend-nodejs
      dockerfile: ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized.proxy
      args:
        HTTP_PROXY: http://cache1.sss:3128
        HTTPS_PROXY: http://cache1.sss:3128
        NO_PROXY: localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16
    image: user-service:1.0-optimized
    # ...
```

**Ilma proksita:**

```yaml
services:
  user-service:
    build:
      context: ./apps/backend-nodejs
      dockerfile: ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized.proxy
      # args: # <- Jäta ära, Dockerfile default'id on tühjad stringid
    image: user-service:1.0-optimized
```

---

## Viited ja Edasine Lugemine

### Teooria Peatükid

- 📖 [Peatükk 06: Dockerfile Rakenduste Konteineriseerimise Detailid](../../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md)
  - Multi-stage builds
  - Dockerfile instruktsioonid (ARG, ENV, FROM)
  - Layer caching

- 📖 [Peatükk 06A: Java Spring Boot ja Node.js Konteineriseerimise Spetsiifika](../../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)
  - Node.js npm ci vs npm install
  - bcrypt natiivmoodulid (miks node:22-slim, mitte Alpine)
  - Package manager proxy handling

### Labori Harjutused

- 📝 [Lab 1, Harjutus 01a: Single Container (Node.js)](../../../exercises/01a-single-container-nodejs.md)
- 📝 [Lab 1, Harjutus 05: Optimization](../../../exercises/05-optimization.md)

### Välised Ressursid

- [npm config proxy documentation](https://docs.npmjs.com/cli/v9/using-npm/config#proxy)
- [Docker ARG vs ENV](https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact)
- [Docker multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Docker daemon proxy configuration](https://docs.docker.com/config/daemon/systemd/#httphttps-proxy)

---

## Kokkuvõte

**Kasuta tootmises:**
- ✅ Dockerfile.optimized.proxy (ARG-põhine, multi-stage)
- ✅ Build args: `--build-arg HTTP_PROXY=http://cache1.sss:3128`
- ✅ Verifitseeri runtime: `docker run --rm <image> env | grep -i proxy` (peaks olema tühi)

**Ära kasuta tootmises:**
- ❌ Dockerfile.proxy-hardcoded (anti-pattern)
- ❌ Hardcoded ENV (proxy leak, ei ole portaabel)

**Õppimiseks:**
- ✅ Dockerfile.proxy (lihtne variant, single-stage)
- ✅ Võrdle kõiki kolme varianti (build time, runtime, image size)

---

**Viimane uuendus:** 2025-01-25
**Seos laboritega:** Lab 1 (Harjutused 01a, 05), Lab 2 (Docker Compose)
**Eelmine:** ../backend-java-spring/README-PROXY.md
**Järgmine:** [Lab 1 Harjutus 01a](../../../exercises/01a-single-container-nodejs.md)
