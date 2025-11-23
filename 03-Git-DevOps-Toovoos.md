# Peatükk 3: Git DevOps Töövoos

**Kestus:** 2 tundi
**Eeldused:** Peatükk 1-2 (VPS, Linux basics)
**Eesmärk:** Mõista Git'i kasutamist DevOps administraatori vaatenurgast

---

## Õpieesmärgid

Selle peatüki lõpuks oskad:
- Kasutada Git'i Infrastructure as Code (IaC) failide haldamiseks
- Mõista GitOps workflow'i DevOps kontekstis
- Hallata secrets'e turvaliselt (mitte commit'ida)
- Kloonida, commit'ida ja push'ida konfiguratsioonifaile

---

## 3.1 Miks Git DevOps'is?

### Git ≠ Ainult Arendajatele

**Tavapärane arusaam:**
> "Git on arendajate tööriist source code'i jaoks."

**DevOps reaalsus:**
> "Git on Infrastructure as Code'i tööriist. Ma versiooni kontrollin Kubernetes manifest'e, Dockerfile'e, CI/CD pipeline'e, nginx konfiguratsioone."

---

### Infrastructure as Code (IaC)

**Traditsiooniline lähenemine (käsitsi):**
```
DevOps administraator:
1. SSH server'isse
2. vim /etc/nginx/nginx.conf
3. Muuda konfiguratsioon
4. systemctl reload nginx

Probleem:
- Ei ole ajalugu (kes muutis? millal? miks?)
- Ei saa tagasi võtta (undo puudub)
- Ei ole backup'i (ketas crashib → config kaob)
- Ei ole replikeeritav (teine server vajab sama konfigi)
```

**IaC lähenemine (Git):**
```
DevOps administraator:
1. git clone infrastructure-repo
2. vim nginx/nginx.conf
3. git commit -m "Increase worker_processes to 4"
4. git push

CI/CD:
→ Automatic deploy nginx.conf serverisse
→ systemctl reload nginx

Plussid:
✅ Ajalugu (git log - kõik muudatused)
✅ Undo (git revert)
✅ Backup (Git server = backup)
✅ Replikeeritav (git clone → sama config kõigis serveris)
```

**DevOps perspektive:**
> "If it's not in Git, it doesn't exist."

---

### GitOps - Deklaratiivne Infrastruktuur

**GitOps põhimõte:**
- Git repository on "single source of truth"
- Desired state on Git'is (Kubernetes manifests, Helm charts)
- Automated tools (ArgoCD, Flux) synchronize actual state → desired state

**Näide:**

```yaml
# Git repository: kubernetes/deployments/backend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3  # DESIRED STATE
```

```
Actual state: 2 replicas running

GitOps tool (ArgoCD):
→ Detect drift (2 ≠ 3)
→ Apply change (create 1 more replica)
→ Actual state = Desired state
```

**Miks see DevOps'ile oluline?**
1. **Auditability:** Kõik muudatused Git commit'ides (audit trail)
2. **Rollback:** `git revert` → automatic rollback production'is
3. **Disaster recovery:** Serverid hävivad → `git clone` → restore kõik

📖 **Praktika:** Labor 5, Harjutus 4 - GitOps workflow ArgoCD'ga

---

## 3.2 Git Põhikäsud DevOps Kontekstis

### Repository Kloneerimine

**Stsenaarium:** Ühine infrastruktuuri repository

```bash
# Clone koolituskava repository
git clone https://github.com/your-org/hostinger.git
cd hostinger
```

**Mis juhtus?**
1. Git laadis alla kogu repository history
2. Lõi kohaliku koopia (working directory)
3. Seadistas remote tracking (`origin`)

**DevOps praktikas:**
```bash
# Clone infrastructure repository
git clone git@github.com:company/infrastructure.git
cd infrastructure

# Repository struktuur:
infrastructure/
├── kubernetes/
│   ├── deployments/
│   ├── services/
│   └── ingress/
├── docker/
│   ├── backend-nodejs/
│   └── frontend/
├── nginx/
│   └── nginx.conf
└── scripts/
    └── backup.sh
```

---

### Muudatuste Tegemine ja Commit'imine

**DevOps workflow:**

