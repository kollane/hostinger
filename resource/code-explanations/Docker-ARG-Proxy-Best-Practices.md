# Docker ARG-põhine Proxy Konfiguratsioon - Best Practices

See dokument selgitab, kuidas ARG-põhine proxy konfiguratsioon töötab ja miks see on parim praktika corporate keskkonnas (nt Intel võrk).

---

## Sissejuhatus: Miks ettevõtetes on vaja proxy serverit?

### Mis on proxy server?

**Proxy server (vahendaja server)** on vahendaja sinu arvuti ja Interneti vahel. Kõik väljuvad päringud (nt Docker image'ite allalaadimine, npm/Gradle sõltuvused) lähevad läbi proxy serveri.

```
┌──────────────┐                ┌──────────────┐                ┌──────────────┐
│   Sinu       │  HTTP päringu  │    Proxy     │  HTTP päringu  │   Internet   │
│   Arvuti     │───────────────>│    Server    │───────────────>│  (registry,  │
│  (Docker)    │                │ (Intel võrk) │                │   npm, etc)  │
└──────────────┘                └──────────────┘                └──────────────┘
```

### Miks ettevõtted (nt Intel) kasutavad proxy serverit?

1. **🔒 Turvalisus:** Proxy server filtreerib ja monitoorib kogu liiklust (blokeerib pahatahtlikud saidid, viiruseid)
2. **📊 Kontroll:** IT osakond näeb, millised ressursid on kasutuses (auditeerimine, compliance)
3. **⚡ Kiirus:** Proxy vahemälu (cache) hoiab sageli kasutatud ressursse (nt Docker base image'id)
4. **🌐 Võrgupoliitika:** Ettevõte kontrollib, milliseid väliseid ressursse töötajad saavad kasutada

### Mis juhtub ilma proxy seadistusteta?

**Intel võrgus (või sarnases corporate keskkonnas):**

```bash
# Proovid alla laadida Docker image'i
docker pull node:22-slim

# VIGA: "dial tcp: lookup registry-1.docker.io: no such host"
# ❌ Ei saa Internetti otse - proxy on vajalik!
```

**npm sõltuvuste installimine:**

```bash
# Proovid npm pakette alla laadida
npm install express

# VIGA: "ETIMEDOUT" või "ECONNREFUSED"
# ❌ npm registry ei ole otse kättesaadav!
```

**Gradle sõltuvuste allalaadimine:**

```bash
# Proovid Gradle dependencies alla laadida
./gradlew build

# VIGA: "Connection timed out"
# ❌ Maven Central, Gradle Plugin Portal ei ole kättesaadav!
```

### Kuidas proxy töötab?

**Intel proxy näide:**

```bash
# Intel võrk kasutab järgmisi proxy servereid:
HTTP_PROXY=http://proxy-chain.intel.com:911   # HTTP liiklus
HTTPS_PROXY=http://proxy-chain.intel.com:912  # HTTPS liiklus
NO_PROXY=localhost,127.0.0.1,10.0.0.0/8       # Ei kasuta proxy'd (local/internal)
```

**Mis juhtub, kui seadistame proxy õigesti:**

```bash
# 1. Docker build kasutab proxy'd
docker build --build-arg HTTP_PROXY=http://proxy-chain.intel.com:911 -t myapp .

# 2. npm/Gradle saavad Internetti proxy kaudu ✅
# 3. Docker base image'id tõmmatakse registry-st ✅
# 4. Kõik välised sõltuvused laetakse alla ✅
```

### Miks ARG-põhine lähenemine on parim?

**Probleem:** Proxy on vajalik AINULT build-time (ehitamise ajal), MITTE runtime (käitamise ajal)!

- ✅ **Build-time:** npm/Gradle peavad alla laadima sõltuvused → vajab proxy'd
- ❌ **Runtime:** Rakendus jookseb ja vastab HTTP päringutele → EI VAJA proxy'd

**Lahendus:** ARG-põhine konfiguratsioon
- ARG määratakse ainult `docker build` ajal (`--build-arg HTTP_PROXY=...`)
- ENV seadistatakse ainult builder stage'is (dependencies allalaadimine)
- Runtime stage on "clean" - proxy muutujaid EI OLE (portaabel, turvaline)

**Tulemus:**
- ✅ Sama Dockerfile töötab Intel võrgus (koos proxy'ga)
- ✅ Sama Dockerfile töötab AWS/GCP/Azure (ilma proxy'ta)
- ✅ Image on portaabel (ei sõltu proxy seadistustest)

---

## 1. Kuidas ARG-põhine Proxy Töötab

**Põhimõte:** Dockerfile kasutab ARG'e build-time proxy seadistusteks ja ENV'e ainult builder stage'is. Runtime stage on "clean" - proxy ei leki!

### Node.js (User Service) proxy struktuur

```dockerfile
# ARG ENNE esimest FROM - nähtav kõigis stage'ides
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""

# Stage 1: Dependencies
FROM node:22-slim AS dependencies

# ENV AINULT selles stage'is - npm kasutab neid
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY}

RUN npm ci --only=production  # npm kasutab HTTP_PROXY automaatselt

# Stage 2: Runtime
FROM node:22-slim  # <-- Uus FROM nullib ENV muutujad!
# Proxy ei ole siin - runtime on "clean"!
```

**Mida õppisid:**
- ✅ ARG on build-time (määratakse `--build-arg` kaudu)
- ✅ ENV on AINULT dependencies stage'is
- ✅ Runtime stage EI OLE proxy keskkonda (turvalisem!)
- ✅ Sama Dockerfile töötab Intel võrgus JA väljaspool

---

## 2. Verifitseeri: Proxy Ei Leki Runtime'i

**KRIITILINE TEST:** Kontrolli, et proxy muutujad EI OLE runtime konteineris!

```bash
# Test: runtime konteineris EI TOHI olla proksi muutujaid
docker run --rm user-service:1.0-optimized env | grep -i proxy

# OODATUD: Tühi väljund (ei leia midagi) ✅
# Kui näed HTTP_PROXY=..., siis proxy leak'is! ⚠️ VIGA!

# Test Gradle muutujate jaoks (Java)
docker run --rm todo-service:1.0-optimized env | grep -i gradle

# OODATUD: Tühi väljund (GRADLE_OPTS ei ole runtime'is) ✅
```

**Miks see on oluline?**
- ✅ Runtime konteiner on "clean" (ei sõltu proksist)
- ✅ Image on portaabel (töötab AWS, GCP, Azure, kodus)
- ✅ Turvalisem (proxy info ei leki tootmisse)

---

## 3. Gradle vs npm Proxy Erinevus

**TÄHTIS ERINEVUS:** Gradle ja npm käituvad erinevalt!

### npm (Node.js)

```bash
# npm kasutab HTTP_PROXY keskkonna muutujat OTSE
ENV HTTP_PROXY=http://proxy-chain.intel.com:911
RUN npm ci --only=production  # ✅ Töötab automaatselt!
```

### Gradle (Java)

```bash
# Gradle EI KASUTA HTTP_PROXY otse! ❌
# Vajab: -Dhttp.proxyHost=HOST -Dhttp.proxyPort=PORT

# Seega parsime HTTP_PROXY stringi:
RUN if [ -n "$HTTP_PROXY" ]; then \
        PROXY_HOST=$(echo "$HTTP_PROXY" | sed -e 's|http://||' -e 's|:[0-9]*$||'); \
        PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
        export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT"; \
        gradle dependencies --no-daemon; \
    fi
```

**Miks see on oluline?**
- ✅ npm: lihtne (kasutab HTTP_PROXY otse)
- ⚠️ Gradle: keeruline (vajab parsing'ut ja GRADLE_OPTS)
- 📖 Täielik selgitus: Vaata `Dockerfile.optimized.proxy` kommentaare

---

## 4. Parimad Praktikad (Best Practices)

### ✅ DO (KASUTA):

1. **ARG-põhine proxy** - portaabel, turvaline
   ```dockerfile
   ARG HTTP_PROXY=""
   ARG HTTPS_PROXY=""
   ```

2. **ENV ainult builder stage'is** - runtime on "clean"
   ```dockerfile
   FROM node:22-slim AS builder
   ENV HTTP_PROXY=${HTTP_PROXY}
   # ...
   FROM node:22-slim AS runtime
   # Proxy ei ole siin!
   ```

3. **Vaikeväärtused tühjad** - töötab ilma proksita
   ```dockerfile
   ARG HTTP_PROXY=""  # Tühi string, mitte undefined
   ```

4. **Test runtime leakage** - veendu, et proxy ei leki
   ```bash
   docker run --rm myapp env | grep -i proxy
   # Oodatud: tühi väljund
   ```

### ❌ DON'T (ÄRA KASUTA):

1. **Hardcoded ENV** - ei ole portaabel
   ```dockerfile
   # ❌ VALE - töötab ainult Intel võrgus
   ENV HTTP_PROXY=http://proxy-chain.intel.com:911
   ```

2. **ENV runtime stage'is** - proxy leak'ib tootmisse
   ```dockerfile
   # ❌ VALE - runtime on "määrdunud"
   FROM node:22-slim AS runtime
   ENV HTTP_PROXY=${HTTP_PROXY}  # Ei tee seda!
   ```

3. **Proxy ilma vaikeväärtuseta** - ei tööta ilma `--build-arg`
   ```dockerfile
   # ❌ VALE - nurjub ilma --build-arg
   ARG HTTP_PROXY  # Puudub vaikeväärtus
   ```

---

## 5. Praktiline Kasutamine

### Intel Võrgus (proxy vajalik)

```bash
docker build \
  --build-arg HTTP_PROXY=http://proxy-chain.intel.com:911 \
  --build-arg HTTPS_PROXY=http://proxy-chain.intel.com:912 \
  -t myapp:latest .
```

### AWS/GCP/Azure (proxy ei ole vaja)

```bash
docker build -t myapp:latest .
# Töötab! ARG vaikeväärtused on tühjad stringid
```

### Sama Image Mõlemas Keskkonnas

```bash
# Intel võrk
docker build --build-arg HTTP_PROXY=... -t myapp:1.0 .
docker push myregistry/myapp:1.0

# AWS
docker pull myregistry/myapp:1.0  # Sama image!
docker run myapp:1.0  # Töötab ilma proksita
```

---

## 6. Kokkuvõte

ARG-põhine proxy konfiguratsioon:
- ✅ Töötab Intel võrgus JA väljaspool (portaabel)
- ✅ Ei leki runtime'i (turvalisem)
- ✅ Ei suurenda image suurust
- ✅ Production-ready (sama Dockerfile mõlemas keskkonnas)

**Võrdlus alternatiividega:**

| Lähenemine | Portaabelsus | Turvalisus | Production-ready |
|------------|--------------|------------|------------------|
| **ARG-põhine** (see dokument) | ✅ Töötab kõikjal | ✅ Ei leki runtime'i | ✅ Jah |
| **Hardcoded ENV** | ❌ Ainult Intel võrk | ❌ Leak'ib runtime'i | ❌ Ei |
| **Runtime ENV** | ⚠️ Vajab `-e` flag'e | ❌ Leak'ib runtime'i | ⚠️ Keeruline |

---

## 7. Viited

**Põhjalik dokumentatsioon:**
- Node.js: [Dockerfile.optimized.proxy](../../labs/01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized.proxy)
- Java/Gradle: [Dockerfile.optimized.proxy](../../labs/01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized.proxy)
- Teooria: [Peatükk 06A: Java/Node.js Konteineriseerimise Spetsiifika](../06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)

**Laborid:**
- Lab 1, Harjutus 01a: Node.js Dockerfile koos proxy tugi
- Lab 1, Harjutus 01b: Java Dockerfile koos Gradle proxy parsing
- Lab 1, Harjutus 05: Optimeeritud Dockerfile'id (Samm 7)

---

**Tüüp:** Koodiselgitus (KOODISELGITUS)
**Kasutatakse:** Lab 1 (Harjutused 01a, 01b, 05)
**Viimane uuendus:** 2025-12-07
**Allikas:** Ekstrakteeritud Lab 1 Exercise 05 Samm 7, laiendatud Sissejuhatusega
