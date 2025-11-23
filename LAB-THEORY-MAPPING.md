# Lab-Theory Mapping Analysis

**Kuupäev:** 2025-11-23
**Eesmärk:** Analüüsida laborite ja koolituskava peatükkide seoseid
**Probleem:** Labid ei viita koolituskavale, kuigi koolituskava peaks toetama laboreid

---

## 🎯 Põhimõte

**User feedback:**
> "Koolituskava peab toetama just laboreid. Laborid on suures plaanis valmis neid enam väga ei muudaks, kuid neist võis olla viited koolituskavasse, kus oleks laboris tehtavate tegevuste põhjalikud selgitused."

**Ideaalne suhe:**
- **Theory chapters (Peatükid):** Selgitavad MIKS ja KUIDAS (concepts, design decisions, WHY)
- **Labs (Laborid):** Näitavad PRAKTIKAS kuidas teha (hands-on, step-by-step, complete examples)
- **Cross-references:** Labs → Theory (põhjalikud selgitused), Theory → Labs (praktika viited)

---

## 📊 Current State: Labs Overview

| Lab | Harjutusi | Praegune viitamine theory'le |
|---|---|---|
| Lab 1: Docker | 6 | ❌ Ei viita |
| Lab 2: Docker Compose | 6 | ❌ Ei viita |
| Lab 3: Kubernetes Basics | 6 | ❌ Ei viita |
| Lab 4: Kubernetes Advanced | 5 | ❌ Ei viita |
| Lab 5: CI/CD | 5 | ❌ Ei viita |
| Lab 6: Monitoring/Logging | 5 | ❌ Ei viita |

**Total:** 33 harjutust, **0 viiteid** koolituskavale

---

## 🗺️ Lab-Theory Mapping

### Lab 1: Docker Lab (6 exercises)

**Theory chapters that SHOULD support this lab:**

| Exercise | Toetavad peatükid | Mida theory selgitab |
|---|---|---|
| **01a-single-container-nodejs** | Peatükk 4: Docker Põhimõtted<br>Peatükk 5: Dockerfile | MIKS containerid, image layers, build optimization |
| **01b-single-container-java** | Peatükk 5: Dockerfile | Multi-stage builds, JVM optimization |
| **02-multi-container** | Peatükk 4: Docker Põhimõtted | Container networking, port mapping |
| **03-networking** | Peatükk 4: Docker Põhimõtted | Docker networks, DNS resolution, isolation |
| **04-volumes** | Peatükk 4: Docker Põhimõtted<br>Peatükk 6: PostgreSQL Konteinerites | Persistent storage, volume vs bind mount trade-offs |
| **05-optimization** | Peatükk 5: Dockerfile | Layer caching, image size optimization, multi-stage builds |

**Missing references:**
- Lab exercises ei viita Peatükk 4, 5, 6'le WHY selgituste jaoks
- Peatükk 4, 5, 6 ei viita Lab 1'le praktika jaoks

---

### Lab 2: Docker Compose Lab (6 exercises)

**Theory chapters that SHOULD support this lab:**

| Exercise | Toetavad peatükid | Mida theory selgitab |
|---|---|---|
| **01-compose-basics** | Peatükk 7: Docker Compose | MIKS Docker Compose, YAML structure, service dependencies |
| **02-add-frontend** | Peatükk 7: Docker Compose | Multi-service orchestration, networks |
| **03-environment-management** | Peatükk 7: Docker Compose | Environment files, secrets management, .env patterns |
| **04-database-migrations** | Peatükk 6: PostgreSQL Konteinerites<br>Peatükk 7: Docker Compose | Database init, migrations, depends_on, healthchecks |
| **05-production-patterns** | Peatükk 7: Docker Compose | Production vs dev configurations, resource limits |
| **06-advanced-patterns** | Peatükk 7: Docker Compose | Profiles, extends, override files |

