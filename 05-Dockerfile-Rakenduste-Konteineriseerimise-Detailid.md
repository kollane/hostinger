# Peatükk 5: Dockerfile ja Rakenduste Konteineriseerimise Detailid

**Kestus:** 10-12 tundi (põhjalik)
**Tase:** Keskmine
**Eeldused:** Peatükk 4 läbitud, Docker põhimõtted selged

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist oskad:

1. ✅ Selgitada Dockerfile instruktsioonide rolli ja eesmärki
2. ✅ Mõista layer caching'u arhitektuurilisi eeliseid
3. ✅ Selgitada multi-stage build'i optimiseerimise põhimõtteid
4. ✅ Mõista Node.js rakenduste konteineriseerimise strateegiaid
5. ✅ Mõista Java/Spring Boot deployment mudelite erinevusi
6. ✅ Selgitada database migrations'i rolli DevOps workflow's
7. ✅ Rakendada image size optimization tehnikaid
8. ✅ Mõista security best practices (non-root users, minimal base images)
9. ✅ Debuggida image build'i probleeme

---

## 🎯 OLULINE: DevOps Administraatori Vaatenurk

**Mida sa ÕPID selles peatükis:**
- ✅ Kuidas image'eid luua ja optimeerida (DevOps vastutus)
- ✅ Kuidas keskkonda seadistada (environment variables, config)
- ✅ Kuidas deployment protsessi automatiseerida (migrations, health checks)
- ✅ Kuidas probleeme diagnosteerida (build errors, runtime issues)

**Mida sa EI ÕPI:**
- ❌ Kuidas rakenduse koodi kirjutada (arendaja vastutus)
- ❌ Kuidas API'sid implementeerida (arendaja vastutus)
- ❌ Kuidas database skeeme disainida (DBA/arendaja vastutus)

**Vastutusalad:**

```
Arendaja:
- Kirjutab koodi (JavaScript, Java)
- Loob API endpoint'id
- Disainib database skeemi

DevOps Administraator:
- Konteineriseerib rakendust (Dockerfile)
- Deploy'b production'i (Kubernetes, Docker Compose)
- Monitoorib ja debuggib (logs, metrics)
- Haldab infrastructure (VPS, cloud)
```

**Analoogia: Automehhaanik vs Autoinsener**

```
Autoinsener disainib mootorit → Arendaja kirjutab koodi
Automehhaanik hooldab autot → DevOps konteineriseerib ja deploy'b
```

---

## 📦 1. Dockerfile: Infrastructure as Code for Images

### 1.1 Mis On Dockerfile ja Miks See On Oluline?

**Dockerfile on blueprint Docker image loomiseks.**

**Miks Dockerfile on Infrastructure as Code (IaC)?**

1. **Reproducibility:**
   - Sama Dockerfile toodab sama image'i (deterministic build)
   - Ei ole "aga minu masinas see töötab" - image on identne

2. **Version Control:**
   - Dockerfile on tekstifail → Git version control
   - Muudatused on traceable (Git history, blame, diff)
   - Code review protsess (pull requests)

3. **Documentation:**
   - Dockerfile on **self-documenting** - näitab täpselt, kuidas image on ehitatud
   - Ei ole "black box" - igaüks saab lugeda, mida tehti

4. **Automation:**
   - CI/CD saab build'ida image'eid automaatselt
   - Ei vaja käsitsi seadistamist

**Dockerfile vs käsitsi image loomine:**

**Käsitsi (deprecated approach):**
```
1. docker run -it ubuntu:22.04 bash
2. apt update && apt install nodejs npm
3. mkdir /app && cd /app
4. Kopeeri failid
5. npm install
6. docker commit <container> myapp:1.0
```

**Probleem:** Ei ole reproducible, ei ole documented, ei saa automatiseerida

**Dockerfile approach (modern):**
- Kirjuta Dockerfile (deklaratiivne, reproducible)
- `docker build` - automaatne, reproducible build
- Version control (Git)

---

### 1.2 Dockerfile Instruktsioonid: Arhitektuurilised Kontseptsioonid

#### FROM - Base Image Selection

**Mis:** Määrab base image, millelt su image tuleneb (inheritance)

**Miks oluline:**
- **Alpine vs Debian trade-off:** Size (5MB vs 120MB) vs Compatibility
- **Runtime requirements:** Node.js app vajab Node runtime, mitte full OS'i
- **Security:** Smaller base = less attack surface (fewer packages = fewer vulnerabilities)

**Valikud:**

**Full OS (Debian/Ubuntu):**
- Pros: Kõik library'id olemas (libc, bash, utilities)
- Cons: Suur size (~120MB base), rohkem vulnerabilities
- Use case: Complex dependencies, legacy apps

