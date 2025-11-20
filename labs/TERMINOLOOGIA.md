# Docker & DevOps Terminoloogia Sõnastik

Selle dokumendi eesmärk on ühtlustada terminoloogiat kõigis labori harjutustes.

## Põhimõte

Kasutame **eestikeelseid sõnu**, tehnilised terminid **sulgudes inglise keeles**.

**Näide:** "Ehita Docker pilt (image) kasutades mitme-sammulist (multi-stage) build'i"

---

## Sõnastik

| Eesti keeles | Inglise keeles | Näide kasutuses |
|--------------|----------------|-----------------|
| ehita | build | Ehita Docker pilt (image) |
| pilt (image) | image | Docker pilt (image) |
| pildid (images) | images | Vaata kõiki pilte (images) |
| baaspilt (base image) | base image | Node.js 18 baaspilt (base image) |
| kiht (layer) | layer | Iga RUN käsk loob uue kihi (layer) |
| kihid (layers) | layers | Mitu kihti (layers) on pildil? |
| mitme-sammuline (multi-stage) | multi-stage | Mitme-sammuline (multi-stage) build |
| vahemälu (cache) | cache | Kihtide vahemälu (layer cache) |
| andmehoidla (volume) | volume | PostgreSQL andmehoidla (volume) |
| võrk (network) | network | Docker võrk (network) |
| kohandatud võrk (custom network) | custom network | Loo kohandatud võrk (custom network) |
| sõltuvused (dependencies) | dependencies | npm sõltuvused (dependencies) |
| seisukorra kontroll (health check) | health check | Seisukorra kontroll (health check) |
| parim praktika (best practice) | best practice | Dockeri parimad praktikad (best practices) |
| võrkude isolatsioon (network isolation) | network isolation | Võrkude isolatsioon (network isolation) |
| seadistus | setup | PostgreSQL seadistus |
| konteiner (container) | container | Docker konteiner (container) |
| tag | tag | Docker pilt tag'iga 1.0 |
| taustal töötav režiim | detached mode | Käivita taustal töötavas režiimis (detached mode) |
| portide vastendamine (port mapping) | port mapping | Portide vastendamine (port mapping) 3000:3000 |
| hangub/hangunud | crash/crashed | Konteiner hangub (crashes) andmebaasi puudumise tõttu |

---

## Mida EI tõlgita

### Käsud
Dockeri käsud jäävad inglise keelde:
- `docker build`
- `docker run`
- `docker ps`
- `docker logs`
- `docker exec`
- `docker network create`
- `docker volume create`

### Faininimed
Failinimed jäävad muutmata:
- `Dockerfile`
- `Dockerfile.optimized`
- `.dockerignore`
- `package.json`
- `build.gradle`

### Parameetrid ja lipud
Käsu parameetrid jäävad:
- `--name`
- `-p` (port)
- `-d` (detached)
- `-v` (volume)
- `--network`
- `-e` (environment)
- `-it` (interactive + tty)

### Tehnilised võtmesõnad koodis
Dockerfile instruktsioonis jäävad inglise keelde:
- `FROM`, `WORKDIR`, `COPY`, `RUN`, `EXPOSE`, `CMD`, `ENTRYPOINT`
- `USER`, `HEALTHCHECK`, `VOLUME`, `ENV`

---

## Kasutusnäited

### ✅ Õige
```markdown
Ehita Docker pilt (image) kasutades Node.js 18 baaspilti (base image).
Iga RUN käsk loob uue kihi (layer), mis salvestatakse vahemällu (cache).
```

### ❌ Vale
```markdown
Build Docker image kasutades Node.js 18 base image.
Iga RUN käsk loob uue layer, mis salvestatakse cache'sse.
```

---

## Versioon

- **Loodud:** 2025-01-20
- **Viimati uuendatud:** 2025-01-20
- **Kehtib:** Lab 1 kõikidele harjutustele (01-06)