**Missing references:**
- Lab exercises ei viita Peatükk 7'le
- Peatükk 7 (120 code blocks!) sisaldab palju YAML'i, mis peaks olema Lab 2'es

**RECOMMENDATION:**
- Peatükk 7 peaks olema EXPLANATORY (MIKS Docker Compose, design decisions)
- Lab 2 peaks sisaldama täielikke docker-compose.yml näiteid
- Cross-reference: Peatükk 7 → Lab 2 (praktika), Lab 2 → Peatükk 7 (WHY selgitused)

---

### Lab 3: Kubernetes Basics Lab (6 exercises)

**Theory chapters that SHOULD support this lab:**

| Exercise | Toetavad peatükid | Mida theory selgitab |
|---|---|---|
| **01-cluster-setup-pods** | Peatükk 9: Kubernetes Alused ja K3s Setup | MIKS Kubernetes, pod lifecycle, K3s vs K8s |
| **02-deployments-replicasets** | Peatükk 10: Pods ja Deployments | Replica sets, rolling updates, self-healing |
| **03-services-networking** | Peatükk 11: Services ja Networking | ClusterIP vs NodePort vs LoadBalancer trade-offs |
| **04-configuration-management** | Peatükk 12: ConfigMaps ja Secrets | MIKS separate config from code, secrets security |
| **05-persistent-storage** | Peatükk 13: Persistent Storage | PV vs PVC, storage classes, StatefulSet philosophy |
| **06-initcontainers-migrations** | Peatükk 10: Pods ja Deployments<br>Peatükk 13: Persistent Storage | Init containers, database migrations in K8s |

**Missing references:**
- Lab 3 ei viita Peatükk 9-13'le
- Peatükid 10-13 (78-112 code blocks!) sisaldavad palju YAML'i

**RECOMMENDATION:**
- Peatükid 9-13 peaks olema EXPLANATORY (MIKS K8s, design decisions, trade-offs)
- Lab 3 peaks sisaldama täielikke K8s manifest'e
- Cross-reference: Theory → Lab 3 (praktika), Lab 3 → Theory (WHY)

---

### Lab 4: Kubernetes Advanced Lab (5 exercises)

**Theory chapters that SHOULD support this lab:**

| Exercise | Toetavad peatükid | Mida theory selgitab |
|---|---|---|
| **01-dns-nginx-proxy** | Peatükk 11: Services ja Networking | DNS in K8s, service discovery |
| **02-kubernetes-ingress** | Peatükk 14: Ingress ja Load Balancing | MIKS Ingress vs LoadBalancer, Traefik vs Nginx |
| **03-ssl-tls** | Peatükk 14: Ingress ja Load Balancing<br>Peatükk 22: Security Best Practices | cert-manager, TLS termination, HTTPS importance |
| **04-helm-charts** | Peatükk 14: Ingress ja Load Balancing (?) | Helm philosophy, package management, templating |
| **05-autoscaling-rolling** | Peatükk 23: High Availability ja Scaling | HPA, VPA, resource limits, scaling strategies |

**Missing references:**
- Lab 4 ei viita Peatükk 14, 22, 23'le
- Peatükk 14 (40 code blocks) sisaldab Ingress YAML'e

**RECOMMENDATION:**
- Peatükk 14 peaks selgitama Ingress/LoadBalancing concepts (MIKS)
- Lab 4 peaks sisaldama täielikke Ingress/Helm näiteid
- Võib kaaluda Peatükk 14.5: Helm (hetkel puudub?)

---

### Lab 5: CI/CD Lab (5 exercises)

**Theory chapters that SHOULD support this lab:**

