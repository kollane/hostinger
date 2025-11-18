# Laborite Arendamise Progress

**Viimane uuendus:** 2025-11-18
**Sessioon:** Lab struktuuri ülevaatus ja parandused

---

## ✅ VALMIS

### Lab 1: Docker Põhitõed
**Staatus:** ✅ 100% VALMIS

**Põhifookus:** Todo Service (Java Spring Boot)

**Tehtud muudatused:**
1. ✅ README.md - Todo Service arhitektuur ja eeldused
2. ✅ setup.sh - backend-java-spring kontroll
3. ✅ Harjutused (5/5):
   - ✅ 01-single-container.md - Java Spring Boot konteineriseerimine
   - ✅ 02-multi-container.md - Todo Service + PostgreSQL (port 5433)
   - ✅ 03-networking.md - todo-network
   - ✅ 04-volumes.md - postgres-todos-data
   - ✅ 05-optimization.md - Multi-stage Gradle build
4. ✅ Lahendused:
   - ✅ solutions/backend-java-spring/Dockerfile
   - ✅ solutions/backend-java-spring/Dockerfile.optimized
   - ✅ solutions/backend-java-spring/.dockerignore
   - ✅ solutions/README.md
   - ✅ Kustutatud: solutions/backend-nodejs/

**Tulemused:**
- Image: `todo-service:1.0`
- Port: 8081
- PostgreSQL: port 5433, todo_service_db
- User Service ja Frontend → Lab 2

---

## 🔄 POOLELI

### Lab 2: Docker Compose
**Staatus:** 📝 README.md uuendatud, harjutused vajavad kontrollimist

**Põhifookus:** KÕIK 3 teenust koos (Todo + User + Frontend)

**Tehtud:**
- ✅ README.md uuendatud:
  - Arhitektuur: Kõik 3 teenust
  - Eeldused: todo-service:1.0 Lab 1'st KOHUSTUSLIK
  - Setup script build'ib user-service + frontend
- ✅ setup.sh uuendatud:
  - Kontrollib todo-service:1.0
  - Build'ib automaatselt user-service + frontend

**JÄRGMISED SAMMUD:**
1. ⏳ Kontrolli Lab 2 harjutusi (exercises/):
   - 01-basic-compose.md
   - 02-full-stack.md
   - 03-dev-prod-envs.md
   - 04-dual-postgres.md
2. ⏳ Kontrolli Lab 2 lahendusi (solutions/)
3. ⏳ Veendu, et kõik 3 teenust on kaetud

---

## 📋 JÄRGMISED SAMMUD (PRIORITEEDIGA)

### 1. Lab 2: Docker Compose Harjutused
**Prioriteet:** KÕRGE

**Ülesanded:**
- [ ] Kontrolli 01-basic-compose.md - kas algab todo-service'ga?
- [ ] Kontrolli 02-full-stack.md - kas sisaldab kõiki 3 teenust?
- [ ] Kontrolli 03-dev-prod-envs.md - keskkondade seadistamine
- [ ] Kontrolli 04-dual-postgres.md - 2x PostgreSQL (users + todos)
- [ ] Kontrolli solutions/docker-compose.yml failid
- [ ] Veendu, et Lab 2 lõpuks on kõik 3 teenust töötavad

### 2. Lab 3: Kubernetes Alused
**Prioriteet:** KESKMINE

