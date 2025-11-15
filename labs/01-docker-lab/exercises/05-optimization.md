# Harjutus 5: Image Optimization

**Kestus:** 45 minutit
**Eesmärk:** Optimeeri Docker image suurust ja build kiirust

---

## 🎯 Õpieesmärgid

- ✅ Kasutada alpine base images
- ✅ Implementeerida multi-stage builds
- ✅ Optimeerida layer caching
- ✅ Kasutada .dockerignore
- ✅ Skanneerida image turvaauke

---

## 📝 Sammud

### Samm 1: Mõõda Algne Suurus

```bash
cd ../../apps/backend-nodejs

# Vaata praeguse image suurust
docker images user-service:1.0

# Peaks olema ~150-200MB
```

### Samm 2: Optimeeri Dockerfile

Loo uus `Dockerfile.optimized`:

```dockerfile
# Stage 1: Dependencies
FROM node:18-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime
FROM node:18-alpine
WORKDIR /app

# Loo non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Kopeeri ainult production sõltuvused
COPY --from=dependencies /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .

# Kasuta non-root userit
USER nodejs

EXPOSE 3000
CMD ["node", "server.js"]
```

### Samm 3: Build Optimeeritud Image

```bash
# Build uus image
docker build -f Dockerfile.optimized -t user-service:1.0-optimized .

# Võrdle suurusi
docker images | grep user-service
```

### Samm 4: Testi Optimeeritud Image

```bash
# Käivita
docker run -d \
  --name user-service-opt \
  --network app-network \
  -p 3001:3000 \
  -e DB_HOST=postgres-users \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-secret-key \
  user-service:1.0-optimized

# Testi
curl http://localhost:3001/health
```

### Samm 5: Security Scan (Bonus)

```bash
# Installi trivy (kui pole)
# sudo apt install trivy  # või
# brew install trivy

# Skanni image
trivy image user-service:1.0-optimized

# Vaata turvaauke
```

### Samm 6: Layer Caching Test

```bash
# Rebuild ilma muudatusteta
docker build -f Dockerfile.optimized -t user-service:1.0-optimized .
# Peaks kasutama cached layers!

# Muuda midagi server.js's
echo "// comment" >> server.js

# Rebuild
docker build -f Dockerfile.optimized -t user-service:1.0-optimized .
# Ainult viimased layer'id rebuilditakse
```

---

## 📊 Optimisatsioonide Võrdlus

| Aspect | Before | After |
|--------|--------|-------|
| **Size** | ~200MB | ~120MB |
| **Layers** | 10+ | 6-8 |
| **Build time** | 30s | 15s (cached) |
| **Security** | root user | non-root user |

---

## ✅ Kontrolli

- [ ] Optimeeritud image on väiksem
- [ ] Multi-stage build töötab
- [ ] Layer caching toimib
- [ ] Non-root user kasutusel
- [ ] Security scan läbitud

---

## 🎓 Parimad Tavad

1. ✅ Kasuta alpine images
2. ✅ Multi-stage builds
3. ✅ Layer caching (COPY package.json enne kood)
4. ✅ .dockerignore fail
5. ✅ Non-root user
6. ✅ npm ci instead of npm install
7. ✅ --only=production flag

---

**Õnnitleme! Oled läbinud Labor 1! 🎉**

**Järgmine:** [Labor 2: Docker Compose](../../02-docker-compose-lab/README.md)