| Exercise | Toetavad peatükid | Mida theory selgitab |
|---|---|---|
| **01-github-actions-basics** | Peatükk 15: GitHub Actions Basics | MIKS CI/CD, triggers, secrets management philosophy |
| **02-docker-build-push** | Peatükk 16: Docker Build Automation | Tagging strategy, multi-platform builds, caching |
| **03-kubernetes-deploy** | Peatükk 17: Kubernetes Deployment Automation | GitOps, blue-green vs canary, deployment strategies |
| **04-automated-testing** | Peatükk 15: GitHub Actions Basics | Testing philosophy, fail-fast, parallel jobs |
| **05-multi-environment** | Peatükk 17: Kubernetes Deployment Automation | Environment management, dev/staging/prod patterns |

**Missing references:**
- Lab 5 ei viita Peatükk 15, 16, 17'le
- Peatükk 15 (118 code blocks → 66 pärast revisioon) sisaldas palju YAML'i

**CURRENT STATE (after Chapter 15 revision):**
- ✅ Peatükk 15 nüüd EXPLANATORY FOCUS (MIKS CI/CD, design decisions)
- ✅ Peatükk 15 viitab Lab 5'le: "Täielikke workflow näiteid harjutad Lab 5'is"
- ❌ Lab 5 EI viita Peatükk 15'le (peaks lisama: "Kontseptide selgitused: Peatükk 15")

**RECOMMENDATION:**
- ✅ Theory → Lab viited on Peatükk 15'is
- ❌ Lab → Theory viiteid pole veel (TULEB LISADA)

---

### Lab 6: Monitoring/Logging Lab (5 exercises)

**Theory chapters that SHOULD support this lab:**

| Exercise | Toetavad peatükid | Mida theory selgitab |
|---|---|---|
| **01-prometheus-setup** | Peatükk 18: Prometheus ja Metrics | MIKS metrics, pull vs push, PromQL philosophy |
| **02-grafana-dashboards** | Peatükk 19: Grafana ja Visualization | Dashboard design, visualization best practices |
| **03-application-metrics** | Peatükk 18: Prometheus ja Metrics | Custom metrics, instrumentation, metric types |
| **04-logging-loki** | Peatükk 20: Logging ja Log Aggregation - Loki | MIKS Loki vs ELK, LogQL, label-based indexing |
| **05-alerting-monitoring** | Peatükk 21: Alerting | Alert design, symptom-based vs cause-based, SLI/SLO |

**Missing references:**
- Lab 6 ei viita Peatükk 18-21'le
- Peatükid 18, 19, 20 (52-76 code blocks) sisaldavad configuration'eid

**RECOMMENDATION:**
- Peatükid 18-21 peaks olema EXPLANATORY (MIKS metrics/logging/alerting)
- Lab 6 peaks sisaldama täielikke Prometheus/Grafana/Loki config'e
- Cross-reference: Theory → Lab 6, Lab 6 → Theory

---

## 🔧 Revision Strategy: Lab-Theory Integration

### Problem

**Current state:**
1. Theory chapters CODE-HEAVY (60-120 code blocks)
2. Labs HANDS-ON (step-by-step complete examples)
3. **OVERLAP:** Theory ja Labs mõlemad sisaldavad täielikke implementation'eid
4. **NO CROSS-REFERENCES:** Labs ei viita theory'le, theory ei viita lab'idele

**Result:**
- Duplication (sama YAML theory's ja lab'is)
- Confusion (kus peaks õppima, theory või lab?)
- Theory on liiga koodirikas (peaks olema EXPLANATORY)

---

### Solution: Clear Separation

**THEORY (Peatükid):**
- ✅ MIKS midagi tehakse (philosophy, problems, solutions)
- ✅ KUIDAS see toimib (architecture, concepts, components)
- ✅ MILLAL kasutada (design decisions, trade-offs)
- ✅ MINIMAL CODE (1-2 illustrative snippets, NOT complete implementations)
- ✅ VIITED LABIDELE: "Täielikke näiteid harjutad Lab X'is"