```bash
# 1. Muuda konfiguratsioonifaili
vim kubernetes/deployments/backend.yaml

# Muudan replicas: 3 → 5 (scale up)

# 2. Vaata, mis muutus
git diff

# 3. Vaata staatust
git status

# 4. Lisa muudatus staging area'sse
git add kubernetes/deployments/backend.yaml

# 5. Commit koos kirjeldava sõnumiga
git commit -m "Scale backend to 5 replicas for Black Friday traffic"

# 6. Push remote repository'sse
git push origin main
```

**Commit message best practices:**

❌ **Halb:**
```bash
git commit -m "fix"
git commit -m "update"
git commit -m "changes"
```

✅ **Hea:**
```bash
git commit -m "Increase backend replicas from 3 to 5 for high traffic"
git commit -m "Fix nginx worker_processes: 2 → 4 (CPU bottleneck)"
git commit -m "Add PostgreSQL backup cronjob - runs daily at 02:00"
```

**Miks hea commit message oluline?**
- 6 kuud hiljem: "Miks me muutsime replicas 5'le?" → git log näitab
- Incident troubleshooting: "Millal me viimati nginx'i muutsime?" → git log

---

### Remote Repository Uuendamine

```bash
# Lae alla viimased muudatused
git pull origin main
```

**Mis juhtub?**
1. `git fetch origin` - Lae alla remote muudatused
2. `git merge origin/main` - Merge local branch'iga

**DevOps praktikas:**

```
Kaks administraatorit töötavad samaaegselt:

Admin A: muudab backend.yaml → git push
Admin B: muudab frontend.yaml

Admin B:
git pull  # Laeb Admin A muudatused
→ Auto-merge OK (erinevad failid)
git push  # Push oma muudatused
```