**Tehtud:**
- ✅ README.md uuendatud (kõik 3 teenust K8s'es)
- ✅ Eeldused: Lab 2 KOHUSTUSLIK
- ✅ setup.sh uuendatud (kõik 3 image'i)

**Järgmised:**
- [ ] Kontrolli harjutusi (5 harjutust)
- [ ] Kontrolli manifests/ kausta
- [ ] Veendu, et deploy'takse kõik 3 teenust

### 3. Lab 4-6
**Prioriteet:** MADAL

**Tehtud:**
- ✅ README.md failid uuendatud eelduste osas
- ✅ setup.sh failid uuendatud

**Järgmised:**
- [ ] Kontrolli Lab 4 harjutusi (Ingress, Helm, HPA)
- [ ] Kontrolli Lab 5 harjutusi (CI/CD)
- [ ] Kontrolli Lab 6 harjutusi (Monitoring)

### 4. Dokumentatsioon
- [ ] Kontrolli 00-LAB-RAAMISTIK.md
- [ ] Uuenda apps/README.md failid
- [ ] Uuenda labs/README.md

---

## 📊 Ülevaade: Laborite Struktuur

### Progressiivne õppetee:

```
┌─────────────────────────────────────────────┐
│  Lab 1: Docker Põhitõed                     │
│  ✅ VALMIS                                  │
│  Fookus: TODO SERVICE (Java Spring Boot)   │
│  Tulemus: todo-service:1.0                  │
└─────────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────────┐
│  Lab 2: Docker Compose                      │
│  📝 POOLELI (README valmis, harjutused?)    │
│  Fookus: KÕIK 3 TEENUST                     │
│  Lisab: user-service:1.0 + frontend:1.0     │
└─────────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────────┐
│  Lab 3: Kubernetes Alused                   │
│  📝 README valmis, harjutused?              │
│  Deploy: KÕIK 3 TEENUST K8s'es              │
└─────────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────────┐
│  Lab 4-6: Advanced Topics                   │
│  📝 README valmis, harjutused?              │
└─────────────────────────────────────────────┘
```

---

## 🎯 Peamised Muudatused (See Sessioon)

### 1. Laborite Fookuse Muutus
**Enne:**
- Lab 1: User Service (Node.js)
- Lab 2: ?
- Lab 3+: User Service + Frontend

**Pärast:**
- Lab 1: **Todo Service (Java)** ← PÕHIFOOKUS
- Lab 2: **Kõik 3 teenust** (Todo + User + Frontend)
- Lab 3+: **Kõik 3 teenust Kubernetes'es**

### 2. Standardiseeritud Eeldused
Kõik 6 labi saivad ühtse eelduste struktuuri:
- Eelnevad labid (KOHUSTUSLIK vs SOOVITUSLIK)
- Tööriistad + versioonid
- Teadmised
- Progressiivne õppetee diagramm

### 3. Automaatsed Setup Scriptid
Kõik 6 labi saivad setup.sh scriptid:
- Kontrollivad eeldusi
- Build'ivad puuduvad image'd automaatselt
- Laevad image'd Kubernetes'esse
- Intelligentsed (küsivad luba, pakuvad lahendusi)

---

## 📝 Märkmed Järgmiseks Sessiooniks

### Alusta Lab 2 harjutuste kontrollimisest:
```bash
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/exercises
ls -la *.md
```

### Kontrollimise checklist:
1. Kas harjutus algab todo-service'ga? (Lab 1 tulemus)
2. Kas lisatakse user-service ja frontend?
3. Kas lõpuks töötavad kõik 3 teenust?
4. Kas portid on õiged:
   - todo-service: 8081
   - user-service: 3000
   - frontend: 8080
   - postgres-todos: 5433
   - postgres-users: 5432
5. Kas docker-compose.yml näidised on õiged?

### Võimalikud probleemid:
- Lab 2 harjutused võivad viidata ainult user-service'le
- docker-compose.yml failid võivad olla poolikud
- Dual PostgreSQL seadistus võib vajada täpsustamist

---

## 🔗 Kasulikud Lingid

**Asukoht:**
- Laborid: `/home/janek/projects/hostinger/labs/`
- Rakendused: `/home/janek/projects/hostinger/labs/apps/`

**Dokumentatsioon:**
- CLAUDE.md (parent): `/home/janek/projects/hostinger/CLAUDE.md`
- CLAUDE.md (labs): `/home/janek/projects/hostinger/labs/CLAUDE.md`
- 00-LAB-RAAMISTIK.md: `/home/janek/projects/hostinger/labs/00-LAB-RAAMISTIK.md`

**Progress:**
- See fail: `/home/janek/projects/hostinger/labs/PROGRESS.md`

---

**Järgmine samm:** Kontrolli Lab 2 harjutusi ja lahendusi (exercises/ ja solutions/)