**LABS (Harjutused):**
- ✅ PRAKTIKAS kuidas teha (step-by-step, complete examples)
- ✅ COMPLETE YAML/CODE (full workflows, manifests, configurations)
- ✅ TROUBLESHOOTING (debugging, common errors, solutions)
- ✅ VIITED THEORY'LE: "Kontseptide selgitused: Peatükk X"

---

### Action Plan

**PHASE 1: Update Theory Chapters (EXPLANATORY FOCUS)**

For each CODE-HEAVY chapter:
1. **REDUCE code blocks** (remove complete implementations → keep minimal examples)
2. **ADD WHY explanations** (design decisions, trade-offs, philosophy)
3. **ADD Lab references** (Lab X, Harjutus Y - täielik näide)

**Example (Chapter 15 - DONE ✅):**
- Before: 118 code blocks (complete GitHub Actions workflows)
- After: 66 code blocks (minimal conceptual examples)
- Added: "Täielikke workflow näiteid harjutad Lab 5: CI/CD Lab'is"

**PHASE 2: Update Lab Exercises (ADD THEORY REFERENCES)**

For each lab exercise:
1. **ADD theory reference section** (beginning of exercise)
2. **LINK to relevant chapters** (Peatükk X selgitab MIKS)
3. **BRIEF WHY summary** (1-2 sentences) + "Täpsemalt: Peatükk X"

**Example template for labs:**

```markdown
# Harjutus 1: GitHub Actions Põhitõed

**Kestus:** 45 minutit
**Eesmärk:** Õppida GitHub Actions workflow'de loomist

**📘 Teooria:**
- **Peatükk 15: GitHub Actions Basics** - Selgitab MIKS CI/CD on kriitiline, kuidas GitHub Actions arhitektuur toimib, ja MILLAL kasutada erinevaid triggers/patterns
- **Key concepts:** CI/CD pipeline revolutsioon (30 min → 5 min deploy), secrets management, parallel jobs trade-offs

---

## 📋 Ülevaade

Selles harjutuses rakendam **Peatükk 15'is õpitud kontsepte** praktikas...
[rest of exercise]
```

---

## 📋 Recommended Cross-References

### Lab 1: Docker Lab

**Add to exercises:**
```markdown
📘 Teooria:
- Peatükk 4: Docker Põhimõtted - Selgitab MIKS containerid, image layers, networking
- Peatükk 5: Dockerfile - Selgitab multi-stage builds, layer caching, optimization
- Peatükk 6: PostgreSQL Konteinerites - Selgitab persistent storage, volumes
```

**Update in theory:**
- Peatükk 4 → "Praktika: Lab 1, Harjutus 1-4 (containers, networking, volumes)"
- Peatükk 5 → "Praktika: Lab 1, Harjutus 5 (Dockerfile optimization)"
- Peatükk 6 → "Praktika: Lab 1, Harjutus 4 (PostgreSQL volumes)"

---

### Lab 2: Docker Compose Lab

**Add to exercises:**
```markdown
📘 Teooria:
- Peatükk 7: Docker Compose - Selgitab MIKS Docker Compose, service orchestration, environment management
```

**Update in theory:**
- Peatükk 7 → "Praktika: Lab 2 (täielikud docker-compose.yml näited)"

---

### Lab 3: Kubernetes Basics Lab

**Add to exercises:**
```markdown
📘 Teooria:
- Peatükk 9: Kubernetes Alused - Selgitab MIKS Kubernetes, pod lifecycle
- Peatükk 10: Pods ja Deployments - Selgitab replica sets, rolling updates
- Peatükk 11: Services ja Networking - Selgitab ClusterIP vs NodePort vs LoadBalancer
- Peatükk 12: ConfigMaps ja Secrets - Selgitab config management, secrets security
- Peatükk 13: Persistent Storage - Selgitab PV/PVC, StatefulSet
```

