# Harjutus 4: Database Migrations Liquibase'iga

**Kestus:** 60 minutit
**Eesmärk:** Automatiseeri database schema haldamist Liquibase migration'itega

---

## 📋 Ülevaade

Selles harjutuses õpid automatiseerima database schema loomist ja uuendamist Liquibase'iga. See on **oluline DevOps skill** ja valmistab ette **Kubernetes InitContainer pattern'i**, mida õpid Lab 3's.

**Probleem praegu:**
- ❌ Database schema luuakse manuaalselt (database-setup.sql)
- ❌ Raske jälgida schema muudatusi
- ❌ Rollback on keeruline
- ❌ Ei ole versioonihaldust database schema'le

**Lahendus:**
- ✅ Liquibase migration'id (versioonihaldus)
- ✅ Automaatne schema loomine
- ✅ Init container pattern (käivitub enne rakendust)
- ✅ Rollback võimalus

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista, mis on database migration
- ✅ Seadistada Liquibase konteinerit
- ✅ Kirjutada changelog faile (XML/YAML)
- ✅ Implementeerida init container pattern
- ✅ Käivitada migration'eid enne rakendust
- ✅ Teha rollback'e
- ✅ Valmistuda Kubernetes Job/InitContainer'iteks (Lab 3)

---

## 🧠 Mis on Database Migration?

### Traditsiooniline Lähenemine (Halb):

```sql
-- database-setup.sql
CREATE TABLE users (...);
INSERT INTO users VALUES (...);
```

**Probleemid:**
- Kui tabel on juba olemas, saad vea (error)
- Pole ajalugu, mis muutus ja millal
- Raske teha rollback'i
- Pole versioonihaldust

### Database Migration Lähenemine (Hea):

```
Version 1: Create users table
Version 2: Add email column
Version 3: Add index on email
Version 4: Create todos table
...
```

**Eelised:**
- ✅ Iga muudatus on versioonihalduses
- ✅ Automaatne rollback
- ✅ Saad käivitada mitu korda (idempotent)
- ✅ Database ja kood on sünkroonis

---

## 🏗️ Liquibase Init Container Pattern

### Praegu (Ilma Liquibase'ita):

```
Backend konteiner käivitub
  → Proovib ühenduda andmebaasiga
  → Eeldab, et tabelid on olemas
  → Kui tabeleid pole, crashib
```

### Peale (Liquibase'iga):

```
1. PostgreSQL konteiner käivitub
2. Liquibase konteiner käivitub (init)
     → Loob/uuendab tabeleid
     → Käivitab migration'id
     → Lõpetab (exit 0)
3. Backend konteiner käivitub
     → Tabelid on juba olemas
     → Rakendus töötab
```

**See on täpselt sama pattern, mida kasutad Kubernetes'es Lab 3's!**

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Harjutus 3 on läbitud:**

```bash
# 1. Kas 5 teenust (services) töötavad?
cd compose-project
docker compose ps

# 2. Kas .env fail on olemas?
ls -la .env
```

**Kui midagi puudub:**
- 🔗 Mine tagasi [Harjutus 3](03-environment-management.md)

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📝 Sammud

### Samm 1: Loo Liquibase Changelog Kataloog (5 min)

Loo kataloog Liquibase migration failide jaoks:

```bash
cd compose-project
mkdir -p liquibase/changelogs
cd liquibase
```

---

### Samm 2: Kirjuta Master Changelog Fail (5 min)

Loo `changelog-master.xml`:

```bash
vim changelog-master.xml
```

Lisa:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

    <!-- Include all changesets -->
    <include file="changelogs/001-create-users-table.xml" relativeToChangelogFile="true"/>
    <include file="changelogs/002-create-todos-table.xml" relativeToChangelogFile="true"/>

</databaseChangeLog>
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 3: Kirjuta Changesets (15 min)

#### Changeset 1: Loo users tabel

```bash
vim changelogs/001-create-users-table.xml
```