**Merge conflict (harv IaC'is):**
```
Admin A ja Admin B muudavad SAMA faili sama kohta:

Admin A: replicas: 5
Admin B: replicas: 3

git pull → CONFLICT!

Resolve manually:
vim backend.yaml
# Vali õige väärtus (5 või 3 või 4)
git add backend.yaml
git commit -m "Resolve conflict: keep replicas=5"
git push
```

---

## 3.3 Branch'id ja Merge

### Miks Branch'id DevOps'is?

**Stsenaarium:**
```
Production infrastruktuur töötab (main branch).

DevOps administraator tahab testida UUSI Kubernetes konfiguratsioone.

Probleem:
- Kui commit'in otse main'i → production muutub KOHE
- Kui test ebaõnnestub → production on katki

Lahendus: BRANCH
```

---

### Branch Workflow

```bash
# 1. Loo uus branch
git checkout -b feature/prometheus-monitoring

# 2. Tee muudatused
vim kubernetes/monitoring/prometheus.yaml

# 3. Commit
git add .
git commit -m "Add Prometheus monitoring setup"

# 4. Push branch'i
git push origin feature/prometheus-monitoring

# 5. Test branch'il (staging environment)
kubectl apply -f kubernetes/monitoring/prometheus.yaml --namespace=staging

# 6. Kui töötab, merge main'i
git checkout main
git merge feature/prometheus-monitoring
git push origin main

# 7. Delete branch
git branch -d feature/prometheus-monitoring
```

**DevOps perspektive:**

```
Branches:
- main → Production (töötav, stabiilne)
- staging → Testing (uued features)
- feature/* → Development (eksperimentaalsed muudatused)

Workflow:
feature/new-feature → staging → main (production)
```

---

### GitFlow vs Trunk-Based Development

**GitFlow (complex):**
- main, develop, feature/*, hotfix/*, release/*
- Sobib suurele organisatsioonile

**Trunk-Based (DevOps soovitab):**
- Ainult main + lühiajalised feature branch'id
- Fast feedback, continuous deployment
- Kasutatakse GitOps'is (ArgoCD, Flux)

**DevOps best practice:**
> "Keep it simple. Main branch = production. Feature branches elavad max 1-2 päeva. Merge kiiresti."

---

## 3.4 .gitignore ja Secrets Haldamine

### Miks .gitignore Kriit

iline?

**Suurim DevOps turvarisk:**
```bash
# .env fail (SECRETS!)
DB_PASSWORD=super-secret-password-123
JWT_SECRET=my-jwt-secret-key
API_KEY=sk-1234567890abcdef
```

**Kui commit'id .env faili Git'i:**
```bash
git add .env
git commit -m "Add environment config"
git push

→ SECRETS ON AVALIKUD! (GitHub public repo)
→ SECURITY BREACH!
→ Attackers saavad DB juurdepääsu
```

**Lahendus: .gitignore**

---

### .gitignore Konfiguratsioon

**`/root/.gitignore`:**
```
# Environment variables (SECRETS!)
.env
.env.local
.env.production

# Credentials
credentials.json
secrets.yaml

# Private keys
*.pem
*.key
id_rsa
id_ed25519

# Database dumps (võivad sisaldada sensitive data)
*.sql
*.dump

# Logs (võivad sisaldada API keys)
*.log

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
```

**Kasutamine:**
```bash
# 1. Loo .gitignore
echo ".env" >> .gitignore
echo "credentials.json" >> .gitignore

# 2. Commit .gitignore
git add .gitignore
git commit -m "Add .gitignore for secrets"

# 3. Nüüd .env ei commit'idu
git add .
git commit -m "Add configs"
# .env on ignored → ei lähe commit'i
```

---

### Secrets Management DevOps'is

**VALE lähenemine:**
```yaml
# kubernetes/deployments/backend.yaml (GIT)
env:
  - name: DB_PASSWORD
    value: "super-secret-123"  # ❌ HARDCODED SECRET!
```

**ÕIGE lähenemine:**

**1. Environment-specific .env failid (ei commit'ita):**
```bash
# .env.production (SERVER'IS, mitte Git'is)
DB_PASSWORD=prod-secret-xyz
```

**2. Kubernetes Secrets (base64 encoded, mitte Git'is):**
```yaml
# Create secret imperatively (not in Git)
kubectl create secret generic db-secret \
  --from-literal=password=super-secret-123

# Use in deployment (Git)
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password
```

**3. External Secrets Manager:**
- Vault (HashiCorp)
- AWS Secrets Manager
- Azure Key Vault
- Sealed Secrets (Kubernetes)

**DevOps põhimõte:**
> "Secrets NEVER in Git. Secrets in secret management systems (Vault, K8s Secrets)."

📖 **Praktika:** Labor 3, Harjutus 4 - Kubernetes Secrets management

---

## 3.5 Git History ja Troubleshooting

### git log - Ajalugu Vaatamine

```bash
# Vaata commit history
git log

# Compact view
git log --oneline

# Viimased 10 commit'i
git log -n 10

# Specific file history
git log -- kubernetes/deployments/backend.yaml

# Author filter
git log --author="John Doe"

# Date range
git log --since="2025-01-01" --until="2025-01-23"
```

**DevOps kasutus:**

```bash
# "Millal me viimati backend'i skaalesime?"
git log --oneline -- kubernetes/deployments/backend.yaml

# Output:
# a1b2c3d Scale backend to 5 replicas
# d4e5f6g Scale backend to 3 replicas
# g7h8i9j Initial backend deployment
```

---

### git diff - Muudatuste Võrdlemine

```bash
# Vaata unstaged changes
git diff

# Vaata staged changes
git diff --staged

# Võrdle kahe commit'i vahel
git diff a1b2c3d d4e5f6g

# Võrdle specific file
git diff HEAD~1 HEAD -- nginx/nginx.conf
```

**DevOps troubleshooting:**

```
Production'is on error pärast viimast deploy'i.

# 1. Vaata, mis muutus
git diff HEAD~1 HEAD

# 2. Leia probleemsed muudatused
# Näiteks: worker_processes muutus 4 → 2

# 3. Rollback (revert)
git revert HEAD
git push

# 4. Deploy uuesti (rollback'd config)
```

---

### git revert vs git reset

**git revert (SAFE - DevOps soovitab):**
```bash
# Creates NEW commit that undoes changes
git revert a1b2c3d
git push

# History:
# a1b2c3d Scale backend to 5 replicas
# z9y8x7w Revert "Scale backend to 5 replicas"  ← NEW COMMIT
```

**Plussid:**
- Ei kustuta history
- Safe collaboration (teised näevad revert'i)
- Audit trail (näeme, et rollback tehti)

---

**git reset (DANGEROUS - ära kasuta production'is!):**
```bash
# Deletes commit history (kui push --force)
git reset --hard HEAD~1
git push --force  # ❌ NEVER in shared branches!

# History:
# (commit a1b2c3d on DELETED - keegi ei tea, et see oli)
```

**Miinused:**
- Kaotad history (audit trail puudub)
- Teised adminid kaotatavad (their history conflicts)

**DevOps rule:**
> "Never `git push --force` to main/production. Always use `git revert` for rollbacks."

---

## 3.6 Git DevOps Töövoog - Praktiline Näide

### Stsenaarium: Nginx Konfiguratsiooni Muutmine

**Algolukord:**
```
Production Nginx serveerib 1000 requests/sec.
Worker processes: 2
```

**Probleem:**
```
CPU utilization: 95%
Response time: 500ms (peaks)

Lahendus: Increase worker_processes 2 → 4
```

---

**DevOps workflow Git'iga:**

```bash
# 1. Clone infrastructure repo
git clone git@github.com:company/infrastructure.git
cd infrastructure

# 2. Create feature branch
git checkout -b fix/nginx-worker-processes

# 3. Muuda konfiguratsioon
vim nginx/nginx.conf

# ENNE:
# worker_processes 2;

# PÄRAST:
# worker_processes 4;

# 4. Vaata diff
git diff
# Näitab: -worker_processes 2; / +worker_processes 4;

# 5. Commit
git add nginx/nginx.conf
git commit -m "Increase nginx worker_processes to 4 (CPU bottleneck fix)

Current: 2 workers, 95% CPU utilization
Target: 4 workers (match CPU core count)
Expected: <60% CPU utilization, <200ms response time"

# 6. Push branch
git push origin fix/nginx-worker-processes

# 7. Test staging environment
scp nginx/nginx.conf staging-server:/etc/nginx/
ssh staging-server "sudo systemctl reload nginx"
# Test → OK

# 8. Merge to main
git checkout main
git merge fix/nginx-worker-processes
git push origin main

# 9. CI/CD automatic deploy
# ArgoCD/Flux detects change → deploys to production

# 10. Verify production
curl https://api.example.com/health
# Response time: 150ms ✅

# 11. Cleanup branch
git branch -d fix/nginx-worker-processes
git push origin --delete fix/nginx-worker-processes
```

**Tulemus:**
- ✅ CPU utilization: 95% → 55%
- ✅ Response time: 500ms → 150ms
- ✅ Full audit trail (git log)
- ✅ Rollback võimalus (git revert)

---

## 3.7 Git Collaboration DevOps Meeskonnas

### Multiple Admins - Conflict Resolution

**Stsenaarium:**

```
Admin A: Skaalerib backend'i 5 replica'le
Admin B: Muudab backend image tag'i v1.2 → v1.3

Mõlemad töötavad samaaegselt SAMA faili kallal.
```

**Workflow:**

```bash
# Admin A:
git pull
vim kubernetes/deployments/backend.yaml  # replicas: 3 → 5
git commit -m "Scale backend to 5 replicas"
git push  # ✅ SUCCESS

# Admin B (30 sek hiljem):
vim kubernetes/deployments/backend.yaml  # image: v1.2 → v1.3
git commit -m "Update backend to v1.3"
git push  # ❌ ERROR: Updates were rejected

# Lahendus:
git pull  # Fetch Admin A changes

# Kui AUTO-MERGE töötab (erinevad read):
# → Git mergib automaatselt
git push  # ✅ SUCCESS

# Kui CONFLICT (samad read):
vim kubernetes/deployments/backend.yaml
# Resolve manually:
# Choose replicas: 5 (Admin A)
# Choose image: v1.3 (Admin B)

git add kubernetes/deployments/backend.yaml
git commit -m "Merge: keep replicas=5 and update image to v1.3"
git push  # ✅ SUCCESS
```

---

### Code Review DevOps'is (Pull Requests)

**MÄRKUS:** Pull requests on ARENDAJATE töövoog, mitte DevOps administraatori põhitöö.

**Kuid, DevOps võib kasutada PR'e:**
- Major infrastructure changes (Kubernetes cluster upgrade)
- Security-sensitive changes (firewall rules, RBAC)
- Peer review (teine admin kontrollib)

**Lihtne workflow:**
```bash
# 1. Create branch
git checkout -b feature/new-firewall-rules

# 2. Commit changes
git commit -m "Add firewall rules for port 443"
git push origin feature/new-firewall-rules

# 3. Open Pull Request (GitHub/GitLab)
# Title: "Add firewall rules for HTTPS traffic"
# Description: "Opens port 443 for Nginx HTTPS. Tested on staging."

# 4. Request review from senior admin
# Senior admin reviews → Approves

# 5. Merge PR
# Click "Merge" button

# 6. Delete branch
```

**DevOps praktikas:**
- Small changes → direct commit to main (fast iteration)
- Large changes → Pull Request (peer review)

---

## 3.8 Git Best Practices DevOps'is

### 1. Commit Sageli, Push Sageli

❌ **Halb:**
```
1 päev töö → 1 suur commit (50 faili muudetud)
git commit -m "Update everything"
```

✅ **Hea:**
```
Iga loogiline muudatus → eraldi commit:
- git commit -m "Add Prometheus monitoring"
- git commit -m "Update backend replicas to 5"
- git commit -m "Fix nginx worker_processes"
```

**Miks?**
- Rollback on lihtsam (revert üks konkreetne muudatus)
- History on loetav (git log näitab täpselt, mis muutus)

---

### 2. Descriptive Commit Messages

**Template:**
```
[Category] Short description (50 chars max)

Longer explanation of WHY (not what):
- What problem does this solve?
- What is the expected impact?

Issue: #123 (kui on issue tracker)
```

**Näited:**

```bash
git commit -m "[K8s] Scale backend to 5 replicas for Black Friday

Current: 3 replicas, 80% CPU under peak load
Target: 5 replicas to handle 2x traffic spike
Expected: <50% CPU during Black Friday sales

Issue: #456"
```

---

### 3. .gitignore - Secrets ja Junk Failid

**Must-have .gitignore items:**
```
# Secrets
.env*
credentials.json
*.pem
*.key

# Logs
*.log

# OS junk
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
```

---

### 4. Branch Nimetamine

**Conventions:**
```
feature/description  - Uued funktsioonid
fix/description      - Bug fixes
hotfix/description   - Critical production fixes
chore/description    - Maintenance (dependency updates)
```

**Näited:**
```
feature/prometheus-monitoring
fix/nginx-worker-processes
hotfix/critical-security-patch
chore/update-kubernetes-1-29
```

---

### 5. Git History Hygiene

**DO:**
- ✅ Commit sageli
- ✅ Descriptive commit messages
- ✅ Use `git revert` rollback'ideks

**DON'T:**
- ❌ `git push --force` to main/production
- ❌ Commit secrets (.env, *.pem)
- ❌ Rewrite shared history (git reset + force push)

---

## Kokkuvõte

### Mida sa õppisid?

**Git DevOps kontekstis:**
- Infrastructure as Code (IaC) - konfiguratsioonid Git'is
- GitOps - Git kui single source of truth
- Version control for manifests, Dockerfiles, configs

**Põhikäsud:**
```bash
git clone    # Clone infrastructure repo
git pull     # Fetch viimased muudatused
git add      # Stage changes
git commit   # Commit koos kirjeldava sõnumiga
git push     # Push remote'i
git log      # Vaata history
git diff     # Võrdle muudatusi
git revert   # Rollback (SAFE)
```

**Secrets management:**
- .gitignore - Secrets EI LÄHE Git'i
- Kubernetes Secrets, Vault - Secret storage
- Never commit .env, *.pem, credentials.json

**Collaboration:**
- Branches - Isolate changes, test enne merge'i
- Pull Requests - Peer review (optional)
- Conflict resolution - Merge conflicts manuaalselt

---

### DevOps Administraatori Vaatenurk

**Iga päev:**
```bash
git pull                    # Sync local repo
git commit -m "..."         # Commit muudatused
git push                    # Deploy via GitOps
```

**Troubleshooting:**
```bash
git log --oneline           # Millal viimati muudeti?
git diff HEAD~1 HEAD        # Mis muutus?
git revert HEAD             # Rollback viimast muudatust
```

**Security:**
```bash
# Check .gitignore
cat .gitignore

# Check for secrets (NEVER commit these!)
git status | grep -E ".env|credentials|*.pem"
```

---

### Järgmised Sammud

**Peatükk 4:** Docker Põhimõtted (konteinerite maailm!)
**Peatükk 7:** Docker Compose (multi-container orchestration)

---

**Kestus kokku:** ~2 tundi teooriat + praktilised harjutused labides

📖 **Praktika:**
- Labor 0, Harjutus 7 - Git basics (clone, commit, push)
- Labor 5, Harjutus 4 - GitOps workflow ArgoCD'ga