**Update in theory:**
- Peatükk 9 → "Praktika: Lab 3, Harjutus 1"
- Peatükk 10 → "Praktika: Lab 3, Harjutus 2"
- Peatükk 11 → "Praktika: Lab 3, Harjutus 3"
- Peatükk 12 → "Praktika: Lab 3, Harjutus 4"
- Peatükk 13 → "Praktika: Lab 3, Harjutus 5-6"

---

### Lab 4: Kubernetes Advanced Lab

**Add to exercises:**
```markdown
📘 Teooria:
- Peatükk 14: Ingress ja Load Balancing - Selgitab MIKS Ingress, cert-manager, TLS
- Peatükk 23: High Availability ja Scaling - Selgitab HPA, scaling strategies
```

**Update in theory:**
- Peatükk 14 → "Praktika: Lab 4, Harjutus 1-3 (Ingress, SSL/TLS)"
- Peatükk 23 → "Praktika: Lab 4, Harjutus 5 (autoscaling)"

---

### Lab 5: CI/CD Lab ✅ (partially done)

**Add to exercises:**
```markdown
📘 Teooria:
- Peatükk 15: GitHub Actions Basics - Selgitab MIKS CI/CD, triggers, secrets, design decisions
- Peatükk 16: Docker Build Automation - Selgitab tagging strategy, multi-platform builds
- Peatükk 17: Kubernetes Deployment Automation - Selgitab GitOps, deployment strategies
```

**Update in theory:**
- ✅ Peatükk 15 → "Praktika: Lab 5" (ALREADY ADDED after revision)
- Peatükk 16 → "Praktika: Lab 5, Harjutus 2"
- Peatükk 17 → "Praktika: Lab 5, Harjutus 3-5"

---

### Lab 6: Monitoring/Logging Lab

**Add to exercises:**
```markdown
📘 Teooria:
- Peatükk 18: Prometheus ja Metrics - Selgitab MIKS metrics, PromQL
- Peatükk 19: Grafana ja Visualization - Selgitab dashboard design
- Peatükk 20: Logging ja Log Aggregation - Loki - Selgitab MIKS Loki, LogQL
- Peatükk 21: Alerting - Selgitab alert design, SLI/SLO
```

**Update in theory:**
- Peatükk 18 → "Praktika: Lab 6, Harjutus 1, 3"
- Peatükk 19 → "Praktika: Lab 6, Harjutus 2"
- Peatükk 20 → "Praktika: Lab 6, Harjutus 4"
- Peatükk 21 → "Praktika: Lab 6, Harjutus 5"

---

## 🎯 Success Criteria

**Theory chapters:**
- ✅ EXPLANATORY FOCUS (MIKS, KUIDAS, MILLAL)
- ✅ Minimal code (20-40 conceptual snippets, NOT 100+ complete examples)
- ✅ Lab references ("Praktika: Lab X, Harjutus Y")

**Lab exercises:**
- ✅ Complete code examples (full YAML workflows, manifests)
- ✅ Theory references ("📘 Teooria: Peatükk X")
- ✅ Step-by-step hands-on instructions

**Integration:**
- ✅ No duplication (theory = concepts, labs = practice)
- ✅ Clear learning path (theory → understand WHY → labs → learn HOW)
- ✅ Bidirectional references (theory ↔ labs)

---

## 📊 Current Progress

**Theory chapters revised:**
- ✅ Chapter 15: GitHub Actions (118 → 66 blocks, added Lab 5 references)

**Theory chapters needing revision:**
- ❌ Chapter 7: Docker Compose (120 blocks → should move complete YAML to Lab 2)
- ❌ Chapters 10-13: Kubernetes (78-112 blocks → should move complete manifests to Lab 3)
- ❌ Chapters 2, 3, 6, 8, 14, 16-20, 20A (all need EXPLANATORY FOCUS + Lab references)

**Lab exercises needing theory references:**
- ❌ All 33 exercises (none have theory references yet)

---

**Next action:** Should we add theory references to labs, or continue revising theory chapters first?
