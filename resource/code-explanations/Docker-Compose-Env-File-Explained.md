# Docker Compose .env Fail - Koodiselgitus

**Eesmärk:** Defineeri keskkonnamuutujad ühes kohas, mida saad hiljem docker-compose.yml'is kasutada.

## .env Faili Näidis

Loo `.env` fail saladustele ja konfiguratsioonile:

```bash
# ==========================================================================
# Environment Variables - Docker Compose (LOCAL TESTING)
# ==========================================================================
# TÄHTIS: See fail sisaldab saladusi!
# EI TOHI commit'ida Git'i! Lisa .gitignore'i!
# MÄRKUS: Need on LIHTSAMAD väärtused testimiseks.
#         Production'is kasuta .env.prod faili tugevate paroolidega!
# ==========================================================================

# PostgreSQL Credentials
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres  # Harjutus 3 vaikeväärtus (lihtne local testing jaoks)

# JWT Configuration
JWT_SECRET=VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=  # Harjutus 3 väärtus
JWT_EXPIRES_IN=1h

# Application Ports (ei kasutata production mode'is - pordid eemaldatud)
USER_SERVICE_PORT=3000
TODO_SERVICE_PORT=8081
FRONTEND_PORT=8080
POSTGRES_USER_PORT=5432
POSTGRES_TODO_PORT=5433

# Database Names
USER_DB_NAME=user_service_db
TODO_DB_NAME=todo_service_db

# Node.js Environment
NODE_ENV=production

# Java Options
JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0

# Spring Profile
SPRING_PROFILE=prod
```

See samm võtab kõik rakenduse konfiguratsiooni ja saladused (paroolid, JWT võtmed jms) ja koondab need ühte keskseks `.env` faili, et docker-compose saaks neid muutujana kasutada ning et neid ei satuks kogemata Git'i ega pildi sisse.

## Mis on `.env` fail siin?

- Tavaline tekstifail samas kataloogis, kus on `docker-compose.yml`, kus iga rida on kujul `NIMI=väärtus` ilma jutumärkideta.
- Docker Compose loeb sealt võtme–väärtuse paarid ja asendab need komponis `docker-compose.yml` sees (nt `${POSTGRES_USER}`) ning/või annab need konteinerite keskkonnamuutujatena edasi.

## Miks hoida seda failis, mitte YAML-is?

- **Üks koht kõikidele seadistustele:** paroolid, portid, DB nimed, profiilid jms, mida muudad tihti või mis on masina/spetsiifilised.
- **Sama docker-compose.yml erinevates keskkondades:** Sama `docker-compose.yml` saab kasutada nii lokaalses testimises kui tootmises, vahetades ainult `.env` faili (`.env`, `.env.prod`, jne).

## Turvalisus ja Git

- Failis on paroolid ja JWT salavõti, seega seda ei tohi Git'i commit'ida; sellepärast käib sinna kommentaar "lisa `.gitignore`‑i".
- **Best practice:** Hoia eraldi näiteks `.env` (simple, local) ja `.env.prod` (tugevad paroolid, tootmine) ning jaga tootmisfaili turvalise kanali kaudu, mitte repo kaudu.

## Mida iga plokk semantiliselt tähendab?

### PostgreSQL Credentials
Kasutaja+parool mõlema Postgres konteineri jaoks; lihtsad väärtused, sobivad ainult lokaalseks harjutamiseks.

### JWT Configuration
- `JWT_SECRET` on võti, millega teenused signeerivad ja valideerivad token'eid
- `JWT_EXPIRES_IN=1h` ütleb, kui kaua token kehtib

### Application Ports
Defineerib, mis hostipordid seotakse teenuste külge lokaalses režiimis; tootmises võid lasta liiklusel tulla läbi reverse proxy või muude portide, seetõttu "ei kasutata production'is".

### Database Names
Eristab kasutaja-teenuse ja TODO-teenuse andmebaase samas Postgres instantsis, nii et skeemid ei läheks sassi.

### NODE_ENV, JAVA_OPTS, SPRING_PROFILE
Teenuste käitumise nuppud:
- **Node.js:** `NODE_ENV=production` (production mode)
- **Java:** `JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0` (konteinerile optimeeritud mälu seaded)
- **Spring Boot:** `SPRING_PROFILE=prod` (profiil, mille järgi Spring laeb vastava konfiguratsiooni)

## Kuidas seda docker-compose'is kasutatakse?

**docker-compose.yml failis:**
```yaml
services:
  postgres-user:
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

  user-service:
    environment:
      JWT_SECRET: ${JWT_SECRET}
      NODE_ENV: ${NODE_ENV}
```

Docker Compose:
1. Loeb `.env` faili (automaatselt, kui asub samas kataloogis)
2. Asendab `${POSTGRES_USER}`, `${JWT_SECRET}`, `${SPRING_PROFILE}` jne väärtustega `.env` failist
3. Käivitab teenused nende keskkonnamuutujatega

**Erinevad keskkonnad:**
```bash
# TEST keskkond
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d

# PRODUCTION keskkond
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
```

Sama `docker-compose.yml`, erinevad paroolid ja seadistused – ilma et peaksid Compose'i või image'e muutma.

---

**Viimane uuendus:** 2025-12-13
**Tüüp:** Koodiselgitus
**Kasutatakse:** Lab 2, Harjutus 4 (Keskkondade haldus)
