# Peatükk 1: DevOps Sissejuhatus

## Õpieesmärgid

Peale selle peatüki läbimist oskad:
- ✅ Selgitada DevOps filosoofiat ja põhimõtteid (CALMS framework)
- ✅ Eristada DevOps'i traditsioonilistest IT meetoditest (Waterfall, Agile)
- ✅ Mõista CI/CD, IaC ja DevSecOps kontseptsioone
- ✅ Tunda SRE (Site Reliability Engineering) ja Observability põhimõtteid
- ✅ Tunda DevOps tööriistu ja DORA metrics'eid

## Põhimõisted

- **DevOps (DevOps):** Kultuur, filosoofia ja praktikad, mis ühendavad arenduse (Development) ja operatsioonide (Operations) meeskonnad
- **Pidev integratsioon (Continuous Integration - CI):** Koodi liitmine keskrepositooriumisse sageli (päevad, tunnid), automaatsete testidega
- **Pidev kohaletoimetamine (Continuous Delivery - CD):** Kood on alati valmis production'i paigaldamiseks, aga vajab manuaalset kinnitust
- **Pidev paigaldamine (Continuous Deployment):** Kood paigaldatakse production'i automaatselt ilma manuaalse kinnituseta
- **Infrastruktuur kui kood (Infrastructure as Code - IaC):** Infrastruktuuri kirjeldamine ja haldamine koodi kaudu (deklaratiivne või imperatiivne)
- **Turvalisus kui kood (Security as Code - DevSecOps):** Turvalisuse integreerimine arendusprotsessi algusest peale
- **SRE (Site Reliability Engineering):** Google'i lähenemine DevOps'ile, keskendub süsteemide usaldusväärsusele ja error budget'idele
- **Vaadeldavus (Observability):** Süsteemi sisemise seisundi mõistmine läbi logide, mõõdikute ja jälgede (traces)
- **Konteineristamine (containerization):** Rakenduste pakendamine koos sõltuvustega isoleeritud keskkondadesse
- **Orkestreerimine (orchestration):** Konteinerite automaatne haldamine, skaleerimine ja paigaldamine
- **Jälgimine (monitoring):** Süsteemide ja rakenduste seisundi jälgimine läbi mõõdikute ja alertide
- **Automatiseerimine (automation):** Käsitsi protsesside asendamine automatiseeritud süsteemidega

## Teooria

### 1. Mis on DevOps?

**DevOps** on kultuur, filosoofia ja praktikate kogum, mis ühendab **arenduse (Development)** ja **operatsioonide (Operations)** meeskonnad ühise eesmärgi nimel: kiire, kvaliteetne ja turvaline tarkvara kohaletoimetamine.

**Peamised komponendid:**
- **Dev (Development):** Arendajad, kes kirjutavad koodi
- **Ops (Operations):** Süsteemiadministraatorid, kes haldavad infrastruktuuri

**DevOps kui kultuur:**
DevOps ei ole tööriist ega ametikoht – see on **kultuuriline nihe**, mis kõrvaldab traditsioonilised "silo'd" (eraldatud meeskonnad) ja edendab koostööd, jagatud vastutust ning pidevat õppimist.

**DevOps eesmärgid:**
1. **Kiirus:** Kiirem tarkvara kohaletoimetamine (deployment frequency)
2. **Kvaliteet:** Vähem vigu production'is (change failure rate)
3. **Usaldusväärsus:** Kiirem taastumine vigadest (MTTR - Mean Time to Restore)
4. **Koostöö:** Paremat suhtlust Dev ja Ops vahel

**Näide:**
```
Traditional IT:
Dev kirjutab koodi → viskab üle seina Ops'ile → Ops paigaldab → midagi läheb valesti → blame game

DevOps:
Dev + Ops töötavad koos → automated testing → automated deployment → shared monitoring → shared responsibility
```

---

### 2. DevOps vs Traditsioonilised Meetodid

#### Waterfall Model (jäik, aeglane, sequential)

**Waterfall** on järjestikune (sequential) arendusmeetod:
1. Nõuete analüüs (3 kuud)
2. Disain (2 kuud)
3. Arendus (6 kuud)
4. Testimine (2 kuud)
5. Paigaldamine (2 nädalat)