Lisa:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

    <changeSet id="001-create-users-table" author="devops-training">
        <comment>Create users table for User Service</comment>

        <createTable tableName="users">
            <column name="id" type="BIGSERIAL" autoIncrement="true">
                <constraints primaryKey="true" nullable="false"/>
            </column>
            <column name="name" type="VARCHAR(100)">
                <constraints nullable="false"/>
            </column>
            <column name="email" type="VARCHAR(255)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="password" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="role" type="VARCHAR(20)" defaultValue="user">
                <constraints nullable="false"/>
            </column>
            <column name="created_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="updated_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <createIndex indexName="idx_users_email" tableName="users">
            <column name="email"/>
        </createIndex>

        <createIndex indexName="idx_users_role" tableName="users">
            <column name="role"/>
        </createIndex>

        <rollback>
            <dropTable tableName="users"/>
        </rollback>
    </changeSet>

</databaseChangeLog>
```

Salvesta.

#### Changeset 2: Loo todos tabel

```bash
vim changelogs/002-create-todos-table.xml
```

Lisa:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

    <changeSet id="002-create-todos-table" author="devops-training">
        <comment>Create todos table for Todo Service</comment>

        <createTable tableName="todos">
            <column name="id" type="BIGSERIAL" autoIncrement="true">
                <constraints primaryKey="true" nullable="false"/>
            </column>
            <column name="user_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="title" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="description" type="TEXT"/>
            <column name="completed" type="BOOLEAN" defaultValueBoolean="false"/>
            <column name="priority" type="VARCHAR(20)" defaultValue="medium"/>
            <column name="due_date" type="TIMESTAMP"/>
            <column name="created_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="updated_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <createIndex indexName="idx_todos_user_id" tableName="todos">
            <column name="user_id"/>
        </createIndex>

        <createIndex indexName="idx_todos_completed" tableName="todos">
            <column name="completed"/>
        </createIndex>

        <rollback>
            <dropTable tableName="todos"/>
        </rollback>
    </changeSet>

</databaseChangeLog>
```

Salvesta.

**Kontrolli failistruktuur:**

```bash
tree liquibase/

# Peaks nägema:
# liquibase/
# ├── changelog-master.xml
# └── changelogs/
#     ├── 001-create-users-table.xml
#     └── 002-create-todos-table.xml
```

---

### Samm 4: Lisa Liquibase Teenused docker-compose.yml'i (20 min)

Mine tagasi compose-project kausta:

```bash
cd ..
vim docker-compose.yml
```

