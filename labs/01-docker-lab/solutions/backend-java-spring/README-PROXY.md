# Proxy-Aware Docker Builds - Todo Service (Java Spring Boot + Gradle)

## Ülevaade

Corporate keskkonnas on otseühendus internetti sageli blokeeritud turvalisuse pärast. Kõik HTTP/HTTPS päringud peavad minema läbi **proksi serveri** (nt. `cache1.sss:3128`). See mõjutab Docker build'e, kuna Gradle peab pääsema Maven Central'i ja teistele repository'desse paketite allalaadimiseks.

**Erinevus npm'ist:**
- npm kasutab `HTTP_PROXY` keskkonna muutujat otse ✅
- Gradle **EI** kasuta `HTTP_PROXY` otse ❌
- Gradle vajab: `-Dhttp.proxyHost=cache1.sss -Dhttp.proxyPort=3128`

**Probleem:**
```bash
docker build -t todo-service:1.0 .

# Viga:
> Could not resolve all dependencies for configuration ':compileClasspath'.
   > Could not resolve org.springframework.boot:spring-boot-starter-web:3.2.0.
      > Could not get resource 'https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-web/3.2.0/spring-boot-starter-web-3.2.0.pom'.
         > Could not GET 'https://repo.maven.apache.org/maven2/...'.
            > Connect to repo.maven.apache.org:443 [repo.maven.apache.org/151.101.0.209] failed: Connection timed out
```

**Lahendus:**
See kaust sisaldab **kolme erinevat lähenemist** Gradle proxy konfigureerimiseks Docker build'ides.

---

## Dockerfile Variandid

### 1. Dockerfile.optimized.proxy (✅ RECOMMENDED)

**Tüüp:** ARG-põhine + GRADLE_OPTS parsing, multi-stage
**Image suurus:** ~250MB (JRE + JAR)
**Portaabel:** ✅ Jah (töötab proksi ja ilma)
**Production-ready:** ✅ Jah