**Probleemid:**
- ❌ Aeglane (12-18 kuud iga release'i kohta)
- ❌ Jäik (muudatused on kallid)
- ❌ Hiline tagasiside (klient näeb tulemust alles aasta lõpus)
- ❌ Ohtlik paigaldamine (suur "big bang" release)

#### Agile (iterative, fast feedback, dev-focused)

**Agile** on iteratiivne meetod, mis keskendub **arendusele**:
- Sprint'id (2 nädalat)
- Kiire tagasiside kliendilt
- Tihedad muudatused
- Demo iga sprint'i lõpus

**Edu:**
- ✅ Kiire (2 nädalat per sprint)
- ✅ Paindlik (muudatused on lihtsad)
- ✅ Tagasiside (klient näeb tulemust iga 2 nädala tagant)

**Kitsaskohad:**
- ⚠️ Keskendub ainult arendusele (Dev)
- ⚠️ Operations on endiselt eraldi (silo)
- ⚠️ Deployment on aeglane ja riskantne

#### DevOps (Agile + Operations, full lifecycle)

**DevOps** laiendab Agile'i **kogu lifecycle'ile** (arendusest kuni operatsioonideni):
- Dev + Ops töötavad koos
- Automated testing
- Automated deployment
- Shared monitoring
- "You build it, you run it" (Amazon filosoofia)

**Võrdlus (DORA Metrics):**

| Kriteerium | Waterfall | Agile | DevOps (Elite) |
|------------|-----------|-------|----------------|
| **Deployment Frequency** | 1x kvartalis | 1x kuus | Mitu korda päevas |
| **Lead Time** | 4-6 kuud | 2-4 nädalat | < 1 tund |
| **MTTR** | 1-2 nädalat | 1-2 päeva | < 1 tund |
| **Change Failure Rate** | 30-40% | 15-20% | < 5% |
| **Klassifikatsioon** | LOW | MEDIUM | ELITE |

---

### 3. DevOps Kultuur ja Põhimõtted (CALMS Framework)

**CALMS** on DevOps kultuuri raamistik (Jez Humble, Gene Kim):

#### **C – Culture (Kultuur)**

**Shared Responsibility (jagatud vastutus):**
- Dev ja Ops töötavad koos (ei ole "üle seina viskamist")
- "You build it, you run it" (Amazon filosoofia)
- Blameless culture (õppida vigadest, mitte süüdistada)

**Collaboration (koostöö):**
- Ühised eesmärgid (kvaliteet, kiirus, usaldusväärsus)
- Cross-functional teams (arendajad, ops, QA, security koos)

**Blameless Postmortems:**
- Peale incidenti: analüüsime, mis läks valesti (mitte "kes tegi vea")
- Fookus: kuidas vältida sarnaseid vigu tulevikus

#### **A – Automation (Automatiseerimine)**

**Automate Everything:**
- Builds (Docker, Maven, Gradle, npm)
- Tests (unit tests, integration tests, security scans)
- Deployments (Kubernetes, Helm, ArgoCD)
- Infrastructure (Terraform, Ansible)

**Eesmärk:** Kõrvaldada käsitsi (manual) sammud, vähendada vigu, kiirendada protsesse.

#### **L – Lean (Lean))**

**Eliminate Waste (kõrvalda raiskamine):**
- Vähenda WIP (Work In Progress)
- Vähenda ootamist (waiting time)
- Kiire feedback loop

**Continuous Improvement (pidev parandamine):**
- Retrospectives (mis läks hästi, mis halvasti)
- Kaizen (väikesed, pidevad parandused)

#### **M – Measurement (Mõõtmine)**

**DORA Metrics:**
1. **Deployment Frequency:** Kui sageli deploy'me?
2. **Lead Time for Changes:** Commit'ist production'i kestus
3. **Mean Time to Restore (MTTR):** Taastumise kiirus
4. **Change Failure Rate:** Mitu % deployment'itest ebaõnnestub?

**Monitoring:**
- Rakenduste metrics (Prometheus)
- Logid (Loki, ELK stack)
- Alerting (AlertManager, PagerDuty)

#### **S – Sharing (Jagamine)**

**Knowledge Sharing:**
- Documentation (Confluence, GitHub Wiki)
- Pair programming
- Code reviews (pull requests)
- Internal tech talks

**Transparency:**
- Kõik on nähtav (metrics, logs, incidents)
- Post-mortems on avalikud (kogu meeskond õpib)

---

### 4. CI/CD Põhimõtted

#### **Continuous Integration (CI)**

**Definitsioon:** Kood liitub keskrepositooriumisse (main branch) **sageli** (päevad, tunnid), koos **automaatsete testidega**.

**Workflow:**
```
1. Arendaja kirjutab koodi
2. Commit + push to main branch
3. CI server (GitHub Actions, Jenkins) käivitab:
   - Build (kompileerimine)
   - Unit tests
   - Integration tests
   - Linting
4. Tagasiside (pass/fail) < 10 minutit
```

**Eelised:**
- ✅ Kiire tagasiside (arendaja teab kohe, kas kood töötab)
- ✅ Vähem merge conflict'e (kood liitub sageli)
- ✅ Kvaliteet (automaatsed testid püüavad vead kinni)

#### **Continuous Delivery (CD)**

**Definitsioon:** Kood on **alati valmis** production'i paigaldamiseks, aga vajab **manuaalset kinnitust**.

**Workflow:**
```
1. CI pipeline edukalt (tests pass)
2. Deployment pipeline:
   - Staging environment'i paigaldamine (automaatne)
   - Manual approval (product owner kinnitab)
   - Production'i paigaldamine (automaatne peale approval'i)
```

**Eelised:**
- ✅ Kood on alati deployment-ready
- ✅ Vähendatud risk (staging'is testitud)
- ✅ Kontroll (manual approval production'i)

#### **Continuous Deployment**

**Definitsioon:** Kood paigaldatakse **production'i automaatselt** ilma manuaalse kinnituseta.

**Workflow:**
```
1. CI pipeline edukalt (tests pass)
2. Deployment pipeline:
   - Staging environment'i paigaldamine (automaatne)
   - Automated tests staging'is
   - Production'i paigaldamine (automaatne, kui staging tests pass)
```

**Eelised:**
- ✅ Maksimaalne kiirus (commit → production < 1 tund)
- ✅ Väikesed muudatused (vähem riski)

**Nõuded:**
- ⚠️ Väga head testid (100% coverage)
- ⚠️ Feature flags (välja lülitada uusi feature'eid production'is)
- ⚠️ Monitoring ja alerting (kiire reageerimine probleemidele)

**CI/CD Pipeline Diagram:**
```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Commit  │ -> │  Build   │ -> │   Test   │ -> │  Deploy  │ -> │ Monitor  │
│  & Push  │    │ (Docker) │    │ (Auto)   │    │ (Auto)   │    │(Feedback)│
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     │                                                                  │
     └──────────────────────── Fast Feedback Loop ─────────────────────┘
```

---

### 5. Infrastructure as Code (IaC)

**Definitsioon:** Infrastruktuuri kirjeldamine ja haldamine **koodi kaudu** (mitte käsitsi klikkides UI's).

#### **Miks IaC?**

**Probleemid ilma IaC'ta:**
- ❌ Käsitsi setup (aeglane, vigane)
- ❌ "Snowflake servers" (iga server on erinev)
- ❌ Ei ole dokumentatsiooni (knowledge on adminide peas)
- ❌ Ei saa versiooni kontrollida (ei tea, kes muutis mida)

**IaC eelised:**
- ✅ **Version Control:** Infrastruktuur on Git'is (muudatuste ajalugu)
- ✅ **Reproducible:** Sama kood → sama infrastruktuur (dev, staging, prod)
- ✅ **Automation:** Ei pea käsitsi midagi tegema
- ✅ **Documentation:** Kood ON dokumentatsioon

#### **Deklaratiivne vs Imperatiivne**

**Imperatiivne (käsuline):**
```bash
# Käsud: KUIDAS teha
aws ec2 run-instances --instance-type t2.micro --count 3
aws ec2 create-security-group --group-name mysg
aws ec2 authorize-security-group-ingress --group-name mysg --port 80
```

**Deklaratiivne (kirjeldav):**
```hcl
# Kirjelda: MIDA tahad (mitte kuidas)
resource "aws_instance" "web" {
  count         = 3
  instance_type = "t2.micro"
}

resource "aws_security_group" "web" {
  ingress {
    from_port = 80
    to_port   = 80
  }
}
```

**Deklaratiivne on parem:**
- ✅ Idempotent (sama tulemus, kui käivitad mitu korda)
- ✅ Loetav (näed kohe, mis on lõpptulemus)
- ✅ Turvaline (ei kustuta ressursse kogemata)

#### **IaC Tööriistad**

| Tööriist | Kasutusjuht | Keel |
|----------|-------------|------|
| **Terraform** | Multi-cloud infrastruktuur (AWS, Azure, GCP, Kubernetes) | HCL |
| **Ansible** | Configuration management, application deployment | YAML |
| **CloudFormation** | AWS-spetsiifiline infrastruktuur | YAML/JSON |
| **Helm** | Kubernetes package manager | YAML + Go templates |

---

### 6. DevSecOps (Security as Code)

**DevSecOps** = **DevOps + Security** (turvalisus on osa DevOps'ist, mitte eraldi silo).

#### **Shift-Left Security**

**Traditional Security (Shift-Right):**
```
Develop → Test → Security Audit (lõpus) → Deploy
                       ↑
                  Probleemid leitakse hilja (kallis parandada)
```

**DevSecOps (Shift-Left):**
```
Security → Develop → Security Tests → Deploy → Security Monitoring
   ↑            ↑              ↑           ↑
   Security on iga sammu juures (odav parandada)
```

#### **Security Automation**

**1. Static Application Security Testing (SAST):**
- Koodi analüüs ilma käivitamata (source code)
- Leiab SQL injection, XSS, hardcoded secrets
- Tööriistad: SonarQube, Checkmarx, Semgrep

**2. Dynamic Application Security Testing (DAST):**
- Rakenduse testimine töötavas olekus (black-box)
- Leiab runtime vigasid (authentication bypass, CSRF)
- Tööriistad: OWASP ZAP, Burp Suite

**3. Dependency Scanning:**
- Sõltuvuste (npm, Maven) turvavigade skaneerimine
- Tööriistad: Snyk, Dependabot, npm audit

**4. Container Scanning:**
- Docker image'ite turvavigade skaneerimine
- Tööriistad: Trivy, Clair, Anchore

**5. Compliance as Code:**
- Policy enforcement (näiteks "ei tohi kasutada root'i konteinerites")
- Tööriistad: Open Policy Agent (OPA), Kyverno (Kubernetes)

#### **Näide: CI/CD Pipeline DevSecOps'iga**

```yaml
# .github/workflows/devsecops.yml
name: DevSecOps Pipeline

on: [push]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      # 1. SAST (Static Analysis)
      - name: SonarQube Scan
        run: sonar-scanner

      # 2. Secret Detection
      - name: Detect Secrets
        run: trufflehog --regex --entropy=False .

      # 3. Dependency Scan
      - name: npm audit
        run: npm audit --audit-level=moderate

      # 4. Build Docker Image
      - name: Build
        run: docker build -t myapp:${{ github.sha }} .

      # 5. Container Scan
      - name: Trivy Scan
        run: trivy image myapp:${{ github.sha }}

      # 6. Deploy (kui kõik testid mööduvad)
      - name: Deploy
        run: kubectl set image deployment/myapp myapp=myapp:${{ github.sha }}
```

**(Detailsem käsitlus: Peatükid 25-27 - Security Best Practices)**

---

### 7. SRE (Site Reliability Engineering) - Põgus Sissejuhatus

**SRE** on Google'i lähenemine DevOps'ile, mis keskendub **süsteemide usaldusväärsusele** (reliability).

#### **SRE Definitsioon**

> "SRE on see, mis juhtub, kui palud tarkvarainseneril disainida operatsioonide meeskonda."
> – Ben Treynor Sloss (Google)

#### **SRE vs DevOps**

**DevOps:**
- Kultuur ja filosoofia
- Dev + Ops koostöö
- Automation, CI/CD, IaC

**SRE:**
- DevOps'i **implementatsioon** (üks võimalik lähenemine)
- Konkreetsed praktikad ja metrics
- Fookus: **reliability** (usaldusväärsus)

**Analoogia:**
- DevOps = Interface (mida teha)
- SRE = Implementation (kuidas teha)

#### **SRE Põhimõtted**

**1. Error Budgets (veaeelarve):**

**Kontseptsioon:** Kui palju downtime'i on lubatud?

```
SLO (Service Level Objective) = 99.9% uptime
→ Error budget = 0.1% downtime per kuu
→ 0.1% × 30 päeva × 24 tundi = ~43 minutit downtime per kuu (lubatud)
```

**Kuidas kasutada:**
- Kui error budget > 0: võime riske võtta (uued feature'd, deploymentid)
- Kui error budget = 0: freeze (ainult stability fixes, ei ole uusi feature'eid)

**Eelised:**
- ✅ Dev ja Ops on aligned (ühine eesmärk: mitte ületada error budget'i)
- ✅ Innovat objektiivne mõõdik (mitte "tundub, et süsteem on ebastabiilne")

**2. Service Level Objectives (SLO):**

**Definitsioonid:**
- **SLI (Service Level Indicator):** Metrics (latency, error rate, uptime)
- **SLO (Service Level Objective):** Sihtmärk SLI jaoks (99.9% uptime)
- **SLA (Service Level Agreement):** Leping kliendiga (kui SLA rikutakse → kompensatsioon)

**Näide:**
```
SLI: HTTP request success rate
SLO: 99.9% requests succeed (< 0.1% errors)
SLA: Kui < 99%, klient saab 10% raha tagasi
```

**3. Toil Reduction (rutiinsete ülesannete vähendamine):**

**Toil** = Käsitsi, korduv, automatiseeritav töö (näiteks: serverite restart, logide vaatamine, deployment)

**SRE eesmärk:** Vähenda toil < 50% tööajast
- Ülejäänud 50%: Engineering work (automation, tooling, new features)

**Näide:**
```
Probleem: Iga deployment vajab 30 käsitsi sammu (2 tundi)
SRE lahendus: Automatiseeri deployment (Kubernetes Helm chart) → 5 minutit
```

**4. Blameless Postmortems:**

Peale incidenti:
1. Analüüsi, mis läks valesti (timeline, root cause)
2. MITTE "kes tegi vea" (blameless)
3. Action items: kuidas vältida sarnaseid vigu

**(Detailsem käsitlus: Peatükid 22-24 - Monitoring, Logging, Alerting)**

---

### 8. Observability vs Monitoring

#### **Traditional Monitoring**

**Definitsioon:** Metrics ja alerts, mis **teame ette**, mida otsida.

**Näide:**
```
Metric: CPU usage > 80% → Alert
Metric: HTTP 500 errors > 10/min → Alert
Metric: Disk space < 10% → Alert
```

**Probleemid:**
- ❌ Teame ainult "known unknowns" (mida ette näeme)
- ❌ Ei aita debug'ida "unknown unknowns" (ootamatud probleemid)

#### **Observability (Vaadeldavus)**

**Definitsioon:** Süsteemi **sisemise seisundi mõistmine** läbi väliste väljundite (logs, metrics, traces).

**Three Pillars of Observability:**

**1. Logs (sündmuste salvestused):**
```
2025-12-09 10:00:00 INFO  User login successful (user_id=123)
2025-12-09 10:00:05 ERROR Database connection failed (db=postgres, timeout=5s)
```

**2. Metrics (numbrilised mõõdikud):**
```
http_requests_total{method="GET", status="200"} = 1500
http_request_duration_seconds{quantile="0.99"} = 0.5
```

**3. Traces (distribueeritud süsteemide jälgimine):**
```
Request ID: abc123
  ├─ API Gateway (10ms)
  ├─ User Service (50ms)
  │  ├─ Database Query (30ms)  ← Bottleneck!
  │  └─ Cache Lookup (5ms)
  └─ Auth Service (20ms)
```

#### **Monitoring vs Observability**

| Aspekt | Monitoring | Observability |
|--------|-----------|---------------|
| **Fookus** | "Kas süsteem töötab?" | "MIKS süsteem ei tööta?" |
| **Eeldus** | Teame, mida otsida | Ei tea, mida otsida (explorative) |
| **Tööriistad** | Prometheus, Grafana | Prometheus + Loki + Jaeger |
| **Küsimused** | "Kas CPU on kõrge?" | "Miks see API call võttis 5 sekundit?" |

**Näide:**
```
Monitoring: "HTTP 500 errors on tõusnud"
Observability: "HTTP 500 error tekib, kui user_id > 1000000 JA database on Postgres 14 JA kell on 10:00-11:00"
```

**(Detailsem käsitlus: Peatükid 22-24 - Prometheus, Grafana, Loki, Jaeger)**

---

### 9. DORA Metrics (DevOps Performance Metrics)

**DORA (DevOps Research and Assessment)** on uurimisgrupp, mis on tuvastanud **4 peamist metrics'i** DevOps performance'i mõõtmiseks.

#### **1. Deployment Frequency (paigaldamise sagedus)**

**Küsimus:** Kui sageli deploy'me production'i?

**Klassifikatsioon:**
- **Elite:** Multiple deployments per day
- **High:** Between once per day and once per week
- **Medium:** Between once per week and once per month
- **Low:** Fewer than once per month

**Miks oluline:**
- Kiire deployment = kiire feedback = kiire õppimine
- Väikesed muudatused = vähem riski

#### **2. Lead Time for Changes (muudatuste läbilaskmine aeg)**

**Küsimus:** Kui kaua võtab commit'ist production'i jõudmine?

**Klassifikatsioon:**
- **Elite:** Less than one hour
- **High:** Between one day and one week
- **Medium:** Between one week and one month
- **Low:** More than one month

**Miks oluline:**
- Lühem lead time = kiirem väärtuse kohaletoimetamine
- Kiirem reageerimine turuvajadus

tele

#### **3. Mean Time to Restore (MTTR) (taastumise keskmine aeg)**

**Küsimus:** Kui kaua võtab süsteemi taastamine peale incidenti?

**Klassifikatsioon:**
- **Elite:** Less than one hour
- **High:** Less than one day
- **Medium:** Between one day and one week
- **Low:** More than one week

**Miks oluline:**
- Kiirem taastumine = vähem downtime'i = vähem kahju

#### **4. Change Failure Rate (muudatuste ebaõnnestumise määr)**

**Küsimus:** Mitu % deployment'itest põhjustab incident'i (rollback, hotfix)?

**Klassifikatsioon:**
- **Elite:** 0-5%
- **High:** 5-10%
- **Medium:** 10-15%
- **Low:** > 15%

**Miks oluline:**
- Madalam failure rate = kvaliteetsem kood = vähem incidente

#### **DORA Metrics Performance Klassifikatsioon**

| Performance | Deployment Frequency | Lead Time | MTTR | Change Failure Rate |
|-------------|---------------------|-----------|------|---------------------|
| **Elite** | Multiple/day | < 1 hour | < 1 hour | 0-5% |
| **High** | Once/week | 1 day - 1 week | < 1 day | 5-10% |
| **Medium** | Once/month | 1 week - 1 month | 1 day - 1 week | 10-15% |
| **Low** | < Once/month | > 1 month | > 1 week | > 15% |

**Kuidas mõõta:**
- Deployment Frequency: Git commits/tags + deployment logs
- Lead Time: Git commit timestamp - Production deployment timestamp
- MTTR: Incident start time - Resolution time
- Change Failure Rate: Failed deployments / Total deployments

---

### 10. DevOps Tööriistad Ökoloogia

DevOps kasutab laia valiku tööriistu erinevate lifecycle'i faaside jaoks:

#### **Lifecycle'i Faaside kaupa:**

**1. Plan (planeerimine):**
- **Jira:** Issue tracking, sprint planning
- **Trello:** Kanban board
- **GitHub Projects:** Lightweight project management

**2. Code (koodimine):**
- **Git:** Version control
- **GitHub/GitLab:** Remote repository, collaboration
- **VS Code, IntelliJ:** IDE'd

**3. Build (ehitamine):**
- **Docker:** Containerization
- **Maven, Gradle:** Java build tools
- **npm, yarn:** Node.js package managers
- **Webpack, Vite:** Frontend build tools

**4. Test (testimine):**
- **Jest, JUnit:** Unit testing
- **Selenium, Cypress:** End-to-end testing
- **Postman, Newman:** API testing
- **SonarQube:** Code quality, security

**5. Release (väljalase):**
- **GitHub Releases:** Semantic versioning, changelogs
- **Docker Hub, ECR, GCR:** Container registry
- **Artifactory, Nexus:** Artifact repository

**6. Deploy (paigaldamine):**
- **Kubernetes:** Container orchestration
- **Helm:** Kubernetes package manager
- **ArgoCD:** GitOps deployment
- **Terraform:** Infrastructure as Code

**7. Operate (opereerimine):**
- **Kubernetes:** Self-healing, scaling
- **systemd:** Linux service management
- **Ansible:** Configuration management

**8. Monitor (jälgimine):**
- **Prometheus:** Metrics collection
- **Grafana:** Metrics visualization
- **Loki:** Log aggregation
- **Jaeger:** Distributed tracing
- **AlertManager:** Alerting

#### **DevOps Toolchain Diagram:**

```
┌──────────────────────────────────────────────────────────────┐
│                     DEVOPS LIFECYCLE                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  PLAN          CODE         BUILD        TEST         RELEASE│
│  Jira          Git          Docker       Jest         GitHub │
│  Trello        GitHub       Maven        Selenium     Docker │
│                VS Code      npm          SonarQube    Hub    │
│                                                              │
│                    ↓ CI/CD PIPELINE ↓                        │
│                                                              │
│  DEPLOY        OPERATE      MONITOR                          │
│  Kubernetes    Kubernetes   Prometheus                       │
│  Helm          Ansible      Grafana                          │
│  ArgoCD        systemd      Loki                             │
│  Terraform                  Jaeger                           │
│                                                              │
│                    ← FEEDBACK LOOP ←                         │
└──────────────────────────────────────────────────────────────┘
```

---

### 11. DevOps Lifecycle

DevOps lifecycle on **pidev ring** (continuous loop), kus tagasiside (feedback) monitor'imisest mõjutab järgmist planeerimist.

#### **Lifecycle Faasid:**

```
    ┌─────────┐
    │  PLAN   │ ← Tagasiside monitor'imisest
    └────┬────┘
         │
    ┌────▼────┐
    │  CODE   │
    └────┬────┘
         │
    ┌────▼────┐
    │  BUILD  │
    └────┬────┘
         │
    ┌────▼────┐
    │  TEST   │
    └────┬────┘
         │
    ┌────▼────┐
    │ RELEASE │
    └────┬────┘
         │
    ┌────▼────┐
    │ DEPLOY  │
    └────┬────┘
         │
    ┌────▼────┐
    │ OPERATE │
    └────┬────┘
         │
    ┌────▼────┐
    │ MONITOR │
    └────┬────┘
         │
         └──────────┐
                    │
         ┌──────────▼──────────┐
         │  FEEDBACK LOOP      │
         │  (tagasi Plan'i)    │
         └─────────────────────┘
```

**1. Plan (Planeerimine):**
- Nõuete kogumine
- Sprint planning (Agile)
- Backlog prioritiseerimine
- **Tööriistad:** Jira, Trello

**2. Code (Koodimine):**
- Feature development
- Bug fixes
- Code review (pull requests)
- **Tööriistad:** Git, GitHub, VS Code

**3. Build (Ehitamine):**
- Koodi kompileerimine
- Dependencies installation
- Docker image build
- **Tööriistad:** Docker, Maven, Gradle, npm

**4. Test (Testimine):**
- Unit tests
- Integration tests
- Security scans
- **Tööriistad:** Jest, JUnit, SonarQube, Trivy

**5. Release (Väljalase):**
- Semantic versioning (v1.0.0)
- Release notes (changelogs)
- Artifact publishing
- **Tööriistad:** GitHub Releases, Docker Hub

**6. Deploy (Paigaldamine):**
- Staging deployment (automaatne)
- Production deployment (manual või automaatne)
- Rollback (kui viga)
- **Tööriistad:** Kubernetes, Helm, ArgoCD

**7. Operate (Opereerimine):**
- Rakenduse käitamine
- Skaleerimine (HPA - Horizontal Pod Autoscaling)
- Self-healing (konteinerite restart)
- **Tööriistad:** Kubernetes, systemd

**8. Monitor (Jälgimine):**
- Metrics kogumine (CPU, memory, requests)
- Logide kogumine
- Alerting (kui midagi läheb valesti)
- **Tööriistad:** Prometheus, Grafana, Loki, AlertManager

**Feedback Loop:**
Monitor'imisest saadud andmed → Plan (järgmine sprint)
- Kas kliendid kasutavad uut feature'd? (analytics)
- Kas performance on hea? (latency metrics)
- Kas on vigu? (error rate)

---

## Praktilised Näited

### Näide 1: Traditional vs DevOps Deployment (DORA Metrics Võrdlus)

**Stsenaarium:** E-commerce rakendus, uue "Shopping Cart" feature paigaldamine.

#### **Traditional (Waterfall) Lähenemine:**

```
Timeline:
- Nõuete kogumine: 2 nädalat
- Disain: 2 nädalat
- Arendus: 8 nädalat
- QA testimine: 3 nädalat
- UAT (User Acceptance Testing): 2 nädalat
- Production deployment: 1 nädal (manual, riskantne)

Kokku: 18 nädalat (4.5 kuud)

DORA Metrics:
- Deployment Frequency: 1x kvartalis
- Lead Time: 4.5 kuud
- MTTR: 1-2 nädalat (kui midagi läheb valesti)
- Change Failure Rate: 30-40% (suur "big bang" release)

Klassifikatsioon: LOW performer
```

#### **DevOps (Elite) Lähenemine:**

```
Timeline (Sprint 1):
- Planning: 2 tundi
- Development: 3 päeva
- Automated tests: käivituvad iga commit'iga (5 minutit)
- Deployment to staging: automaatne (5 minutit)
- Deployment to production: automaatne (5 minutit)

Kokku: 3-4 päeva (iga feature on väike, deploy'me mitu korda päevas)

DORA Metrics:
- Deployment Frequency: Multiple deployments per day
- Lead Time: < 1 hour (commit → production)
- MTTR: < 1 hour (kui midagi läheb valesti, rollback 2 minutit)
- Change Failure Rate: < 5% (väikesed muudatused, head testid)

Klassifikatsioon: ELITE performer
```

**Võrdlus:**

| Aspekt | Traditional | DevOps (Elite) |
|--------|-------------|----------------|
| **Aeg kliendini** | 4.5 kuud | 3-4 päeva |
| **Risk** | Kõrge (suur release) | Madal (väike release) |
| **Rollback** | Raske (2 nädalat) | Lihtne (2 minutit) |
| **Vigade avastamine** | Hilja (QA lõpus) | Vara (iga commit) |
| **Kliendi tagasiside** | 4.5 kuud hiljem | 3-4 päeva hiljem |

---

### Näide 2: CI/CD Pipeline Näide (DevSecOps)

**Stsenaarium:** Node.js rakenduse CI/CD pipeline GitHub Actions'is, koos turvalisuse skanneerimisega.

```yaml
# .github/workflows/ci-cd-devsecops.yml
name: CI/CD Pipeline (DevSecOps)

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-test-deploy:
    runs-on: ubuntu-latest

    steps:
      # 1. Checkout kood
      - name: Checkout code
        uses: actions/checkout@v3

      # 2. Node.js setup
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      # 3. Install dependencies
      - name: Install dependencies
        run: npm ci

      # 4. Linting (code quality)
      - name: ESLint
        run: npm run lint

      # 5. Unit tests
      - name: Run unit tests
        run: npm test

      # 6. Security: Dependency scan
      - name: npm audit
        run: npm audit --audit-level=moderate

      # 7. Security: Secret detection
      - name: Detect secrets
        run: |
          npm install -g trufflehog
          trufflehog --regex --entropy=False .

      # 8. Build Docker image
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      # 9. Security: Container scan
      - name: Trivy container scan
        run: |
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy image myapp:${{ github.sha }}

      # 10. Push to Docker Hub (kui kõik testid mööduvad)
      - name: Login to Docker Hub
        if: github.ref == 'refs/heads/main'
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Push image
        if: github.ref == 'refs/heads/main'
        run: |
          docker tag myapp:${{ github.sha }} myuser/myapp:latest
          docker push myuser/myapp:latest

      # 11. Deploy to Kubernetes (production)
      - name: Deploy to Kubernetes
        if: github.ref == 'refs/heads/main'
        run: |
          kubectl set image deployment/myapp myapp=myuser/myapp:${{ github.sha }}
          kubectl rollout status deployment/myapp

      # 12. Notify Slack
      - name: Slack notification
        if: always()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployment ${{ job.status }}: myapp@${{ github.sha }}"
            }
```

**Selgitus:**
1. **CI (Continuous Integration):** Build, lint, test (sammud 1-5)
2. **DevSecOps:** Security scans (sammud 6-7, 9)
3. **CD (Continuous Delivery):** Docker build, push, deploy (sammud 8, 10-11)
4. **Feedback:** Slack notification (samm 12)

**Tulemus:**
- Iga commit → automaatne pipeline (5-10 minutit)
- Security on integreeritud (Shift-Left Security)
- Deployment on automaatne (Continuous Deployment)

---

### Näide 3: Infrastructure as Code (Terraform + Kubernetes)

**Stsenaarium:** Kubernetes Deployment ja Service loomine Terraform'iga.

```hcl
# main.tf
# Deklaratiivne lähenemine: kirjelda MIDA tahad (mitte KUIDAS)

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Deployment: Rakenduse käitamine 3 replica'ga
resource "kubernetes_deployment" "myapp" {
  metadata {
    name = "myapp"
    labels = {
      app = "myapp"
    }
  }

  spec {
    replicas = 3  # High availability (3 Pod'i)

    selector {
      match_labels = {
        app = "myapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "myapp"
        }
      }

      spec {
        container {
          name  = "myapp"
          image = "myuser/myapp:1.0.0"

          port {
            container_port = 8080
          }

          # Resource limits (best practice)
          resources {
            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          # Health check
          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# Service: Stable endpoint Pod'ide jaoks
resource "kubernetes_service" "myapp" {
  metadata {
    name = "myapp-service"
  }

  spec {
    selector = {
      app = "myapp"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"  # Expose väljapoole
  }
}
```

**Kasutamine:**

```bash
# 1. Initialize Terraform
terraform init

# 2. Vaata, mida Terraform teeb (dry-run)
terraform plan

# 3. Rakenda muudatused
terraform apply

# 4. Kontrolli Kubernetes'es
kubectl get deployments
kubectl get pods
kubectl get services
```

**Eelised:**
- ✅ **Version Control:** Kood on Git'is (muudatuste ajalugu)
- ✅ **Reproducible:** Sama kood → sama infrastruktuur (dev, staging, prod)
- ✅ **Documentation:** Kood ON dokumentatsioon (ei pea dokumenteerima käsitsi)
- ✅ **Idempotent:** Võid käivitada `terraform apply` mitu korda, tulemus on sama

---

## Levinud Müüdid ja Väärarusaamad

### Müüt 1: "DevOps = Tööriistad"

**Väärarusaam:** "Kui paigaldan Docker'i ja Kubernetes'e, olen DevOps meeskond."

**Tõde:** DevOps on **esmajoones kultuur ja filosoofia** (CALMS framework). Tööriistad aitavad, aga ilma kultuurita ei toimi.

**Näide:**
- ❌ Vale: "Meil on Jenkins, Docker, Kubernetes → me oleme DevOps"
- ✅ Õige: "Dev ja Ops töötavad koos, jagame vastutust, automatiseerime protsesse, mõõdame DORA metrics'eid → me oleme DevOps"

**Analoogia:** Hammaste pesemine ei tee sinust hambaarsti. Samuti Docker ei tee sinust DevOps meeskonda.

---

### Müüt 2: "DevOps = DevOps Engineer"

**Väärarusaam:** "Loome 'DevOps Engineer' ametikoha, kes tegeleb deployment'iga."

**Tõde:** DevOps on **kogu meeskonna vastutus** (devs, ops, QA, security). "DevOps Engineer" on **anti-pattern**, mis tekitab uue **silo** (eraldatud meeskond).

**Probleem:**
```
Before: Dev → (üle seina) → Ops
After:  Dev → (üle seina) → DevOps Engineer → (üle seina) → Ops

Tulemus: Uus silo, sama probleem!
```

**Õige lähenemine:**
- ✅ **Cross-functional team:** Dev, Ops, QA, Security töötavad **koos**
- ✅ **Shared responsibility:** Kõik vastutavad deployment'i, monitoring'u, turvalisuse eest
- ✅ **"You build it, you run it":** Arendajad vastutavad ka production'i eest

---

### Müüt 3: "DevOps = Kubernetes"

**Väärarusaam:** "DevOps = Docker + Kubernetes. Kui pole Kubernetes'e, pole DevOps'i."

**Tõde:** Kubernetes on **üks tööriist** paljudest. Väikesed projektid võivad kasutada **Docker Compose**'i või isegi **systemd**'i.

**Õige valiku kriteeriumid:**
- **Väike projekt (1-3 teenust):** Docker Compose
- **Keskmine projekt (5-10 teenust):** Kubernetes (K3s, managed K8s)
- **Suur projekt (100+ teenust):** Kubernetes + Helm + ArgoCD

**Näide:**
- ❌ Vale: "Blogil (1 server) on vaja Kubernetes'e"
- ✅ Õige: "Blog töötab Docker Compose'iga, Kubernetes on overkill"

---

### Müüt 4: "DevOps = NoOps"

**Väärarusaam:** "DevOps tähendab Ops'i kõrvaldamist. Arendajad teevad kõike ise."

**Tõde:** DevOps **ei tähenda** Ops'i kõrvaldamist. Operations on **endiselt vajalik**, aga **koos Dev'iga** (mitte eraldi silo).

**Ops rolli muutumine DevOps'is:**
- **Enne DevOps'i:** Ops tegeleb serverite, deployment'iga käsitsi
- **DevOps'is:** Ops tegeleb **automatiseerimise, tooling'u, platform engineering'uga**

**Näide:**
- Ops ehitab CI/CD pipeline'i (GitHub Actions, ArgoCD)
- Ops haldab Kubernetes cluster'it (K3s, monitoring, backup)
- Ops loob IaC template'id (Terraform modules, Helm charts)

---

### Müüt 5: "DevOps on ainult startup'idele"

**Väärarusaam:** "DevOps töötab ainult väikestes startup'ides. Suured ettevõtted ei saa DevOps'i teha."

**Tõde:** DevOps praktikad töötavad **igas organisatsioonis** (väike startup kuni suur enterprise). Isegi Google, Amazon, Microsoft kasutavad DevOps'i.

**Näited:**
- **Amazon:** "You build it, you run it" (2002)
- **Google:** SRE (Site Reliability Engineering)
- **Netflix:** Chaos Engineering, microservices
- **Microsoft:** Azure DevOps, GitHub Actions

**Väljakutsed suurtes ettevõtetes:**
- ⚠️ Legacy systems (vana tehnoloogia)
- ⚠️ Organisatsiooniline vastupanu (kultuuriline muutus on raske)
- ⚠️ Compliance (regulatsioonid, auditid)

**Lahendus:**
- ✅ Alusta väikestest sammudest (üks meeskond, üks projekt)
- ✅ Tõesta väärtust (DORA metrics)
- ✅ Laienda järk-järgult

---

### Müüt 6: "SRE ja DevOps on vastandlikud"

**Väärarusaam:** "SRE ja DevOps on erinevad meetodid. Pean valima ühe."

**Tõde:** SRE on **üks DevOps'i implementatsioon** (Google lähenemine). SRE kasutab DevOps põhimõtteid.

**Analoogia:**
- **DevOps** = Interface (mida teha)
- **SRE** = Implementation (kuidas teha)

**Võrdlus:**

| Aspekt | DevOps | SRE |
|--------|--------|-----|
| **Päritolu** | Agile + Operations | Google (2003) |
| **Fookus** | Dev + Ops koostöö | Reliability (usaldusväärsus) |
| **Lähenemine** | Kultuur, filosoofia | Konkreetsed praktikad |
| **Metrics** | DORA metrics | SLO, error budgets |
| **Sobib** | Kõigile organisatsioonidele | Suurematele organisatsioonidele |

**Tõde:** Võid kasutada mõlemat! SRE praktikad (error budgets, SLO) täiendavad DevOps kultuuri.

---

## Best Practices

### DO (Tee nii):

- ✅ **Alusta väikestest sammudest:** Ei pea kohe Kubernetes'ega alustama. Alusta Docker Compose'iga.
- ✅ **Automatiseeri kõike, mida saad:** Builds, tests, deployments, security scans
- ✅ **Mõõda DORA metrics'eid:** Deployment frequency, lead time, MTTR, change failure rate
- ✅ **Jaga teadmisi:** Documentation (README, Confluence), pair programming, code reviews
- ✅ **Continuous improvement:** Retrospectives (mis läks hästi, mis halvasti), kaizen (väikesed parandused)
- ✅ **Shift-Left Security:** Turvalisus arenduse alguses (mitte lõpus)
- ✅ **Observability > Monitoring:** Mõista süsteemi seesmist käitumist (logs + metrics + traces)
- ✅ **Blameless culture:** Õppida vigadest (mitte süüdistada)
- ✅ **"You build it, you run it":** Arendajad vastutavad ka production'i eest
- ✅ **Väikesed muudatused:** Väiksed deployment'id = vähem riski

### DON'T (Ära tee nii):

- ❌ **Ära loo "DevOps team":** Tekitab uue silo. DevOps on kogu meeskonna vastutus.
- ❌ **Ära keskendu ainult tööriistadele:** Kultuur on tähtsam kui tööriistad.
- ❌ **Ära unusta turvalisust:** DevSecOps (Security as Code)
- ❌ **Ära tee suuri "big bang" release'e:** Väikesed, sagedased deployment'id on paremad
- ❌ **Ära ignoreeri DORA metrics'eid:** Kui ei mõõda, ei saa parandada
- ❌ **Ära süüdista:** Blameless culture (õppida vigadest)
- ❌ **Ära optimiseeri enneaegset:** Alusta lihtsalt (Docker Compose), optimeeri hiljem (Kubernetes)

---

## Kokkuvõte

- **DevOps** on kultuur, filosoofia ja praktikad (CALMS framework), mis ühendab Dev + Ops meeskonnad
- **DevOps vs Traditional:** Kiire (multiple deployments/day) vs aeglane (1x kvartalis)
- **CI/CD** on DevOps põhiprintsiibid: Continuous Integration → Continuous Delivery/Deployment
- **IaC** (Infrastructure as Code): Infrastruktuur on koodina (Terraform, Ansible, Helm)
- **DevSecOps** = Security as Code (Shift-Left Security, security scans CI/CD's)
- **SRE** on üks DevOps'i implementatsioon (Google, error budgets, SLO)
- **Observability** > Monitoring: Mõista süsteemi seesmist käitumist (logs + metrics + traces)
- **DORA metrics** mõõdavad DevOps performance'i: Deployment frequency, lead time, MTTR, change failure rate
- **DevOps lifecycle** on pidev ring: Plan → Code → Build → Test → Release → Deploy → Operate → Monitor → (feedback loop) → Plan
- **DevOps eesmärk:** Kiire, kvaliteetne, turvaline tarkvara kohaletoimetamine

---

## Viited ja Edasine Lugemine

### Raamatud:
- [**The Phoenix Project**](https://www.amazon.com/Phoenix-Project-DevOps-Helping-Business/dp/0988262592) - DevOps filosoofia läbi romaani (Gene Kim, Kevin Behr, George Spafford)
- [**The DevOps Handbook**](https://www.amazon.com/DevOps-Handbook-World-Class-Reliability-Organizations/dp/1942788002) - DevOps praktikad (Gene Kim, Jez Humble, Patrick Debois, John Willis)
- [**Accelerate: The Science of DevOps**](https://www.amazon.com/Accelerate-Software-Performing-Technology-Organizations/dp/1942788339) - DORA metrics uurimus (Nicole Forsgren, Jez Humble, Gene Kim)
- [**Site Reliability Engineering (SRE Book)**](https://sre.google/sre-book/table-of-contents/) - Google SRE (tasuta online)

### Artikid ja Ressursid:
- [**DORA Metrics**](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance) - DevOps performance mõõtmine
- [**CALMS Framework**](https://www.atlassian.com/devops/frameworks/calms-framework) - DevOps kultuuri raamistik
- [**DevOps Roadmap**](https://roadmap.sh/devops) - DevOps õppimise tee
- [**The Twelve-Factor App**](https://12factor.net/) - Moderne rakenduste arhitektuur

### Videod ja Kursused:
- [**DevOps Tutorial for Beginners (freeCodeCamp)**](https://www.youtube.com/watch?v=hQcFE0RD0cQ) - 2h video
- [**Google Cloud Skills Boost - DevOps**](https://www.cloudskillsboost.google/paths/20) - Hands-on labs

---

**Viimane uuendus:** 2025-12-09
**Seos laboritega:** Üldine teoreetiline raamistik kõigile laboritele (Lab 1-10)
**Eelmine peatükk:** -
**Järgmine peatükk:** [02-Linux-Pohitoed-DevOps-Kontekstis.md](02-Linux-Pohitoed-DevOps-Kontekstis.md)
