# Legacy → Kubernetes: Migration Roadmap

**Eesmärk:** Ülevaade, **millises järjekorras** liikuda legacy Tomcat/Gradle lahenduselt Kubernetes'ele.

**Sihtrühm:**
- Legacy stack: Tomcat 9/10 + Java 17 + Gradle
- Mitme keskkonda: dev, test, prod (eraldiseisvad hostid)
- Andmebaasid: Eraldi serverites (PostgreSQL/Oracle)
- Veebiserver: Reverse proxy (Nginx/Apache) eraldi hostis

**Põhimõte:** Samm-sammuline migratsioon ilma kõike korraga muutmata. Iga etapp annab väärtust ja õppimist.

---

## 📋 Roadmap Ülevaade (5 Etappi)

| Etapp | Eesmärk | Aeg | Tulemus |
|-------|---------|-----|---------|
| **1. Ettevalmistus** | Audit, prioriteedid, õppimine | 1-2 kuud | Migratsiooniplaan |
| **2. Konteinerise** | Rakendused Docker'isse | 3-6 kuud | Docker images |
| **3. Orkestreerimise** | Docker Compose (kohalik) | 2-3 kuud | Kohalik testimine |
| **4. Kubernetes** | K8s cluster, deploy | 3-6 kuud | Production K8s |
| **5. Hardening** | Monitoring, CI/CD, security | 3-6 kuud | Stable production |

**Kokku:** 12-23 kuud (sõltuvalt rakenduste arvust ja meeskonna kogemusest)

---

## Etapp 1: Ettevalmistus (1-2 kuud)

### 1.1. Inventory ja Audit

**Mis tuleb teha:**
1. **Loenda kõik rakendused:**
   - Mitu rakendust on? (näit. 5, 10, 20?)
   - Milliseid versioone kasutavad? (Tomcat 9/10, Java 17/11/8)
   - Millised andmebaasid? (PostgreSQL, Oracle, MySQL)

2. **Grupeeri rakendused:**
   - **Lihtsamad:** Spring Boot (embedded Tomcat), PostgreSQL, aktiivsed
   - **Keerukamad:** Traditional WAR, Oracle, shared libraries, legacy framework'id