**Alpine Linux:**
- Pros: Minimal (~5MB base), security-focused (musl libc, no bash)
- Cons: Compatibility issues (musl libc ≠ glibc)
- Use case: Modern apps, production

**Language runtimes:**
- `node:18-alpine` - Node.js 18 + Alpine (~150MB total)
- `eclipse-temurin:17-jre-alpine` - Java 17 JRE (~180MB total)
- `python:3.11-alpine` - Python 3.11 + Alpine (~50MB total)

**Versioning strategy:**
- ❌ `node:latest` - ÄRGE KASUTAGE (unpredictable, breaks builds)
- ✅ `node:18-alpine` - Specific major version (predictable, safe)
- ✅ `node:18.19.0-alpine` - Exact version (maximum reproducibility)

---

#### WORKDIR - Filesystem Organization

**Mis:** Määrab working directory containeris

**Miks oluline:**
- **Organization:** Kõik application files struktureeritud (`/app` on standard)
- **Avoid root pollution:** Ei pane faile `/` kataloogi (mess)
- **Predictability:** CMD/ENTRYPOINT käivitatakse WORKDIR'ist

**Best practice:** `/app` on de facto standard (Kubernetes, Docker Compose docs kasutavad)

---

#### COPY vs ADD: Predictability vs Magic

**COPY: Explicit, predictable**
- Kopeerib faile host'ist → container'i
- No surprises, no magic

**ADD: Implicit behavior (AVOID!)**
- Auto-extracts tar archives (magic!)
- Downloads URLs (network dependency in build!)
- Unpredictable (kas see on tar? URL?)

**Best practice:** ALATI `COPY`, mitte `ADD` (explicit > implicit)

---

#### RUN - Build-Time Execution

**Mis:** Käivitab käsu build ajal (NOT runtime!)

**Miks kombineerida käsud?**

```dockerfile
# ❌ Vale: Iga RUN = uus layer
RUN apt update
RUN apt install -y curl
RUN apt install -y wget
RUN apt clean

# ✅ Õige: Üks RUN = üks layer
RUN apt update && \
    apt install -y curl wget && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
```

**Põhjused:**
1. **Fewer layers:** Docker image koosneb layer'itest - vähem layers = väiksem image
2. **Cache consistency:** Kõik käsud executetakse koos - atomic operation
3. **Cleanup in same layer:** `apt clean` peab olema samas layer'is, kus `apt install` (muidu cached layer sisaldab jura)

**Layer caching impact:**
- Iga RUN loob uue layer'i
- Layer muutub → kõik järgnevad layer'id rebuild'itakse
- Cache invalidation cascade

---

#### CMD vs ENTRYPOINT: Container Startup Behavior

**Arhitektuuriline erinevus:**

**CMD: Default command (overridable)**
- Saab override'ida `docker run` käsuga
- Use case: Default behavior, aga flexibility

**ENTRYPOINT: Fixed executable**
- EI SAA override'ida (fixed container behavior)
- Use case: Container on specific tool (immutable behavior)

**Kombineerimine (best practice):**

```dockerfile
ENTRYPOINT ["node"]
CMD ["src/index.js"]
```

**Põhjus:**
- ENTRYPOINT = executable (node)
- CMD = default argumendid (src/index.js)
- Flexibility: `docker run myapp src/test.js` → runs `node src/test.js`

**Exec form vs Shell form:**

```dockerfile
# Exec form (array) - SOOVITATUD
CMD ["node", "src/index.js"]

# Shell form (string) - AVOID
CMD node src/index.js
```