**Eelised:**
- ✅ Töötab MÕLEMAS keskkonnas (proksi ja ilma)
- ✅ Proxy AINULT build-time ajal (ei leki runtime'i)
- ✅ Turvaline (runtime ainult JRE + JAR, proxy clean)
- ✅ Multi-stage: Gradle builder (600MB) → JRE runtime (250MB)
- ✅ HTTP_PROXY parsing → GRADLE_OPTS (automaatne)
- ✅ Non-root user (spring:1001)
- ✅ Health check
- ✅ JVM memory tuning (80% container RAM)

**Build käsud:**

```bash
cd /home/janek/projects/hostinger/labs/01-docker-lab/solutions/backend-java-spring

# PROKSIGA (corporate võrk):
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  --build-arg NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16 \
  -f Dockerfile.optimized.proxy \
  -t todo-service:1.0-optimized \
  ../../../apps/backend-java-spring

# ILMA PROKSITA (arendaja masinas):
docker build \
  -f Dockerfile.optimized.proxy \
  -t todo-service:1.0-optimized \
  ../../../apps/backend-java-spring
```

**Test runtime (veendu, et proxy ei leki):**

```bash
docker run --rm todo-service:1.0-optimized env | grep -i proxy

# EXPECTED: Tühi väljund (ei leia midagi) ✅
# Kui näed HTTP_PROXY=... või GRADLE_OPTS=..., siis proxy leak'is! ⚠️
```

---

### 2. Dockerfile.proxy (Lihtne Variant)

**Tüüp:** ARG-põhine + GRADLE_OPTS, single-stage
**Image suurus:** ~600MB (JDK + Gradle + JAR)
**Portaabel:** ✅ Jah
**Production-ready:** ⚠️ Ei (JDK runtime'is, suur image)

**Eelised:**
- ✅ Lihtne mõista (kõik ühes stage'is)
- ✅ Töötab proksi ja ilma
- ✅ GRADLE_OPTS parsing (sama nagu optimized)
- ✅ Hea õppimiseks

**Puudused:**
- ❌ Suur image (~600MB vs ~250MB optimized)
- ❌ JDK jääb runtime'i (ei ole vajalik, turvaviga)
- ❌ Gradle daemon ja cache jäävad image'i
- ❌ Proxy muutujad jäävad runtime'i

**Build käsk:**

```bash
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f Dockerfile.proxy \
  -t todo-service:1.0-simple \
  ../../../apps/backend-java-spring
```

**Kasutus:** Õppimiseks ja testimiseks, mitte tootmiseks.

---

### 3. Dockerfile.proxy-hardcoded (❌ ANTI-PATTERN)

**Tüüp:** Hardcoded GRADLE_OPTS
**Image suurus:** ~600MB
**Portaabel:** ❌ EI (ainult cache1.sss võrgus)
**Production-ready:** ❌ EI

**Probleemid:**
- ❌ Töötab AINULT cache1.sss võrgus
- ❌ Arendaja masinas ebaõnnestub
- ❌ GRADLE_OPTS leak'ib runtime'i (confusion)
- ❌ Ei ole taaskasutatav teistes keskkondades
- ❌ Tekitab technical debt

**Miks see eksisteerib corporate keskkonnas?**
- Quick fix surve all
- Gradle proxy konfiguratsioon on keeruline (systemProp vs GRADLE_OPTS)
- Copy-paste StackOverflow'st
- "It works, don't touch it" kultuur

**Build käsk (DEMONSTRATSIOONIKS):**

```bash
docker build \
  -f Dockerfile.proxy-hardcoded \
  -t todo-service:1.0-hardcoded \
  ../../../apps/backend-java-spring
```

**⚠️ Ära kasuta tootmises!** See on AINULT demonstratsiooniks.

---

## Gradle Proxy Konfiguratsioon - Detailne Selgitus

### Probleem: Gradle vs. npm Proxy

| Package Manager | HTTP_PROXY Support | Proxy Format |
|----------------|---------------------|--------------|
| **npm** | ✅ Respects HTTP_PROXY env var | `http://cache1.sss:3128` |
| **Gradle** | ❌ Does NOT use HTTP_PROXY | `-Dhttp.proxyHost=cache1.sss -Dhttp.proxyPort=3128` |

### Gradle Proxy Meetodid

**Meetod 1: GRADLE_OPTS keskkonna muutuja** (Dockerfiles kasutavad seda)

```bash
export GRADLE_OPTS="-Dhttp.proxyHost=cache1.sss -Dhttp.proxyPort=3128 -Dhttps.proxyHost=cache1.sss -Dhttps.proxyPort=3128"
gradle dependencies
```

**Meetod 2: gradle.properties fail**

```properties
# $GRADLE_USER_HOME/gradle.properties
systemProp.http.proxyHost=cache1.sss
systemProp.http.proxyPort=3128
systemProp.https.proxyHost=cache1.sss
systemProp.https.proxyPort=3128
systemProp.http.nonProxyHosts=localhost|127.0.0.1
```

**Meetod 3: Kommandrea argumentid**

```bash
gradle dependencies \
  -Dhttp.proxyHost=cache1.sss \
  -Dhttp.proxyPort=3128 \
  -Dhttps.proxyHost=cache1.sss \
  -Dhttps.proxyPort=3128
```

### Meie Lahendus: HTTP_PROXY Parsing

Dockerfile.optimized.proxy parsib HTTP_PROXY stringi:

```bash
# Input: HTTP_PROXY=http://cache1.sss:3128
PROXY_HOST=$(echo $HTTP_PROXY | sed -e 's|http://||' -e 's|https://||' -e 's|:[0-9]*$||')
PROXY_PORT=$(echo $HTTP_PROXY | grep -oE '[0-9]+$')

# Output:
# PROXY_HOST=cache1.sss
# PROXY_PORT=3128

# Seadista GRADLE_OPTS
export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT"
```

**Eelised:**
- ✅ Töötab nagu npm (standard HTTP_PROXY formaat)
- ✅ Dockerfile sarnane Node.js variandiga
- ✅ Dünaamiline (parsing build-time ajal)

---

## Build Käsud ja Näited

### Näide 1: Ehita Lab 1 Harjutuseks 1b (proksiga)

```bash
cd /home/janek/projects/hostinger/labs/01-docker-lab/solutions/backend-java-spring

# Ehita optimeeritud variant proksiga
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  --build-arg NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16 \
  -f Dockerfile.optimized.proxy \
  -t todo-service:1.0 \
  ../../../apps/backend-java-spring

# Kontrolli image suurust
docker images | grep todo-service

# Testi runtime (ei tohi olla proxy vars)
docker run --rm todo-service:1.0 env | grep -i proxy
# EXPECTED: Tühi väljund ✅
```

### Näide 2: Ehita ilma proksita (arendaja masinas)

```bash
# Sama Dockerfile, ILMA build-arg'ideta
docker build \
  -f Dockerfile.optimized.proxy \
  -t todo-service:1.0 \
  ../../../apps/backend-java-spring

# Töötab ilma proksita! ✅
```

### Näide 3: Võrdle Image Suurusi (optimized vs simple)

```bash
# Ehita optimeeritud (multi-stage)
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f Dockerfile.optimized.proxy \
  -t todo-service:optimized \
  ../../../apps/backend-java-spring

# Ehita simple (single-stage)
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f Dockerfile.proxy \
  -t todo-service:simple \
  ../../../apps/backend-java-spring

# Võrdle suurusi
docker images | grep todo-service

# EXPECTED:
# todo-service:optimized   ~250MB  ← JRE + JAR
# todo-service:simple      ~600MB  ← JDK + Gradle + JAR
# ERINEVUS:                ~350MB säästetud! 💾
```

---

## Troubleshooting

### Viga 1: Could not resolve all dependencies for configuration ':compileClasspath'

**Sümptom:**
```
> Could not resolve org.springframework.boot:spring-boot-starter-web:3.2.0.
   > Could not get resource 'https://repo.maven.apache.org/maven2/...'.
      > Could not GET 'https://repo.maven.apache.org/maven2/...'.
         > Connect to repo.maven.apache.org:443 [repo.maven.apache.org/151.101.0.209] failed: Connection timed out
```

**Põhjus:**
Corporate firewall blokeerib otseühenduse Maven Central'i. Sõltuvused peavad minema läbi proksi (cache1.sss:3128).

**Lahendus 1: Kasuta Dockerfile.optimized.proxy build arg'idega**

```bash
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f Dockerfile.optimized.proxy \
  -t todo-service:1.0 \
  ../../../apps/backend-java-spring
```

**Lahendus 2: Debug Gradle proxy konfiguratsiooni**

```bash
# Testi Gradle'i proksiga
docker run --rm gradle:8.11-jdk21-alpine sh -c '
  export GRADLE_OPTS="-Dhttp.proxyHost=cache1.sss -Dhttp.proxyPort=3128"
  gradle --version
'

# Kui õnnestub: Proxy töötab ✅
# Kui timeout: Kontrolli proxy aadressi ja porti
```

**Lahendus 3: Kontrolli, kas proxy on kättesaadav**

```bash
# Test proxy ühendust
curl -I -x http://cache1.sss:3128 https://repo.maven.apache.org

# EXPECTED: HTTP/1.1 200 OK (või 301 Moved Permanently)
# Kui timeout: Proxy ei ole kättesaadav või vale aadress
```

---

### Viga 2: GRADLE_OPTS leak'is runtime'i

**Sümptom:**
```bash
docker run --rm todo-service:1.0 env | grep -i gradle
GRADLE_OPTS=-Dhttp.proxyHost=cache1.sss -Dhttp.proxyPort=3128 ...
```

**Põhjus:**
Kasutasid Dockerfile.proxy või Dockerfile.proxy-hardcoded varianti, kus GRADLE_OPTS on ka runtime stage'is.

**Miks see on probleem?**
- GRADLE_OPTS ei ole vaja runtime'is (Java rakendus ei vaja Gradle'i)
- Confusion: miks Gradle konfiguratsioon on runtime'is?
- Proxy info on nähtav (turvaviga)

**Lahendus:**
Kasuta Dockerfile.optimized.proxy, kus GRADLE_OPTS on AINULT builder stage'is.

```bash
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f Dockerfile.optimized.proxy \
  -t todo-service:1.0 \
  ../../../apps/backend-java-spring

# Verifitseeri runtime (peaks olema clean)
docker run --rm todo-service:1.0 env | grep -i gradle
# EXPECTED: Tühi väljund ✅

docker run --rm todo-service:1.0 env | grep -i proxy
# EXPECTED: Tühi väljund ✅
```

---

### Viga 3: Proxy parsing ebaõnnestus

**Sümptom:**
```
PROXY_HOST=
PROXY_PORT=
GRADLE_OPTS=-Dhttp.proxyHost= -Dhttp.proxyPort=
```

**Põhjus:**
HTTP_PROXY formaat ei ole `http://host:port`.

**Lahendus:**
Kontrolli HTTP_PROXY formaati:

```bash
# ÕIGE:
HTTP_PROXY=http://cache1.sss:3128  ✅
HTTP_PROXY=https://cache1.sss:3128 ✅

# VALE:
HTTP_PROXY=cache1.sss:3128  ❌ (puudub protocol)
HTTP_PROXY=cache1.sss       ❌ (puudub port)
HTTP_PROXY=http://cache1.sss:3128/  ❌ (trailing slash)
```

**Debug parsing:**

```bash
# Testi parsing'ut
HTTP_PROXY=http://cache1.sss:3128
PROXY_HOST=$(echo "$HTTP_PROXY" | sed -e 's|http://||' -e 's|https://||' -e 's|:[0-9]*$||')
PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$')

echo "Host: $PROXY_HOST"  # Should output: cache1.sss
echo "Port: $PROXY_PORT"  # Should output: 3128
```

---

## Võrdlustabel

| Aspekt | Dockerfile.optimized.proxy | Dockerfile.proxy | Dockerfile.proxy-hardcoded |
|--------|---------------------------|------------------|---------------------------|
| **Portaabel** | ✅ Töötab proksi ja ilma | ✅ Töötab proksi ja ilma | ❌ Ainult cache1.sss võrgus |
| **Runtime proxy** | ✅ Clean (ei leki) | ⚠️ Leak'ib | ❌ Leak'ib (hardcoded) |
| **Production-ready** | ✅ Jah | ⚠️ Ei soovitata | ❌ EI |
| **Image suurus** | ~250MB (JRE) | ~600MB (JDK) | ~600MB (JDK) |
| **Multi-stage** | ✅ Jah (Gradle builder + JRE runtime) | ❌ Ei (single-stage) | ❌ Ei |
| **GRADLE_OPTS parsing** | ✅ Automaatne (HTTP_PROXY → GRADLE_OPTS) | ✅ Automaatne | ❌ Hardcoded |
| **Non-root user** | ✅ Jah (spring:1001) | ✅ Jah | ❌ Root |
| **Health check** | ✅ Jah (wget /health) | ✅ Jah | ❌ Ei |
| **JVM tuning** | ✅ Jah (80% RAM) | ✅ Jah | ❌ Ei |
| **Arendaja masinas** | ✅ Töötab | ✅ Töötab | ❌ Ei tööta |
| **CI/CD integratsioon** | ✅ Lihtne (build args) | ✅ Lihtne | ❌ Vajab hardcoded proxy |

**Järeldus:**
Tootmiseks kasuta **Dockerfile.optimized.proxy** (ARG-põhine + parsing, multi-stage).

---

## Docker Compose Integratsioon (Lab 2)

Kui kasutad Docker Compose'i (Lab 2), siis:

```yaml
# docker-compose.yml
services:
  todo-service:
    build:
      context: ./apps/backend-java-spring
      dockerfile: ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized.proxy
      args:
        HTTP_PROXY: http://cache1.sss:3128
        HTTPS_PROXY: http://cache1.sss:3128
        NO_PROXY: localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16
    image: todo-service:1.0-optimized
    # ...
```

**Ilma proksita:**

```yaml
services:
  todo-service:
    build:
      context: ./apps/backend-java-spring
      dockerfile: ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized.proxy
      # args: # <- Jäta ära
    image: todo-service:1.0-optimized
```

---

## Viited ja Edasine Lugemine

### Teooria Peatükid

- 📖 [Peatükk 06: Dockerfile Rakenduste Konteineriseerimise Detailid](../../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md)
  - Multi-stage builds
  - Dockerfile instruktsioonid (ARG, ENV, FROM)
  - Layer caching

- 📖 [Peatükk 06A: Java Spring Boot ja Node.js Konteineriseerimise Spetsiifika](../../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)
  - Java Spring Boot JAR vs WAR
  - Gradle dependency caching
  - JVM tuning (InitialRAMPercentage, MaxRAMPercentage)

### Labori Harjutused

- 📝 [Lab 1, Harjutus 01b: Single Container (Java)](../../../exercises/01b-single-container-java.md)
- 📝 [Lab 1, Harjutus 05: Optimization](../../../exercises/05-optimization.md)

### Välised Ressursid

- [Gradle proxy configuration](https://docs.gradle.org/current/userguide/build_environment.html#sec:accessing_the_web_via_a_proxy)
- [Docker ARG vs ENV](https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact)
- [Docker multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Spring Boot Docker best practices](https://spring.io/guides/topicals/spring-boot-docker)

---

## Kokkuvõte

**Kasuta tootmises:**
- ✅ Dockerfile.optimized.proxy (ARG-põhine + GRADLE_OPTS parsing, multi-stage)
- ✅ Build args: `--build-arg HTTP_PROXY=http://cache1.sss:3128`
- ✅ Verifitseeri runtime: `docker run --rm <image> env | grep -i proxy` (peaks olema tühi)
- ✅ Image suurus: ~250MB (JRE + JAR) vs ~600MB (JDK + Gradle)

**Ära kasuta tootmises:**
- ❌ Dockerfile.proxy-hardcoded (anti-pattern)
- ❌ Hardcoded GRADLE_OPTS (proxy leak, ei ole portaabel)
- ❌ Single-stage JDK runtime (suur image, turvaviga)

**Õppimiseks:**
- ✅ Dockerfile.proxy (lihtne variant, single-stage)
- ✅ Võrdle HTTP_PROXY parsing'ut (automaatne vs hardcoded)
- ✅ Võrdle image suurusi (optimized 250MB vs simple 600MB)

---

**Viimane uuendus:** 2025-01-25
**Seos laboritega:** Lab 1 (Harjutused 01b, 05), Lab 2 (Docker Compose)
**Eelmine:** ../backend-nodejs/README-PROXY.md
**Järgmine:** [Lab 1 Harjutus 01b](../../../exercises/01b-single-container-java.md)
