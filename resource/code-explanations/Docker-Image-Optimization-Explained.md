# Docker Image Optimeerimise 5 Eesmärki

Docker image optimeerimise peamised eesmärgid tootmiskõlbuliku rakenduse jaoks.

---

## 1️⃣ Kiire Arendusprotsess - Layer Caching

**Probleem:**
```dockerfile
COPY . .                    # ← Muudad üht faili → kogu npm install uuesti!
RUN npm install             # ← 30-60 sekundit IGAL rebuild'il
```

**Lahendus:**
```dockerfile
COPY package*.json ./       # ← Muutub harva
RUN npm install             # ← Cached! Rebuild 5 sekundit
COPY . .                    # ← Muutub tihti, aga kiire
```

**Tulemus:** Arendaja muudab koodi → rebuild **60-80% kiirem** (30s → 5s)

---

## 2️⃣ Väiksem Image Suurus - Multi-stage Build

**Java näide:**
```dockerfile
# Stage 1: BUILD (JDK + Gradle + source) → 800MB
FROM gradle:8-jdk21 AS builder
RUN gradle bootJar

# Stage 2: RUNTIME (ainult JRE + JAR) → 250MB
FROM eclipse-temurin:21-jre
COPY --from=builder /app/app.jar .
```

**Tulemus:**
- Image 70% väiksem (800MB → 250MB)
- Kiirem deployment (vähem allalaadida)
- Vähem kõvaketta kasutust

---

## 3️⃣ Turvalisus - Non-root User + Health Checks

```dockerfile
# Loo mitte-juurkasutaja
RUN adduser -S spring -u 1001
USER spring:spring

# Tervisekontroll
HEALTHCHECK --interval=30s \
  CMD wget --spider http://localhost:8081/health || exit 1
```

**Tulemus:**
- Rakendus ei tööta root'ina → vähem turvariski
- Orkestreerijad (Docker Compose, Kubernetes) näevad konteineri tervist
- Automaatne restart, kui konteiner ei vasta

---

## 4️⃣ Portaabelsus - Corporate Proxy Tugi

```dockerfile
# ARG-põhine proxy konfiguratsioon
ARG HTTP_PROXY=""
ENV HTTP_PROXY=${HTTP_PROXY}  # ← AINULT builder stage'is
RUN npm install               # ← Kasutab proxy'd, kui määratud

# Runtime stage
FROM node:22-slim             # ← Proxy POLE siin (clean!)
```

**Tulemus:**
- Sama Dockerfile töötab Intel võrgus JA AWS/GCP/Azure
- Ei leki proxy info tootmisse
- Production-ready

---

## 5️⃣ CI/CD Kiirus - Reproducible Builds

```dockerfile
# Deterministlik build
RUN npm ci --only=production  # ← package-lock.json garanteerib sama tulemuse
```

**Tulemus:**
- Sama image igal build'il (reproducible)
- CI/CD pipeline kiirem (cache töötab)
- Vähem ootamist deployment'il

---

**Viimane uuendus:** 2025-01-25
**Tüüp:** Koodiselgitus
**Kasutatakse:** Lab 1 (Harjutus 05 - Image Optimeerimine)
