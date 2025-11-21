# Labor 2: Docker Compose - Lahendused

See kaust sisaldab näidislahendusi kõigile Labor 2 harjutustele.

## Failid

### Harjutus 1: Docker Compose Alused
- **docker-compose.yml** - 4 teenust (2x PostgreSQL, user-service, todo-service)
- Konverteerib Lab 1 lõpuseisu docker-compose.yml failiks
- Kasutab external volumes ja networks

### Harjutus 2: Lisa Frontend
- **docker-compose-full.yml** - 5 teenust (+ frontend)
- Lisab Nginx frontend teenuse
- Mount'ib staatilised failid

### Harjutus 3: Environment Management
- **.env.example** - Environment variables template
- Näitab, kuidas hallata salajaseid turvaliselt

### Harjutus 4: Database Migrations
- **liquibase/changelog-master.xml** - Master changelog
- **liquibase/changelogs/001-create-users-table.xml** - Users tabel
- **liquibase/changelogs/002-create-todos-table.xml** - Todos tabel

### Harjutus 5: Production Patterns
- **docker-compose.prod.yml** - Production overrides
- Resource limits, logging, security

## Kasutamine

### Harjutus 1 Lahendus

```bash
# Kopeeri fail töökataloogiacd compose-project
cp ../solutions/docker-compose.yml .

# Käivita
docker compose up -d
```

### Harjutus 2 Lahendus

```bash
# Kopeeri fail
cp ../solutions/docker-compose-full.yml .

# Käivita
docker compose -f docker-compose-full.yml up -d
```

### Harjutus 3 Lahendus

```bash
# Kopeeri .env template
cp ../solutions/.env.example .env

# Muuda salajaseid
vim .env

# Käivita docker-compose.yml'iga, mis kasutab ${VARIABLE} süntaksit
docker compose up -d
```

### Harjutus 4 Lahendus

```bash
# Kopeeri Liquibase failid
cp -r ../solutions/liquibase .

# Käivita koos Liquibase teenustega
docker compose up -d
```

### Harjutus 5 Lahendus

```bash
# Kopeeri production override
cp ../solutions/docker-compose.prod.yml .

# Käivita production mode's
docker compose -f docker-compose-full.yml -f docker-compose.prod.yml up -d
```

## Märkused

- **TÄHTIS:** Need on näidislahendused. Proovi esmalt ise lahendada!
- Kõik failid kasutavad external volumes ja networks (Lab 1'st)
- Production failid kasutavad resource limits ja security seadistusi
- Liquibase changelog failid loovad users ja todos tabelid

## Vead ja Troubleshooting

Kui leiad vea lahenduses, vaata harjutuste troubleshooting sektsioone.