**Miks exec form?**
- **Signal handling:** Exec form -> node PID 1 (gets SIGTERM)
- **Shell form:** sh PID 1 → node PID 2 (SIGTERM ei jõua node'ini → graceful shutdown fails!)

---

#### ENV - Configuration Management

**Mis:** Määrab environment variables

**Miks Dockerfile'is?**
- **Default values:** Production defaults (NODE_ENV=production)
- **Overridable:** `docker run -e NODE_ENV=development` override'ib

**Hierarchy:**
1. Dockerfile ENV (defaults)
2. docker run -e (runtime override)
3. Kubernetes ConfigMap/Secret (orchestration layer)

---

#### USER - Security Best Practice

**Probleem: Root by default**

Containers run as root by default (UID 0):
- Security risk: Container escape → host compromise
- Privilege escalation vulnerabilities

**Lahendus: Non-root user**

```dockerfile
RUN addgroup --system --gid 1001 appuser && \
    adduser --system --uid 1001 appuser
USER appuser
```

**Miks see on oluline?**
- **Least privilege:** Container ei vaja root õigusi
- **Defense in depth:** Container breakout → attackeril pole root õigusi host'is
- **Kubernetes security:** PodSecurityPolicy/PodSecurity Standards nõuavad non-root

**Implementation details:**
- `--system` - system user (no login shell, no home directory clutter)
- `--gid 1001` - Explicit GID (predictable UID/GID Kubernetes'es)
- `COPY --chown=appuser:appuser` - File ownership

---

#### EXPOSE - Documentation

**Mis:** Dokumenteerib, millist porti container kasutab

**OLULINE: EXPOSE EI AVALDA PORTI!**

- EXPOSE on **metadata only** (documentation)
- Actual port publishing: `docker run -p 3000:3000`

**Miks EXPOSE siis?**
- Documentation: Dockerfileist näha, millist porti app kasutab
- `-P` flag: `docker run -P` avaldab kõik EXPOSE'itud portid random host portidele

---

#### HEALTHCHECK - Observability Built-In

**Mis:** Automated health check containeris

**Miks oluline?**

**Without HEALTHCHECK:**
- Container status: Running (protsess töötab)
- Kas app on terve? UNKNOWN (protsess võib olla deadlock, mitte vastata)

**With HEALTHCHECK:**
- Container status: Healthy / Unhealthy
- Docker (ja Kubernetes) saavad restart'ida unhealthy containereid

**Kubernetes equivalent:**
- `livenessProbe` = HEALTHCHECK
- `readinessProbe` = Kas valmis traffic'u vastu võtma?

---

### 1.3 Dockerfile Design Patterns

**Minimal pattern:**
```dockerfile
FROM <base>
COPY <app files>
CMD <start command>
```

**Production pattern:**
```dockerfile
FROM <base>
WORKDIR /app
RUN <create non-root user>
COPY --chown=<user> <app files>
USER <user>
EXPOSE <port>
HEALTHCHECK <health command>
CMD <start command>
```

**Multi-stage pattern:**
```dockerfile
# Stage 1: Build
FROM <build image> AS builder
<build steps>

# Stage 2: Runtime
FROM <minimal runtime image>
COPY --from=builder <built artifacts>
<runtime config>
```

📖 **Praktika:** Labor 1, Harjutus 1-2 - Dockerfile loomine ja optimiseerimine

---

## 🔧 2. Layer Caching: Build Performance Optimization

### 2.1 Kuidas Layer Caching Töötab?

**Docker image = stack of layers**

Iga Dockerfile instruction loob uue layer:
```dockerfile
FROM node:18-alpine        # Layer 1 (shared from registry)
WORKDIR /app               # Layer 2 (mkdir /app)
COPY package.json .        # Layer 3 (package.json content)
RUN npm install            # Layer 4 (node_modules - LARGE!)
COPY src/ ./src/           # Layer 5 (source code)
CMD ["node", "src/index.js"] # Layer 6 (metadata only)
```

**Layer caching rule:**

> Kui layer input EI MUUTU, siis Docker kasutab cached layer'it.
> Kui layer MUUTUB, siis rebuild layer + KÕlK JÄRGNEVAD LAYERS.

**Cache invalidation cascade:**

```
src/index.js muutus
→ Layer 5 (COPY src/) invalidated
→ Layer 6 rebuild (CMD)
✅ Layers 1-4 CACHED (fast!)

package.json muutus
→ Layer 3 (COPY package.json) invalidated
→ Layers 4-6 rebuild (npm install + copy src + CMD)
❌ Slow (npm install rebuild!)
```

---

### 2.2 Layer Caching Optimization Strategies

**Anti-pattern: Copy everything first**

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .                    # ❌ Kopeerib KÕIK (sh package.json + src)
RUN npm install             # ❌ Rebuild iga src muudatuse peale!
```

**Probleem:**
- `src/index.js` muutus → `COPY . .` muutub → `npm install` rebuild (5 min)

**Optimized pattern: Copy dependencies separately**

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./       # ✅ Copy AINULT dependency files
RUN npm install             # ✅ Cached, kui package.json ei muutu!
COPY src/ ./src/            # ✅ Copy source (muutub tihti, aga ei mõjuta npm install)
```

**Benefit:**
- `src/index.js` muutus → `npm install` CACHED (10 sec build!)
- `package.json` muutus → `npm install` rebuild (5 min, aga vajalik)

**Build time võrdlus:**

| Stsenaarium | Anti-pattern | Optimized |
|-------------|-------------|-----------|
| **Clean build** | 5 min | 5 min |
| **Code change** | 5 min | 10 sec ✅ |
| **Dependency change** | 5 min | 5 min |

**ROI:** 99% build'idest on code changes → 30x kiirem!

---

### 2.3 .dockerignore: Build Context Optimization

**Mis on build context?**

`docker build .` saadab **kogu directory** Docker daemon'ile (build context).

**Probleem ilma .dockerignore'ita:**
```
node_modules/ (500MB) → saadab Docker daemon'ile → build context 500MB → SLOW
.git/ (100MB) → saadab → build context 600MB
logs/ (50MB) → saadab → build context 650MB
```

**Lahendus: .dockerignore**

```
node_modules/
.git/
.env
*.log
coverage/
```

**Build context size:**
- Ilma .dockerignore: 650MB
- .dockerignore'iga: 5MB ✅

**Performance impact:**
- Network latency: Väiksem context = kiirem upload daemon'ile
- Disk I/O: Vähem faile = kiirem COPY
- Image size: Ei kopeeri jura image'sse

**Security benefit:**
- `.env` secrets ei leki image'sse
- `.git` history ei leki (commit messages, author info)

📖 **Praktika:** Labor 1, Harjutus 3 - Layer caching optimization

---

## 🟢 3. Node.js Rakenduste Konteineriseerimise Strateegiad

### 3.1 Node.js Application Anatomy (DevOps Perspective)

**Failisüsteemi struktuur:**

```
backend-nodejs/
├── package.json           # Dependency manifest (npm config)
├── package-lock.json      # Dependency lock (exact versions)
├── src/                   # Application source code
├── node_modules/          # Installed dependencies (100-500MB!)
└── .env                   # Environment config (SECRETS - NEVER COMMIT!)
```

**DevOps administraator peaks teadma:**

1. **package.json role:**
   - Dependencies list (`express`, `pg`, `jsonwebtoken`)
   - Scripts (`npm start`, `npm test`)
   - Entry point (`main: src/index.js`)

2. **node_modules lifecycle:**
   - `npm install` - installib dependencies → `/node_modules/`
   - SIZE problem: 100-500MB (võib olla suurem kui app kood!)
   - Solution: Multi-stage build (install'i build stage'is, copy ainult production deps)

3. **Environment variables:**
   - App vajab: `DB_HOST`, `DB_PASSWORD`, `JWT_SECRET`, `PORT`
   - NEVER hardcode - use `process.env.DB_HOST`
   - DevOps seadistab runtime'il (`docker run -e`, Kubernetes Secret)

**DevOps administraator EI PEA teadma:**
- JavaScript syntax (arendaja vastutus)
- Express routing implementation (arendaja vastutus)
- SQL query optimization (DBA/arendaja vastutus)

---

### 3.2 Node.js Image Size Optimization Journey

**Naive approach: 900MB image**

```dockerfile
FROM node:18               # Debian + Node.js = 900MB base!
WORKDIR /app
COPY . .                   # All files (incl. dev dependencies!)
RUN npm install            # Dev + prod dependencies
CMD ["npm", "start"]
```

**Problems:**
- ❌ Base: Debian = 120MB + Node.js = 900MB total
- ❌ Dependencies: dev dependencies kaasas (typescript, jest, eslint)
- ❌ Security: Running as root

**Optimized approach: 150MB image**

```dockerfile
# Stage 1: Dependencies
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production    # Production deps ainult!

# Stage 2: Runtime
FROM node:18-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs src/ ./src/
USER nodejs
CMD ["node", "src/index.js"]
```

**Optimizations:**
1. ✅ Alpine base: 900MB → 150MB (Alpine = 5MB vs Debian 120MB)
2. ✅ Multi-stage: Build deps separate → runtime ainult production deps
3. ✅ `npm ci --only=production`: No dev dependencies (typescript, eslint)
4. ✅ Non-root user: Security best practice

**Size breakdown:**
- Alpine base: 5MB
- Node.js runtime: 50MB
- App code: 1MB
- Production dependencies: 94MB
- **Total: ~150MB** (vs 900MB = 83% reduction!)

---

### 3.3 Node.js Runtime Modes

**Development vs Production:**

| Aspect | Development | Production |
|--------|-------------|------------|
| **NODE_ENV** | development | production |
| **Dependencies** | All (dev + prod) | Production only |
| **Error detail** | Full stack traces | Sanitized errors |
| **Performance** | Source maps, debug | Optimized, no debug |
| **Logging** | Verbose | Structured (JSON) |

**Environment variable impact:**

```javascript
// Express behavior based on NODE_ENV
if (process.env.NODE_ENV === 'production') {
  app.use(compression());        // Gzip compression
  app.set('view cache', true);   // Template caching
} else {
  app.use(errorHandler());       // Detailed error pages
}
```

**DevOps responsibility:**
- Set `NODE_ENV=production` runtime'il (Docker, Kubernetes)
- Use `npm ci --only=production` build'is
- Never expose dev error messages production'is (security risk - stack traces leak info)

---

### 3.4 Node.js Dependency Management

**npm install vs npm ci:**

| Command | Use case | Behavior |
|---------|----------|----------|
| `npm install` | Development | Uses package.json, updates package-lock.json |
| `npm ci` | Production | Uses package-lock.json (exact versions), faster, deterministic |

**Why `npm ci` in Dockerfile?**

1. **Deterministic:** Exact versions (package-lock.json)
2. **Faster:** Skips package.json resolution
3. **Clean:** Deletes node_modules/ before install (no stale deps)

**package-lock.json importance:**
- Locks transitive dependencies (dependency-of-dependency versions)
- Without lock: `express` updates sub-dependency → breaking change
- With lock: Exact versions guaranteed → reproducible builds

📖 **Praktika:** Labor 1, Harjutus 4 - Node.js multi-stage build

---

## ☕ 4. Java/Spring Boot Konteineriseerimise Strateegiad

### 4.1 Java Deployment Model Evolution

**Traditional: WAR + Application Server**

```
[WAR file] → deployed to → [Shared Tomcat Server]
                              ├── App1.war
                              ├── App2.war
                              └── App3.war
```

**Problems:**
- ❌ Shared server: Version conflicts (App1 needs Tomcat 9, App2 needs Tomcat 10)
- ❌ Coupling: Apps share same JVM settings (heap size, GC)
- ❌ Deployment complexity: Deploy WAR → restart Tomcat → affects all apps
- ❌ Scaling: Can't scale one app independently

**Modern: Spring Boot + Embedded Server**

```
[Executable JAR] = App code + Embedded Tomcat + Dependencies
```

**Benefits:**
- ✅ Self-contained: JAR sisaldab Tomcat'i (no external server needed)
- ✅ Isolation: Iga app = eraldi JAR = oma JVM = oma Tomcat
- ✅ Simple deployment: `java -jar app.jar` (no server config)
- ✅ Cloud-native: Saab containeriseerida, scaleerida Kubernetes'es

**DevOps perspective:**

WAR model → DevOps haldab Tomcat server'it (config, versions, shared resources)
JAR model → DevOps deploy'b JAR'i (app = self-contained unit)

**Transition:**
- Legacy apps: WAR + Tomcat (supported, aga legacy)
- Modern apps: Spring Boot JAR (cloud-native standard)

---

### 4.2 Java Build Tools: Maven vs Gradle

**Arhitektuurilised erinevused:**

| Aspect | Maven | Gradle |
|--------|-------|--------|
| **Config format** | XML (`pom.xml`) | Groovy/Kotlin DSL (`build.gradle`) |
| **Philosophy** | Convention over configuration | Flexibility |
| **Build speed** | Slower (no incremental builds) | Faster (incremental builds, caching) |
| **Dependency management** | Transitive dependency hell | Better conflict resolution |
| **Ecosystem** | Older, larger plugin ecosystem | Modern, growing |

**DevOps perspective:**

**Maven:**
- `./mvnw clean package` - Build JAR
- `pom.xml` - Dependency manifest
- `.m2/repository/` - Local cache (~GB'id!)

**Gradle:**
- `./gradlew bootJar` - Build executable JAR
- `build.gradle` - Dependency manifest
- `.gradle/` - Build cache

**Wrapper pattern:**
- `mvnw` / `gradlew` - Wrapper scripts (committed to repo)
- No global Maven/Gradle installation needed
- Consistent versions across team

---

### 4.3 Java Image Size Optimization: JDK vs JRE

**Build vs Runtime requirements:**

**JDK (Java Development Kit):**
- Compiler (`javac`)
- Build tools
- Debug tools
- Size: ~300MB

**JRE (Java Runtime Environment):**
- Java VM
- Core libraries
- NO compiler
- Size: ~100MB

**Multi-stage strategy:**

```dockerfile
# Stage 1: Build (needs JDK)
FROM gradle:8.5-jdk17 AS builder
<build JAR using javac>

# Stage 2: Runtime (needs JRE only)
FROM eclipse-temurin:17-jre-alpine AS runner
COPY --from=builder <JAR file>
```

**Benefit:**
- Build stage: JDK + Gradle = 470MB (needed for compilation)
- Runtime stage: JRE Alpine = 180MB (only runtime needed)
- Final image: 180MB vs 470MB = 62% reduction!

**Why not use JDK in runtime?**
- Security: Less code = less attack surface (no compiler = no runtime compilation exploits)
- Size: Smaller images = faster pulls, less storage
- Performance: JRE is optimized for runtime (no dev tools overhead)

---

### 4.4 Java Memory Management (DevOps Perspective)

**JVM Heap configuration:**

**Default behavior:**
```
JVM allocates heap based on container memory limit
Docker container: 1GB RAM → JVM may allocate 512MB heap (automatic)
```

**Problem: OutOfMemoryError**

**Causes:**
1. Heap too small for workload
2. Memory leak in application code
3. JVM doesn't respect container limits (old JVMs)

**Solution: Explicit heap sizing**

```dockerfile
ENV JAVA_OPTS="-Xmx512m -Xms256m"
```

**Parameters:**
- `-Xmx512m` - Maximum heap (cap)
- `-Xms256m` - Initial heap (startup allocation)

**Sizing strategy:**
- Container limit: 1GB
- JVM heap: 512MB (-Xmx512m)
- Remaining: 512MB for JVM non-heap (metaspace, threads, native memory)

**Kubernetes resource limits:**
```yaml
resources:
  requests:
    memory: "512Mi"    # Guaranteed
  limits:
    memory: "1Gi"      # Maximum (OOMKilled if exceeded)
```

**Best practice:**
- Set `-Xmx` to ~50% of container memory limit
- Leave room for non-heap memory
- Monitor memory usage (Prometheus JVM metrics)

📖 **Praktika:** Labor 1, Harjutus 5 - Java multi-stage build

---

## 🗄️ 5. Database Migrations: DevOps Perspective

### 5.1 Miks Automated Database Migrations?

**Traditional manual approach:**

```
1. DBA kirjutab SQL faili (001-create-users.sql)
2. DevOps käivitab: psql -f 001-create-users.sql
3. DBA kirjutab 002-add-email-column.sql
4. DevOps käivitab: psql -f 002-add-email-column.sql
```

**Problems:**
- ❌ Manual execution (error-prone, kui DBA unustab step'i)
- ❌ No tracking (kas 002 on applied? Unclear)
- ❌ No rollback (kui 002 breaks production, kuidas rollback?)
- ❌ Environment drift (dev DB ≠ staging DB ≠ prod DB)

**Automated migrations (Liquibase, Flyway):**

```
Application startup → Migration tool checks DB → Applies pending migrations → Ready
```

**Benefits:**
1. **Automatic:** No manual SQL execution (app applies migrations)
2. **Versioned:** Migration history tracked in DB (databasechangelog table)
3. **Idempotent:** Rerunning migrations = safe (already applied migrations skipped)
4. **Rollback:** Migrations have rollback definitions
5. **Environment parity:** Same migrations run in dev/staging/prod → consistent schema

---

### 5.2 Liquibase Architecture

**Components:**

1. **Changelog Master:**
   - References all changesets
   - Execution order

2. **Changesets:**
   - Individual DB changes (CREATE TABLE, ADD COLUMN)
   - ID + Author + Rollback

3. **Tracking table:**
   - `databasechangelog` - Applied migrations log
   - `databasechangeloglock` - Prevents concurrent migrations

**Execution flow:**

```
1. App starts
2. Liquibase reads changelog master
3. Liquibase checks databasechangelog table
4. Calculates pending migrations (not yet applied)
5. Acquires lock (databasechangeloglock)
6. Applies migrations sequentially
7. Updates databasechangelog
8. Releases lock
9. App ready
```

---

### 5.3 DevOps Responsibilities for Migrations

**Mida DevOps TEEB:**

1. **Monitor migration execution:**
   - Application startup logs: "Liquibase: Successfully applied 3 changesets"
   - Error handling: Migration failure → app crashes (fail fast!)

2. **Troubleshoot locked migrations:**
   - Symptom: App hangs at startup
   - Cause: Previous migration crashed → lock not released
   - Solution: Check `databasechangeloglock`, manually unlock if safe

3. **Verify migration history:**
   - Query `databasechangelog` table
   - Ensure all expected migrations applied
   - Compare dev vs staging vs prod (should be identical)

4. **Rollback (emergency):**
   - Liquibase rollback commands (pre-defined rollback changesets)
   - Coordination with DBA/developers

**Mida DevOps EI TEE:**
- ❌ Kirjutab SQL päringuid (arendaja/DBA vastutus)
- ❌ Disainib database skeeme (arendaja/DBA vastutus)
- ❌ Optimeerib SQL queries (arendaja/DBA vastutus)

**Troubleshooting scenario:**

**Problem:** App fails to start

**Logs:**
```
Liquibase: Waiting for changelog lock....
```

**Diagnosis:**
```sql
SELECT * FROM databasechangeloglock;
-- locked = true, lockedby = pod-abc (crashed pod)
```

**Solution:**
```sql
DELETE FROM databasechangeloglock;
-- Restart app → migration resumes
```

**Root cause:** Previous pod crashed during migration → lock not released → new pod blocked

📖 **Praktika:** Labor 2, Harjutus 3 - Database migrations troubleshooting

---

## 🎓 6. Multi-Stage Builds: Architecture Pattern

### 6.1 Miks Multi-Stage Builds?

**Single-stage probleem:**

```dockerfile
FROM node:18             # 900MB (includes build tools)
RUN npm install          # Dev dependencies (typescript, eslint)
<build steps>
CMD ["node", "dist/index.js"]
```

**Final image sisaldab:**
- ✅ Runtime (Node.js) - needed
- ❌ Build tools (npm, gcc, make) - NOT needed
- ❌ Dev dependencies (typescript) - NOT needed
- ❌ Source code (.ts files) - NOT needed (have compiled .js)

**Result:** 900MB image, millest ~70% on jura (unused build artifacts)

---

### 6.2 Multi-Stage Pattern: Separation of Concerns

**Architecture:**

```dockerfile
# ============================================
# Stage 1: Builder (Heavy)
# ============================================
FROM <language>-full AS builder
# Install build tools
# Install ALL dependencies (dev + prod)
# Compile/build app
# Run tests (optional)
# Output: Built artifacts (JAR, compiled JS, etc.)

# ============================================
# Stage 2: Runtime (Minimal)
# ============================================
FROM <language>-runtime-alpine AS runner
# Copy ONLY built artifacts from builder
# Copy ONLY production dependencies
# Configure runtime
# Start app
```

**Benefits:**

1. **Size optimization:**
   - Builder stage: 900MB (build tools + dev deps + source)
   - Runtime stage: 150MB (runtime + prod deps + built artifacts)
   - **Saved: 750MB (83% reduction!)**

2. **Security:**
   - No build tools in final image (no gcc, make → can't compile malware)
   - No source code in image (no intellectual property leak)
   - Minimal base (Alpine) = smaller attack surface

3. **Performance:**
   - Smaller images = faster docker pull (180MB vs 470MB = 2.6x faster)
   - Less disk I/O, less network transfer

4. **Clean separation:**
   - Build concerns (compilation, testing) separate from runtime concerns (execution)

---

### 6.3 Multi-Stage Best Practices

**Pattern 1: Build + Runtime**

```dockerfile
FROM <build-image> AS builder
<build steps>

FROM <runtime-image> AS runner
COPY --from=builder <artifacts>
```

**Pattern 2: Dependencies + Build + Runtime**

```dockerfile
# Stage 1: Download dependencies (cached separately!)
FROM <image> AS deps
COPY package.json .
RUN <install deps>

# Stage 2: Build
FROM <image> AS builder
COPY --from=deps <deps>
COPY src/ .
RUN <build>

# Stage 3: Runtime
FROM <runtime-image> AS runner
COPY --from=builder <built artifacts>
```

**Benefit of 3-stage:**
- Dependency layer cached separately
- Code change → rebuild, aga dependencies cached

**Stage naming:**
- Use `AS <name>` (builder, runner, deps)
- `COPY --from=<name>` references previous stage
- Self-documenting

**Target specific stage:**
```bash
# Build only builder stage (testing)
docker build --target builder -t myapp:builder .

# Build full image (default: last stage)
docker build -t myapp:runtime .
```

📖 **Praktika:** Labor 1, Harjutus 6 - Multi-stage optimization comparison

---

## 🔒 7. Security Best Practices

### 7.1 Non-Root Users

**Problem: Default root**

Containers run as UID 0 (root) by default:
- Container escape → attacker has root on host
- Kubernetes PodSecurityPolicy rejects root containers (security enforcement)

**Solution: Explicit non-root user**

```dockerfile
RUN addgroup --system --gid 1001 appuser && \
    adduser --system --uid 1001 appuser
USER appuser
```

**File ownership:**
```dockerfile
COPY --chown=appuser:appuser src/ ./src/
```

**Why explicit UID/GID (1001)?**
- Predictable: Same UID across environments
- Kubernetes volume permissions: Volume mounted with UID 1001 → appuser can write
- Security policies: PSP/PSS can enforce UID > 1000 (non-root range)

---

### 7.2 Minimal Base Images

**Alpine philosophy:**
- Minimal packages (only essentials)
- musl libc (lighter than glibc)
- apk package manager (minimal)

**Security benefits:**
- Fewer packages = fewer vulnerabilities
- Small attack surface
- Regular security updates (Alpine security team)

**Trade-off:**
- Compatibility: musl libc ≠ glibc (some C libraries don't work)
- Debugging: No bash (only sh), no standard GNU tools

**When NOT to use Alpine:**
- Complex C dependencies (use Debian)
- Legacy apps requiring glibc

---

### 7.3 Secret Management

**NEVER:**
```dockerfile
ENV DB_PASSWORD=mysecret    # ❌ Secret in image layer!
COPY .env /app/.env         # ❌ Secret in image!
```

**Why dangerous:**
- Image layers are readable (docker history)
- Image pushed to registry → secret leaked
- Image shared → secret compromised

**Correct approach:**
- **Runtime injection:** `docker run -e DB_PASSWORD=secret`
- **Kubernetes Secrets:** Mount as env var or file
- **Vault/AWS Secrets Manager:** Fetch at runtime

**Build-time secrets (ARG):**
```dockerfile
ARG NPM_TOKEN              # Build-time only
RUN npm config set //registry.npmjs.org/:_authToken=$NPM_TOKEN
```

**ARG vs ENV:**
- ARG: Build-time, not in final image
- ENV: Runtime, persisted in image

📖 **Praktika:** Labor 1, Harjutus 7 - Security hardening

---

## 🐛 8. Build Troubleshooting

### 8.1 Common Build Errors

**Error: "Cannot find module 'express'"**

**Cause:**
- Dependencies not installed
- Wrong COPY order (copied source before npm install)

**Diagnosis:**
```dockerfile
RUN npm install    # Check if this ran
COPY src/ .        # Check order
```

**Error: "COPY failed: no such file or directory"**

**Cause:**
- File not in build context
- Excluded by .dockerignore

**Diagnosis:**
```bash
# Check build context
docker build -t myapp --progress=plain .
# Look for "COPY src/ ./src/" → shows files copied
```

---

### 8.2 Cache Debugging

**Problem:** Cache not working

**Cause:**
- File timestamps changed (Git clone resets timestamps)
- Whitespace changes in Dockerfile

**Diagnosis:**
```bash
docker build --no-cache .   # Force rebuild all layers
```

**Problem:** Cache too aggressive

**Solution:**
```bash
docker build --pull .       # Force pull latest base image
```

---

### 8.3 Build Performance

**Slow builds:**

**Cause 1:** Large build context
**Solution:** Add to .dockerignore

**Cause 2:** Rebuilding dependencies
**Solution:** Optimize layer caching (COPY package.json separately)

**Cause 3:** Network-heavy operations
**Solution:** Cache dependencies in earlier layers

📖 **Praktika:** Labor 1, Harjutus 8-10 - Build debugging ja troubleshooting

---

## 🎓 9. Mida Sa Õppisid?

### Põhilised Kontseptsioonid

✅ **Dockerfile Architecture:**
- Dockerfile kui Infrastructure as Code (version control, reproducibility)
- Instruction'ide roll (FROM, RUN, COPY, CMD, USER)
- Exec form vs shell form (signal handling)

✅ **Image Optimization:**
- Layer caching architecture ja performance impact
- Multi-stage builds (build vs runtime separation)
- Base image selection (Alpine vs Debian trade-offs)
- Image size reduction tehnikad (900MB → 150MB)

✅ **Application-Specific Strategies:**
- Node.js: npm ci, production dependencies, multi-stage
- Java/Spring Boot: JDK vs JRE, JAR model, memory management
- Dependency management (package-lock.json, Gradle wrapper)

✅ **Database Migrations:**
- Automated migrations architecture (Liquibase)
- DevOps responsibilities (monitor, troubleshoot, verify)
- Migration tracking ja rollback

✅ **Security Best Practices:**
- Non-root users (defense in depth)
- Minimal base images (attack surface reduction)
- Secret management (runtime injection, NEVER in image)

✅ **Troubleshooting:**
- Build error patterns
- Cache debugging
- Performance optimization

---

## 🚀 10. Järgmised Sammud

**Peatükk 6: PostgreSQL Konteinerites** 🗄️

Nüüd kui oskad rakendusi konteineriseerida, on aeg õppida **stateful rakendusi** (andmebaasid):

- Volume lifecycle management
- Data persistence strategies
- PostgreSQL configuration containeris
- Backup ja restore
- Performance tuning

**Peatükk 7: Docker Compose** 🐳

Multi-container orkestratsioon:
- Declarative multi-container apps
- Service dependencies
- Network configuration
- Volume management

📖 **Praktika:** Labor 1 sisaldab kõikide selle peatüki kontseptsioonide hands-on harjutusi.

---

## ✅ Kontrolli Ennast

Enne järgmisele peatükile liikumist, veendu et:

- [ ] Mõistad Dockerfile'i rolli IaC'na (version control, reproducibility)
- [ ] Oskad selgitada layer caching'u performance impact'i
- [ ] Mõistad multi-stage build'i optimiseerimise põhimõtteid
- [ ] Oskad selgitada Alpine vs Debian trade-off'e
- [ ] Mõistad Node.js dependency management'i (npm ci, production deps)
- [ ] Mõistad Java deployment model evolutiooni (WAR → JAR)
- [ ] Mõistad database migrations'i rolli DevOps workflow's
- [ ] Oskad rakendada security best practices (non-root, minimal base)

**Kui kõik on ✅, oled valmis Peatükiks 6!** 🚀

---

**Peatükk 5 lõpp**
**Järgmine:** Peatükk 6 - PostgreSQL Konteinerites
