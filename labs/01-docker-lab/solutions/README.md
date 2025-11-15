# Labor 1 Lahendused

See kaust sisaldab näidis-lahendusi Labor 1 harjutustele.

---

## 📂 Struktuur

```
solutions/
├── README.md                    # See fail
├── backend-nodejs/
│   ├── Dockerfile               # Lihtne Dockerfile (Harjutus 1)
│   ├── Dockerfile.optimized     # Optimeeritud (Harjutus 5)
│   └── .dockerignore
└── (teised rakendused lisatakse hiljem)
```

---

## 🚀 Kasutamine

### Lihtne Dockerfile

```bash
# Mine apps/backend-nodejs kausta
cd ../../apps/backend-nodejs

# Kopeeri Dockerfile
cp ../../01-docker-lab/solutions/backend-nodejs/Dockerfile .
cp ../../01-docker-lab/solutions/backend-nodejs/.dockerignore .

# Build
docker build -t user-service:1.0 .

# Käivita
docker run -d --name user-service -p 3000:3000 user-service:1.0
```

### Optimeeritud Dockerfile

```bash
# Kopeeri optimeeritud versioon
cp ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized .

# Build
docker build -f Dockerfile.optimized -t user-service:1.0-opt .

# Võrdle suurusi
docker images | grep user-service
```

---

## 📊 Image Suuruste Võrdlus

| Versioon | Suurus | Kirjeldus |
|----------|--------|-----------|
| **Lihtne** | ~150-200MB | node:18-alpine + kõik sõltuvused |
| **Optimeeritud** | ~100-120MB | Multi-stage + npm ci + non-root |

---

## 💡 Märkused

- Need on **näidis-lahendused** - proovi esmalt ise!
- Optimeeritud versioon sisaldab:
  - Multi-stage build
  - Non-root user
  - Health check
  - npm ci instead of npm install
  - Layer caching optimisatsioon

---

**Kasuta neid ainult kui jääd hätta! Õppimine toimub läbi proovimise. 💪**
