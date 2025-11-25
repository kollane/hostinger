# Labor 2: Docker Compose - Lahendused

See kaust sisaldab näidislahendusi kõigile Labor 2 harjutustele. Iga harjutuse lahendus on organiseeritud eraldi kausta.

## Failide Struktuur

```
solutions/
├── 01-compose-basics/          # Harjutus 1 lahendus
│   └── docker-compose.yml
├── 02-add-frontend/            # Harjutus 2 lahendus
│   ├── docker-compose-full.yml
│   └── nginx.conf
├── 03-network-segmentation/    # Harjutus 3 lahendus
│   └── docker-compose.secure.yml
├── 04-environment-management/  # Harjutus 4 lahendus
│   ├── .env.example
│   ├── .env.dev
│   ├── .env.prod
│   └── .env.external
├── 05-database-migrations/     # Harjutus 5 lahendus
│   └── liquibase/
│       ├── changelog-master.xml
│       └── changelogs/
│           ├── 001-create-users-table.xml
│           └── 002-create-todos-table.xml
├── 06-production-patterns/     # Harjutus 6 lahendus
│   └── docker-compose.prod.yml
└── 07-advanced-patterns/       # Harjutus 7 lahendus
    └── docker-compose.override.yml
```

## Harjutuste Lahendused

### Harjutus 1: Docker Compose Alused

**Failid:**
- `01-compose-basics/docker-compose.yml` - 4 teenust (2x PostgreSQL, user-service, todo-service)

**Kirjeldus:**
- Konverteerib Lab 1 lõpuseisu docker-compose.yml failiks
- Kasutab external volumes ja networks

**Kasutamine:**
```bash
cd compose-project
cp ../solutions/01-compose-basics/docker-compose.yml .
docker compose up -d
```

### Harjutus 2: Lisa Frontend

**Failid:**
- `02-add-frontend/docker-compose-full.yml` - 5 teenust (+ frontend)
- `02-add-frontend/nginx.conf` - Nginx konfiguratsioon

**Kirjeldus:**
- Lisab Nginx frontend teenuse
- Mount'ib staatilised failid

**Kasutamine:**
```bash
cd compose-project
cp ../solutions/02-add-frontend/docker-compose-full.yml .
cp ../solutions/02-add-frontend/nginx.conf .
docker compose -f docker-compose-full.yml up -d
```

### Harjutus 3: Network Segmentation

**Failid:**
- `03-network-segmentation/docker-compose.secure.yml` - Võrgu segmenteerimisega konfiguratsioon

**Kirjeldus:**
- Eraldab teenused erinevatesse võrkudesse
- Turvalisem arhitektuur

**Kasutamine:**
```bash
cd compose-project
cp ../solutions/03-network-segmentation/docker-compose.secure.yml .
docker compose -f docker-compose.secure.yml up -d
```

### Harjutus 4: Environment Management

**Failid:**
- `04-environment-management/.env.example` - Environment variables template
- `04-environment-management/.env.dev` - Development keskkonna seadistused
- `04-environment-management/.env.prod` - Production keskkonna seadistused
- `04-environment-management/.env.external` - External teenuste seadistused

**Kirjeldus:**
- Näitab, kuidas hallata salajaseid turvaliselt
- Eraldi .env failid erinevateks keskkondadeks

**Kasutamine:**
```bash
cd compose-project
cp ../solutions/04-environment-management/.env.example .env

# Muuda salajaseid
vim .env

# Käivita docker-compose.yml'iga, mis kasutab ${VARIABLE} süntaksit
docker compose up -d
```

### Harjutus 5: Database Migrations

**Failid:**
- `05-database-migrations/liquibase/changelog-master.xml` - Master changelog
- `05-database-migrations/liquibase/changelogs/001-create-users-table.xml` - Users tabel
- `05-database-migrations/liquibase/changelogs/002-create-todos-table.xml` - Todos tabel

**Kirjeldus:**
- Database migration'id Liquibase'iga
- Loob users ja todos tabelid

**Kasutamine:**
```bash
cd compose-project
cp -r ../solutions/05-database-migrations/liquibase .

# Käivita koos Liquibase teenustega
docker compose up -d
```

### Harjutus 6: Production Patterns

**Failid:**
- `06-production-patterns/docker-compose.prod.yml` - Production overrides

**Kirjeldus:**
- Resource limits, logging, security
- Production-ready konfiguratsioonid

**Kasutamine:**
```bash
cd compose-project
cp ../solutions/06-production-patterns/docker-compose.prod.yml .

# Käivita production mode's
docker compose -f docker-compose-full.yml -f docker-compose.prod.yml up -d
```

### Harjutus 7: Advanced Patterns

**Failid:**
- `07-advanced-patterns/docker-compose.override.yml` - Override konfiguratsioon

**Kirjeldus:**
- Kasutab docker-compose.override.yml faili automaatseks override'iks
- Näitab advanced compose patterns'e

**Kasutamine:**
```bash
cd compose-project
cp ../solutions/07-advanced-patterns/docker-compose.override.yml .

# docker compose loeb automaatselt docker-compose.override.yml faili
docker compose up -d
```

## Märkused

- **TÄHTIS:** Need on näidislahendused. Proovi esmalt ise lahendada!
- Kõik failid kasutavad external volumes ja networks (Lab 1'st)
- Production failid kasutavad resource limits ja security seadistusi
- Iga harjutuse lahendus on organiseeritud eraldi kausta selguse huvides

## Vead ja Troubleshooting

Kui leiad vea lahenduses, vaata harjutuste troubleshooting sektsioone exercises kaustas.