Lisa **kaks Liquibase teenust (service)** (peale PostgreSQL teenuste, enne backend'e):

```yaml
  # ==========================================================================
  # Liquibase - User Service Database Migrations
  # ==========================================================================
  liquibase-user:
    image: liquibase/liquibase:4.20-alpine
    container_name: liquibase-user
    volumes:
      - ./liquibase:/liquibase/changelog
    environment:
      LIQUIBASE_COMMAND_URL: jdbc:postgresql://postgres-user:5432/${USER_DB_NAME}
      LIQUIBASE_COMMAND_USERNAME: ${POSTGRES_USER}
      LIQUIBASE_COMMAND_PASSWORD: ${POSTGRES_PASSWORD}
      LIQUIBASE_COMMAND_CHANGELOG_FILE: changelog-master.xml
    command: --changeLogFile=changelog-master.xml update
    networks:
      - todo-network
    depends_on:
      postgres-user:
        condition: service_healthy
    restart: "no"  # Käivitub ainult üks kord

  # ==========================================================================
  # Liquibase - Todo Service Database Migrations
  # ==========================================================================
  liquibase-todo:
    image: liquibase/liquibase:4.20-alpine
    container_name: liquibase-todo
    volumes:
      - ./liquibase:/liquibase/changelog
    environment:
      LIQUIBASE_COMMAND_URL: jdbc:postgresql://postgres-todo:5432/${TODO_DB_NAME}
      LIQUIBASE_COMMAND_USERNAME: ${POSTGRES_USER}
      LIQUIBASE_COMMAND_PASSWORD: ${POSTGRES_PASSWORD}
      LIQUIBASE_COMMAND_CHANGELOG_FILE: changelog-master.xml
    command: --changeLogFile=changelog-master.xml update
    networks:
      - todo-network
    depends_on:
      postgres-todo:
        condition: service_healthy
    restart: "no"  # Käivitub ainult üks kord
```

**TÄHTIS:** Nüüd muuda backend teenused (services) sõltuma Liquibase'ist:

```yaml
  user-service:
    # ... eelnevad seadistused
    depends_on:
      postgres-user:
        condition: service_healthy
      liquibase-user:  # UUS: oota Liquibase'i
        condition: service_completed_successfully

  todo-service:
    # ... eelnevad seadistused
    depends_on:
      postgres-todo:
        condition: service_healthy
      liquibase-todo:  # UUS: oota Liquibase'i
        condition: service_completed_successfully
```

Salvesta.

---

### Samm 5: Kustuta Vanad Andmebaasid ja Testi (10 min)

**Kustuta vanad andmehoidlad (volumes), et testida Liquibase'i:**

```bash
# HOIATUS: See kustutab kõik andmed!
docker compose down

# Kustuta vanad volumes
docker volume rm postgres-user-data postgres-todo-data

# Loo uued tühjad volumes
docker volume create postgres-user-data
docker volume create postgres-todo-data

# Käivita stack Liquibase'iga
docker compose up -d

# Vaata Liquibase logisid
docker compose logs liquibase-user
docker compose logs liquibase-todo

# Peaks nägema:
# liquibase-user  | Liquibase command 'update' was executed successfully.
# liquibase-todo  | Liquibase command 'update' was executed successfully.
```

**Kontrolli, et tabelid loodi:**

```bash
# Kontrolli users tabelit
docker compose exec postgres-user psql -U postgres -d user_service_db -c "\dt"

# Peaks nägema:
#  databasechangelog      | table
#  databasechangeloglock  | table
#  users                  | table

# Kontrolli todos tabelit
docker compose exec postgres-todo psql -U postgres -d todo_service_db -c "\dt"

# Peaks nägema:
#  databasechangelog      | table
#  databasechangeloglock  | table
#  todos                  | table
```

**MÄRKUS:** `databasechangelog` ja `databasechangeloglock` on Liquibase'i enda tabelid, kus jälgitakse migration'eid.

---

### Samm 6: Testi End-to-End (5 min)

```bash
# Kontrolli, et kõik teenused (services) töötavad
docker compose ps

# Backend'id peaksid olema UP (Liquibase EXIT 0)
# NAME              STATUS
# liquibase-user    Exited (0)
# liquibase-todo    Exited (0)
# user-service      Up (healthy)
# todo-service      Up (healthy)

# Testi API'd
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Liquibase Test","email":"liquibase@test.com","password":"test123"}'

# Peaks töötama! Tabelid on Liquibase'i poolt loodud!
```

---

### Samm 7: Lisa Uus Migration (Bonus) (10 min)

Simuleerime schema muudatust:

```bash
cd liquibase
vim changelogs/003-add-user-phone.xml
```

Lisa:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

    <changeSet id="003-add-user-phone" author="devops-training">
        <comment>Add phone column to users table</comment>

        <addColumn tableName="users">
            <column name="phone" type="VARCHAR(20)"/>
        </addColumn>

        <rollback>
            <dropColumn tableName="users" columnName="phone"/>
        </rollback>
    </changeSet>

</databaseChangeLog>
```

Salvesta.

**Uuenda master changelog:**

```bash
cd ..
vim changelog-master.xml
```

Lisa kolmas include:

```xml
<include file="changelogs/003-add-user-phone.xml" relativeToChangelogFile="true"/>
```

**Käivita migration:**

```bash
cd ..
docker compose up liquibase-user

# Peaks nägema:
# liquibase-user  | Running Changeset: changelogs/003-add-user-phone.xml::003-add-user-phone::devops-training

# Kontrolli, et veerg on lisatud
docker compose exec postgres-user psql -U postgres -d user_service_db -c "\d users"

# Peaks nägema "phone" veergu
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **liquibase/** kataloog changelog failidega
- [ ] **changelog-master.xml** master fail
- [ ] **2 changeset'i** (users, todos tabelid)
- [ ] **Liquibase teenused** docker-compose.yml's
- [ ] **Init container pattern** - backend sõltub Liquibase'ist
- [ ] **Tabelid loodud** Liquibase'i poolt
- [ ] **Migration history** databasechangelog tabelis
- [ ] **End-to-End workflow** toimib

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas Liquibase teenused exitisid edukalt?
docker compose ps | grep liquibase
# Peaks nägema: Exited (0)

# 2. Kas tabelid on loodud?
docker compose exec postgres-user psql -U postgres -d user_service_db -c "\dt"
# Peaks nägema: users, databasechangelog, databasechangeloglock

# 3. Kas migration history on olemas?
docker compose exec postgres-user psql -U postgres -d user_service_db -c "SELECT * FROM databasechangelog;"
# Peaks nägema 2-3 rida (changesets)
```

---

## 🎓 Õpitud Mõisted

### Liquibase Mõisted:

- **changeSet:** Üks muudatus andmebaasis (DDL)
- **changelog:** Fail, mis sisaldab changesets'e
- **master changelog:** Fail, mis include'ib kõik changesets
- **rollback:** Tagasivõtmine (undo changeset)
- **databasechangelog:** Liquibase'i tabel migration history jaoks

### Init Container Pattern:

```
1. PostgreSQL konteiner käivitub (healthy)
2. Liquibase konteiner käivitub ja lõpetab (exit 0)
3. Backend konteiner käivitub (depends_on Liquibase)
```

**Kubernetes'es Lab 3:**
- Liquibase = InitContainer
- Backend = Main Container

### Changesets Best Practices:

1. **Üksi muudatus per changeset** - Lihtne rollback
2. **Nunber changesets järjekorras** - 001, 002, 003...
3. **Kirjelda kommentaarides** - Mis muutus tehti
4. **Määra author** - Kes tegi
5. **Kirjuta rollback** - Kuidas tagasi võtta

---

## 💡 Parimad Tavad

1. **Ära muuda vanu changesets'e** - Loo alati uus
2. **Versioonihälda changelog'e** - Git commit iga muudatuse kohta
3. **Testi rollback'e** - Veendu, et rollback töötab
4. **Kasuta descriptive ID-sid** - 001-create-users-table
5. **Lisa kommentaare** - Selgita, miks muudatus tehti

### Rollback Testimine:

```bash
# Vaata, mis changesets on rakendatud
docker compose exec liquibase-user liquibase --changeLogFile=changelog-master.xml history

# Rollback viimane changeset
docker compose exec liquibase-user liquibase --changeLogFile=changelog-master.xml rollbackCount 1

# Kontrolli
docker compose exec postgres-user psql -U postgres -d user_service_db -c "\d users"
# "phone" veerg peaks olema eemaldatud
```

---

## 🐛 Levinud Probleemid

### Probleem 1: "Liquibase cannot connect to database"

```bash
# Kontrolli, et PostgreSQL on healthy
docker compose ps postgres-user

# Kontrolli connection string'i
docker compose exec liquibase-user env | grep LIQUIBASE

# Peaks olema:
# LIQUIBASE_COMMAND_URL=jdbc:postgresql://postgres-user:5432/user_service_db
```

### Probleem 2: "Changeset already exists"

```bash
# Liquibase jälgib juba rakendatud changesets'e
# Kui proovid sama ID-ga changeset'i uuesti, saad vea

# Lahendus: Muuda changeset ID
# VÕI kustuta databasechangelog tabel ja alusta otsast
docker compose exec postgres-user psql -U postgres -d user_service_db -c "TRUNCATE databasechangelog;"
```

### Probleem 3: "Backend starts before Liquibase"

```bash
# Kontrolli depends_on
vim docker-compose.yml

# user-service peab sõltuma:
depends_on:
  liquibase-user:
    condition: service_completed_successfully  # Oluline!
```

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd automatiseerid database schema Liquibase'iga.

**Mis edasi?**
- ✅ Database migration'id töötavad
- ✅ Init container pattern implementeeritud
- ✅ Valmis Kubernetes InitContainer'iteks (Lab 3)
- ⏭️ **Järgmine:** Production Patterns

**Jätka:** [Harjutus 5: Production Patterns](05-production-patterns.md)

---

## 📚 Viited

- [Liquibase dokumentatsioon](https://docs.liquibase.com/)
- [Liquibase Docker Hub](https://hub.docker.com/r/liquibase/liquibase)
- [Liquibase changesets](https://docs.liquibase.com/concepts/changelogs/changeset.html)
- [Init containers (Kubernetes)](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

---

**Õnnitleme! Oled õppinud database migration'eid! 🎉**