3. **Dokumenteeri sõltuvused:**
   - Andmebaas (kas shared või dedicated?)
   - Välised API'd (REST, SOAP)
   - Failisüsteem (kas kirjutab logisid/cache'i kuhugi?)
   - Konfiguratsioon (properties failid, JNDI, keskkonna muutujad)

**Tulemus:**
- Excel/CSV tabel: rakendus, runtime, DB, kriitilisus, keerukus
- Prioriteedid: millised rakendused migreerida esimesena

---

### 1.2. Vali Pilootprojekt (2 rakendust)

**Kriteeriumid:**
- ✅ **Lihtne:** Spring Boot (embedded Tomcat), PostgreSQL
- ✅ **Aktiivne:** Arendus käib, saad kiiresti testida
- ✅ **Madal kriitilisus:** Võib testfaasis olla tunde maas
- ❌ **Väldi:** Oracle, keeruline XML config, shared JARs, kriitilised süsteemid

**Näide:**
- App 1: Internal admin dashboard (Spring Boot 2.7, PostgreSQL)
- App 2: Reporting service (Spring Boot 3.0, PostgreSQL)

---

### 1.3. Õppimine ja Tooling

**Meeskond:**
- **Docker:** 2-3 päeva koolitus (Docker, Dockerfile, Compose)
- **Kubernetes:** 5-7 päeva koolitus (Pods, Deployments, Services, Ingress)

**Tööriistad (paigalda):**
- **Arendajad:** Docker Desktop
- **Lokaalne K8s:** Minikube või K3s (testimiseks)
- **kubectl, Helm** (K8s package manager)

**Tulemus:** Meeskond saab aru Docker ja K8s põhitõdedest

---

## Etapp 2: Konteinerise (3-6 kuud)

### 2.1. Pilootprojekt (2 rakendust, 1-2 kuud)

**Sammud:**

1. **Kirjuta Dockerfile:**
   - Kasuta multi-stage build'i (build + runtime stage)
   - Gradle dependencies cache (kiire rebuild)
   - Base image: `eclipse-temurin:17-jre-alpine` (väike, kiire)

2. **Testi lokaalselt:**
   - `docker build -t myapp:1.0 .`
   - `docker run -p 8080:8080 -e DATABASE_URL=... myapp:1.0`
   - Verifitseeri: rakendus käivitub, connects DB'sse, API töötab

3. **Dokumenteeri:**
   - README: kuidas ehitada, käivitada
   - Envars: millised keskkonnamuutujad on vajalikud
   - Probleemid: mida õppisid, mis läks valesti

**Tulemus:**
- 2 Docker image'it valmis
- Käivituvad lokaalselt (Docker Desktop)
- Meeskond teab, kuidas Docker töötab

---

### 2.2. Konverteeri Ülejäänud Rakendused (2-4 kuud)

**Strateegia:**
- Tee 2-3 rakendust korraga (paralleelselt)
- Kasuta pilootprojektist õpitut (template Dockerfile)
- Iga rakendus: Dockerfile + README + lokaalne test

**Jaga meeskond:**
- Arendajad: Konverteeri oma rakendused
- DevOps: Aitab troubleshooting'ul ja best practices

**Tulemus:** Kõik rakendused Docker image'ites

---

## Etapp 3: Orkestreerimise - Docker Compose (2-3 kuud)

### 3.1. Lokaalne Testimine

**Eesmärk:** Harjuta multi-container orchestration ilma K8s complexity'ta.

**Mis tuleb teha:**
1. **Loo docker-compose.yml:**
   ```yaml
   services:
     myapp:
       image: myapp:1.0
       environment:
         DATABASE_URL: postgresql://db:5432/mydb
       depends_on:
         - db
     db:
       image: postgres:15
       volumes:
         - db-data:/var/lib/postgresql/data
   ```

2. **Testi kohalikult:**
   - `docker-compose up -d` (start)
   - `docker-compose logs -f` (monitor)
   - `docker-compose down` (cleanup)

3. **Multi-environment pattern:**
   - `docker-compose.yml` (base)
   - `docker-compose.dev.yml` (development overrides)
   - `docker-compose.prod.yml` (production overrides)

**Tulemus:**
- Arendajad saavad terve stack'i käivitada lokaalselt
- Õppinud, kuidas services suhtlevad (networking, dependencies)

---

### 3.2. Testimiskeskkonnas Deploy (valikuline)

**Kui soovite testida serveris:**
- Paigalda Docker Engine testserverisse
- Kopeeri docker-compose.yml + images
- `docker-compose up -d`

**Märkus:** See on **MITTE production!** Ainult testimiseks ja harjutamiseks.

---

## Etapp 4: Kubernetes (3-6 kuud)

### 4.1. Vali Kubernetes Platform (1-2 nädalat)

**Valikud:**

| Platform | Sobib kui... | Keerukus | Hind |
|----------|--------------|----------|------|
| **AWS EKS** | Kasutate juba AWS'i | Keskmine | $$$ |
| **Azure AKS** | Kasutate juba Azure'i | Keskmine | $$$ |
| **GKE (Google)** | Tahate kõige managed K8s | Madal | $$$ |
| **Self-hosted (K3s/kubeadm)** | On-premise, täielik kontroll | Kõrge | $ |

**Soovitus esmakordsetele:** Managed Kubernetes (EKS/AKS/GKE) - vähem operatsioonilist koormust.

---

### 4.2. Loo Kubernetes Cluster (1-2 nädalat)

**Sammud:**
1. **Provision cluster:**
   - Managed: AWS/Azure/GCP console või Terraform
   - Self-hosted: Paigalda K3s või kubeadm

2. **Baaskonfiguratsioon:**
   - Ingress controller (Nginx Ingress)
   - Load balancer (AWS ELB või MetalLB)
   - StorageClass (persistent volumes DB jaoks)

3. **Access setup:**
   - Kubectl config (kubeconfig fail)
   - RBAC (role-based access control)

**Tulemus:** Töötav K8s cluster, kuhu saad deploy'da

---

### 4.3. Pilootprojekt Kubernetes'es (2-3 kuud)

**Sammud:**

1. **Kirjuta Kubernetes manifests:**
   - Deployment (rakendus + replicas)
   - Service (internal networking)
   - ConfigMap (konfiguratsioon)
   - Secret (paroolid)
   - Ingress (external access)

2. **Deploy pilootprojekt (2 rakendust):**
   ```bash
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   kubectl apply -f ingress.yaml
   ```

3. **Testi:**
   - Rakendus käivitub?
   - Saab andmebaasiga ühendust?
   - External access töötab (Ingress)?
   - Logs/metrics nähtavad?

4. **Iterate:**
   - Paranda probleeme (resource limits, health checks, DB connection)
   - Dokumenteeri õppetunnid

**Tulemus:**
- 2 rakendust töötavad Kubernetes'es (dev või test namespace)
- Meeskond teab, kuidas K8s töötab

---

### 4.4. Migreeri Kõik Rakendused (2-3 kuud)

**Strateegia:**
- Tee 3-5 rakendust korraga
- Kasuta pilootprojektist template'e
- Iga rakendus: Kubernetes manifests + deploy + test

**Näpunäited:**
- Kasuta Helm charts (templating - kergemini hallata)
- Grupeeri rakendused namespace'ide kaupa (project1-ns, project2-ns)
- Andmebaasid: Algselt jäta legacy DB serverid (ära koli kohe K8s'i!)

**Tulemus:** Kõik rakendused Kubernetes'es

---

## Etapp 5: Production Hardening (3-6 kuud)

### 5.1. Monitoring & Logging

**Paigalda:**
- **Prometheus + Grafana:** Metrics (CPU, memory, request rate)
- **Loki või ELK:** Centralized logging
- **Alerting:** Email/Slack alerts (Prometheus AlertManager)

**Tulemus:** Näed, mis süsteemis toimub real-time

---

### 5.2. CI/CD Pipeline

**Automaatne pipeline:**
1. **Build:**
   - Git push → CI build (Bamboo, GitHub Actions, GitLab CI)
   - Gradle build → Docker image
   - Push image → Docker registry

2. **Deploy:**
   - Dev: automaatne deploy (iga commit)
   - Test: automaatne deploy (iga merge to main)
   - Prod: manual approval + deploy

**Tööriistad:**
- Bamboo (juba kasutusel)
- ArgoCD (GitOps - sync Git → K8s)
- Helm (package management)

---

### 5.3. Security & Secrets

**Paigalda:**
- **Secrets management:** HashiCorp Vault või K8s Sealed Secrets
- **RBAC:** Role-based access (developers, admins)
- **Network Policies:** Isolate namespaces (myapp ei saa access teiste app'ide DB'le)
- **Image scanning:** Trivy või Docker Scout (CVE scan)

---

### 5.4. Backup & Disaster Recovery

**Paigalda:**
- **Velero:** Kubernetes backup (manifests + persistent volumes)
- **Scheduled backups:** Daily/weekly
- **DR test:** Simulate failure → restore → verify

**Tulemus:** Süsteemid on turvalised ja restorable

---

## Etapp 6: Andmebaasid (Valikuline, hiljem)

**Märkus:** Algselt jäta **legacy DB serverid** samaks (PostgreSQL/Oracle eraldi hostides). Rakendused konteinerid → K8s, aga DB jääb väljapoole.

**Hiljem (kui süsteemid on stabiilsed):**
- Koli PostgreSQL → Kubernetes StatefulSets või managed DB (AWS RDS/Azure Database)
- Oracle: kaaluda cloud managed variant (AWS RDS Oracle, Azure SQL)

**Põhjus:** Andmebaasid on **kõige kriitilisemad**. Alusta rakenduste migratsiooniga, DB koli alles pärast stabiilsust.

---

## 📊 Kokkuvõte: Järjekord ja Prioriteedid

### Järjekord (ei vaheta!)

```
1. Audit + Planeerimine → 2. Docker (piloot 2 apps) → 3. Docker (kõik apps) →
4. Docker Compose (lokaalne test) → 5. K8s Cluster → 6. K8s (piloot 2 apps) →
7. K8s (kõik apps) → 8. Monitoring + CI/CD → 9. Security + Backup
```

### Etappide Sõltuvused

| Etapp | Sõltub Etapist | Saab Alustada Ilma Eelmiseta? |
|-------|----------------|-------------------------------|
| **1. Ettevalmistus** | - | ✅ Jah |
| **2. Docker (piloot)** | 1 | ✅ Jah (aga audit aitab!) |
| **3. Docker (kõik)** | 2 | ❌ Ei (õpid piloodist!) |
| **4. Docker Compose** | 3 | ✅ Valikuline (lokaalne test) |
| **5. K8s Cluster** | - | ✅ Jah (paralleelselt Docker'iga) |
| **6. K8s Deploy (piloot)** | 3, 5 | ❌ Ei (vajad Docker images + cluster) |
| **7. K8s Deploy (kõik)** | 6 | ❌ Ei (õpid piloodist!) |
| **8. Monitoring** | 7 | ❌ Ei (vajab töötavat K8s'i) |
| **9. Security** | 7 | ❌ Ei (vajab töötavat K8s'i) |

---

## ⚠️ Levinud Vead (Mida MITTE Teha)

### ❌ Viga 1: Kõik korraga
**Vale:** "Migreerime 20 rakendust Kubernetes'ele järgmine kuu!"
**Õige:** Alusta 2 rakendusega, õpi, siis järgmised.

### ❌ Viga 2: Vahele jätta Docker etapi
**Vale:** "Lähme otse legacy → Kubernetes!"
**Õige:** Legacy → Docker → Kubernetes (Docker õpetab containerization'i!)

### ❌ Viga 3: Unustada testimine
**Vale:** Deploy production'i ilma testimata
**Õige:** Test lokaalselt (Docker Desktop), siis dev K8s, siis test K8s, siis prod K8s

### ❌ Viga 4: Andmebaasid korraga
**Vale:** Koli rakendused JA andmebaasid korraga K8s'i
**Õige:** Rakendused esmalt, DB koli hiljem (pärast stabiilsust)

### ❌ Viga 5: Monitoring hiljem
**Vale:** "Lisame monitoring'u pärast production launch'i"
**Õige:** Prometheus + Grafana on ESIMESED asjad, mida K8s'i paigaldad

---

## 🎯 Edu Kriteeriumid (Iga Etapp)

### Etapp 2 (Docker): ✅ Valmis kui...
- [ ] Kõik rakendused on Docker image'ites
- [ ] Käivituvad lokaalselt (`docker run`)
- [ ] Dockerfile'id on dokumenteeritud
- [ ] Meeskond teab, kuidas Docker töötab

### Etapp 4 (Kubernetes): ✅ Valmis kui...
- [ ] Kõik rakendused töötavad K8s'es
- [ ] Zero-downtime deployments (rolling updates)
- [ ] External access töötab (Ingress)
- [ ] Logs on nähtavad (`kubectl logs`)

### Etapp 5 (Hardening): ✅ Valmis kui...
- [ ] Prometheus + Grafana töötavad
- [ ] CI/CD pipeline automaatne (Git push → Deploy)
- [ ] Secrets on turvalised (Vault/Sealed Secrets)
- [ ] Backup tehtud ja testitud

---

## 📚 Ressursid ja Koolitusmaterjalid

### Käesoleva Repositooriumi Labs

| Lab | Teema | Aeg | Kirjeldus |
|-----|-------|-----|-----------|
| **Lab 1** | Docker Basics | 4h | Dockerfile, multi-stage builds, images |
| **Lab 2** | Docker Compose | 5h | Multi-container, environments |
| **Lab 3** | Kubernetes Basics | 5h | Pods, Deployments, Services |
| **Lab 4** | K8s Advanced | 5h | Ingress, HPA, Helm |
| **Lab 5** | CI/CD | 4h | Automated pipeline |
| **Lab 6** | Monitoring | 4h | Prometheus, Grafana, Loki |
| **Lab 7** | Security | 5h | Vault, RBAC, Network Policies |
| **Lab 8** | GitOps | 5h | ArgoCD |
| **Lab 9** | Backup | 5h | Velero |
| **Lab 10** | Terraform | 5h | Infrastructure as Code |

**Soovitatav järjekord:** Lab 1 → Lab 2 → Lab 3 → Lab 4 → ...

### Theory Chapters (resource/)

| Peatükk | Teema | Kirjeldus |
|---------|-------|-----------|
| **05** | Docker Põhimõtted | Docker architecture, images vs containers |
| **06** | Dockerfile Detailid | Multi-stage builds, layer caching, best practices |
| **06A** | Java/Spring Boot Spetsiifika | Gradle dependencies, JVM tuning, WAR vs JAR |
| **08A** | Production vs Dev Seadistused | Environment-specific configs, secrets |
| **08B** | Nginx Reverse Proxy | API gateway patterns, CORS |

---

## 💡 Lõppsõnad

### Kõige Olulisem Õppetund

**"Migration ei ole race - see on marathon."**

- ✅ Alusta väikesest (2 rakendust)
- ✅ Õpi igast etapist
- ✅ Dokumenteeri (README, troubleshooting)
- ✅ Jaga teadmisi meeskonnas
- ❌ Ära kiirusta
- ❌ Ära jäta etappe vahele

### Realistic Timeline

- **Väike meeskond (1-2 DevOps):** 18-24 kuud (kõik etapid)
- **Keskmine meeskond (3-5 DevOps):** 12-18 kuud
- **Suur meeskond (5+ DevOps):** 9-12 kuud

**Märkus:** Aeg sõltub rakenduste arvust (10 vs 50 apps), legacy complexity'st (Tomcat WAR vs Spring Boot JAR), meeskonna kogemusest (Docker/K8s beginners vs experienced).

---

**Viimane uuendus:** 2025-12-12
**Autor:** DevOps Koolituskava
**Sihtrühm:** Legacy Tomcat/Gradle → Kubernetes Migration
**Märksõnad:** Roadmap, Migration, Docker, Kubernetes, Tomcat, Gradle, Java 17
