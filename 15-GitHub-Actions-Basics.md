# Peatükk 15: GitHub Actions Basics

**Kestus:** 3 tundi
**Eeldused:** Peatükk 3 (Git), Peatükk 4-7 (Docker)
**Eesmärk:** Mõista CI/CD filosoofiat ja GitHub Actions arhitektuuri

---

## Õpieesmärgid

Selle peatüki lõpuks mõistad:
- **MIKS** CI/CD on kriitiline DevOps'is
- **KUIDAS** GitHub Actions arhitektuur toimib
- **MILLAL** kasutada erinevaid triggers ja workflow patterns
- **Kuidas** hallata secrets ja environment variables turvaliselt
- **Erinevusi** GitHub Actions vs GitLab CI vs Bamboo

**TÄHTIS:** See peatükk keskendub KONTSEPTIDELE ja DISAINI OTSUSTELE. Täielikke workflow näiteid harjutad **Lab 5: CI/CD Lab'is**.

---

## 15.1 Miks CI/CD?

### Probleem: Manual Deployment

**Traditional workflow:**

```
Developer:
1. Write code
2. Test locally (maybe...)
3. Build Docker image manually
4. Push image to registry
5. SSH to server
6. docker pull new image
7. docker stop old container
8. docker run new container
9. Hope everything works...

Problems:
- Manual steps → error-prone
- Inconsistent (different developers do it differently)
- No testing before deploy
- Slow (30 minutes per deploy)
- No rollback strategy
- Works on my machine™
```

**Miks see on OHTLIK?**

1. **Human error:** Käsitsi deployment → 1 kord 10-st läheb midagi valesti
2. **No testing:** Kui kohalikud testid ei jooksnud, deploy läheb samuti läbi
3. **No audit trail:** Kes deploy'das? Millal? Mida muudeti? → Ei tea
4. **Downtime:** Manual deployment võtab 15-30 minutit (service down)
5. **Fear of deployment:** "Ärge deploy'dage reedeti!" (kui midagi läheb valesti, veedate nädalavahetuse parandamisega)

---

### Solution: CI/CD Pipeline

**Continuous Integration (CI):**
> Automatically build and test code on **every commit**

**MIKS see on revolutsiooniline?**
- Bugid avastakse 5 minutit pärast commit'i (mitte 2 nädalat hiljem)
- Merge conflicts avastakse koheselt
- Code quality (linter) jõustatakse automaatselt
- Testid **peavad** jooksma (ei saa skipida)

**Continuous Deployment (CD):**
> Automatically deploy tested code to production

**MIKS see on revolutsiooniline?**
- Deploy võtab 5 minutit (mitte 30)
- Zero downtime (rolling update)
- Rollback on 1-click (kui midagi läheb valesti)
- Deploy'da võib 10x päevas (mitte 1x kuus)

---

**GitHub Actions workflow:**

```
1. Developer: git push
   ↓
2. GitHub Actions (automatic):
   - Checkout code
   - Run linter (code quality)
   - Run tests
   - Build Docker image
   - Push to Docker Hub
   - Deploy to Kubernetes
   ↓
3. Production updated (5 minutes, zero human intervention)
```

**DevOps benefits:**
- ✅ **Consistency:** Same process every time (no "oops, I forgot to run tests")
- ✅ **Speed:** Automated → 10x faster (5 min vs 30 min)
- ✅ **Quality:** Tests always run (can't skip)
- ✅ **Confidence:** If tests pass, deploy is safe
- ✅ **Audit trail:** All deployments logged (who, what, when)
- ✅ **Rollback:** Previous version is 1-click away

---

### Reaalne Näide: Startup vs Enterprise

**Startup ilma CI/CD:**
```
- 5 developers
- Manual deployment: 30 min
- Deploy 2x päevas
- Developer aeg deployment'ile: 5h nädalas
- Bugs production'is: 3-4 nädalas (avastatud hilja)
```

**Startup CI/CD'ga:**
```
- 5 developers
- Automated deployment: 5 min
- Deploy 10x päevas (ei ole enam "big scary event")
- Developer aeg deployment'ile: 0h (automatic)
- Bugs production'is: 0-1 nädalas (caught by CI)
```

**Kokkuvõte:** CI/CD võimaldab väiksel meeskonnal liikuda KIIREMINI ja TURVALISEMALT.

---

## 15.2 GitHub Actions Architecture

### MIKS GitHub Actions?

**Alternatiivid:**
1. **Jenkins:** Self-hosted, paindlik, aga complex setup
2. **GitLab CI/CD:** GitLab'i native, hea enterprise'ile
3. **Travis CI:** Legacy, kaotab turuosa
4. **CircleCI:** Cloud-native, hea, aga kallis

**GitHub Actions EELISED:**
- ✅ **Native GitHub integration:** Zero setup (juba GitHubis)
- ✅ **Free tier:** 2,000 minutes/month (public repos: unlimited)
- ✅ **Marketplace:** 10,000+ pre-built actions
- ✅ **Simple YAML:** Lihtne õppida
- ✅ **Community:** Suur kasutajaskond, palju näiteid

**GitHub Actions PUUDUSED:**
- ❌ **Vendor lock-in:** Workflow'de ei saa lihtsalt teise platvormi viia
- ❌ **Limited free tier:** 2,000 min/month (enterprise peab maksma)
- ❌ **GitHub-centric:** Kui repo on GitLab'is, ei saa kasutada

**MILLAL kasutada GitHub Actions?**
- ✅ Repo on GitHubis
- ✅ Small/medium projects (free tier piisab)
- ✅ Open-source (unlimited minutes)

**MILLAL kasutada GitLab CI?**
- ✅ Repo on GitLabis
- ✅ Enterprise (better pricing, self-hosted)
- ✅ Need complex pipelines (better features)

---

### Components

**Workflow:**
- YAML file in `.github/workflows/`
- Defines automation (build, test, deploy)

**Trigger (Event):**
- **MIKS see on oluline:** Määrab, MILLAL workflow käivitub
- **Common triggers:** push, pull_request, schedule, manual

**Job:**
- **MIKS multiple jobs:** Parallel execution (tests + build samaaegselt)
- **Trade-off:** Rohkem jobs = kiirem, aga complex dependencies

**Step:**
- Individual task (checkout code, run command, use action)
- **MIKS atomic steps:** Debug on lihtsam (näed, kus täpselt fail)

**Runner:**
- **Machine that executes workflow**
- **MIKS GitHub-hosted:** Zero maintenance, clean environment
- **MIKS self-hosted:** Cost savings, custom hardware (GPU)

**Action:**
- **Reusable task**
- **MIKS kasutada actions:** Don't reinvent the wheel (10,000+ marketplace)

---

### Architecture Diagram

```
GitHub Repository:
  .github/workflows/ci.yml

Trigger: git push
  ↓
GitHub Actions Service:
  → Allocate runner (Ubuntu VM)
  → Checkout code
  → Execute jobs

Runner (GitHub-hosted):
  - Ubuntu 22.04
  - 2 CPU cores
  - 7 GB RAM
  - 14 GB SSD

Jobs execute:
  → Build Docker image
  → Run tests
  → Push to registry
  → Deploy to Kubernetes

Result:
  → Success ✅ or Failure ❌
  → Notification (email, Slack)
```

---

## 15.3 Workflow YAML Structure

### Minimal Workflow - Concept

**MIKS YAML?**
- ✅ Human-readable (inimene saab aru)
- ✅ Git-friendly (version control, code review)
- ✅ Declarative (kirjeldad MIDA, mitte KUIDAS)

**Minimal näide (kontsept):**

```yaml
# .github/workflows/hello.yml
name: Hello World

on: [push]  # Trigger

jobs:
  greet:
    runs-on: ubuntu-latest
    steps:
    - name: Say hello
      run: echo "Hello, World!"
```

**Mida see teeb:**
1. Push to any branch → trigger workflow
2. GitHub allocates ubuntu-latest runner
3. Runner executes: `echo "Hello, World!"`
4. Log output visible in GitHub UI

**TÄHTIS:** See on MINIMAALNE näide kontsepti mõistmiseks. Praktilisi workflow'e harjutad **Lab 5'is**.

---

### Triggers - MILLAL Kasutada?

**Design decision:** Trigger määrab, KUI TIHTI ja MILLAL workflow jookseb.

**1. `on: push` - Continuous Integration**

**MILLAL kasutada:**
- ✅ Main branch protection (tests enne merge'i)
- ✅ Automatic build on main branch
- ✅ Hotfix deployment

**MIKS see on hea:**
- Immediate feedback (developer teab 5 min jooksul, kas build läbis)
- Prevents broken main branch

**Trade-off:**
- ⚠️ Konsumeerib runner minutes (iga push)
- ⚠️ Slow repo (100 pushes/day) = high cost

---

**2. `on: pull_request` - Code Review Gate**

**MILLAL kasutada:**
- ✅ Require tests before merge
- ✅ Security scanning
- ✅ Code quality checks (linter)

**MIKS see on hea:**
- Broken code never reaches main (caught in PR)
- Code review'daja näeb, et testid läbisid

**Trade-off:**
- ⚠️ Slower feedback (peab ootama workflow completion)

---

**3. `on: schedule` - Nightly Builds**

**MILLAL kasutada:**
- ✅ Security scanning (daily scan)
- ✅ Dependency updates (check for outdated packages)
- ✅ Report generation (nightly metrics)

**MIKS see on hea:**
- Avastab probleeme, mis tekivad ajas (dependencies deprecated)
- Ei blokeeri development workflow'd

**Trade-off:**
- ⚠️ Slow feedback (probleemid avastatud 12-24h hiljem)

---

**4. `on: workflow_dispatch` - Manual Deployment**

**MILLAL kasutada:**
- ✅ Production deployment (safety gate - human approval)
- ✅ Hotfix deployment (urgent manual trigger)
- ✅ Testing (trigger workflow manually for debugging)

**MIKS see on hea:**
- Human control (ei deploy'da automaatselt production'i)
- Flexibility (võid valida parameetreid)

**Trade-off:**
- ⚠️ Slower (peab käsitsi trigger'dama)
- ⚠️ Requires human (ei saa täielikult automatiseerida)

---

**Design decision: Kui TIHTI deploy'da?**

**Conservative approach:**
```
- PR → run tests (automatic)
- Push to main → build image (automatic)
- Deploy to production → manual approval (workflow_dispatch)
```

**Aggressive approach (Continuous Deployment):**
```
- PR → run tests (automatic)
- Merge to main → deploy to production (automatic, 0 human intervention)
```

**MIKS conservative?**
- ✅ Safety (human approval before production)
- ❌ Slower (peab ootama approval)

**MIKS aggressive?**
- ✅ Speed (production updated 5 min pärast merge)
- ❌ Risk (kui tests ei kata kõike, broken code → production)

**DevOps best practice:** Start conservative, move to aggressive kui test coverage > 80%.

---

## 15.4 Secrets Management - MIKS See On Kriitiline?

### Probleem: Hardcoded Secrets

**❌ NEVER do this:**

```yaml
# BAD - secret hardcoded in repo
env:
  DATABASE_PASSWORD: "mypassword123"
  DOCKER_PASSWORD: "hunter2"
```

**MIKS see on OHTLIK?**
- ❌ Secrets on Git history's (IGAVESTI)
- ❌ Anyone with repo access näeb secrets
- ❌ Leaked secrets → security breach (database compromised)

**Reaalne näide:** AWS credentials leakitud GitHubis → $10,000 bitcoin mining bill järgmisel kuul.

---

### Solution: GitHub Secrets

**KUIDAS see toimib:**
1. Secrets stored encrypted in GitHub (not in repo)
2. Workflow saab access secrets'ile runtime'is
3. Secrets never logged (masked in output)

**Minimal näide (kontsept):**

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Kubernetes
        env:
          KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
        run: kubectl apply -f deployment.yaml
```

**MIKS see on parem?**
- ✅ Secrets NOT in Git history
- ✅ Access control (ainult repo admins saavad secrets muuta)
- ✅ Masked in logs (ei kuvata console output'is)

---

### Secrets Best Practices

**1. MIKS use environment-specific secrets?**

```
Environments:
- development → secrets.DEV_KUBE_CONFIG
- staging → secrets.STAGING_KUBE_CONFIG
- production → secrets.PROD_KUBE_CONFIG
```

**MIKS see on oluline:**
- ✅ Prevents accidental production deployment (dev secrets ei tööta prod'is)
- ✅ Principle of least privilege (dev'idel ei ole prod secrets)

---

**2. MIKS rotate secrets regularly?**

**DevOps best practice:** Rotate secrets every 90 days (või koheselt kui developer lahkub).

**MIKS?**
- ✅ Compromised secret has limited lifetime
- ✅ Reduces blast radius (kui secret leaks, it expires soon)

---

**3. MIKS use OIDC instead of long-lived tokens?**

**Problem: Long-lived tokens**
- Token generated → valid for 1 year
- If leaked → attacker has 1 year access

**Solution: OIDC (OpenID Connect)**
- GitHub generates short-lived token (valid 1 hour)
- If leaked → attacker has 1 hour window (minimal damage)

**MILLAL kasutada OIDC?**
- ✅ AWS, Azure, GCP deployment (native support)
- ✅ Security-critical applications

**MILLAL kasutada long-lived tokens?**
- ✅ Simple projects (OIDC setup complex)
- ✅ Self-hosted runners (OIDC not always supported)

---

## 15.5 Multi-Job Workflows - MIKS Paralleliseerimine?

### Probleem: Sequential Pipeline

**Ilma paralleliseerimiseta:**

```
Step 1: Lint (30 seconds)
  ↓
Step 2: Unit tests (3 minutes)
  ↓
Step 3: Integration tests (5 minutes)
  ↓
Step 4: Build Docker image (2 minutes)
  ↓
Total: 10.5 minutes
```

**MIKS see on AEGLANE?**
- Tests ei sõltu üksteisest (unit tests ei vaja integration tests tulemust)
- Build ei vaja tests tulemust (võib paralleelselt joosta)

---

### Solution: Parallel Jobs

**Concept (parallel execution):**

```
git push →

Job 1: Lint (30s)     \
Job 2: Unit tests (3m) → Job 4: Deploy (if all pass)
Job 3: Integration (5m)/

Total: 5 minutes (saved 5.5 minutes!)
```

**MIKS paralleliseerimine on hea?**
- ✅ Faster feedback (5 min vs 10.5 min)
- ✅ Better resource usage (3 runners samaaegselt vs 1 runner sequentially)

**Trade-off:**
- ⚠️ Consumes more runner minutes (3 runners × 5 min = 15 runner-minutes vs 10.5 sequential)
- ⚠️ More complex (dependencies between jobs)

---

### Design Decision: Parallel vs Sequential?

**MILLAL parallel?**
- ✅ Jobs sõltumatud (testid ei vaja üksteist)
- ✅ Speed critical (developer waiting for feedback)
- ✅ Unlimited runner minutes (free tier piisab)

**MILLAL sequential?**
- ✅ Jobs dependent (build vajab test results)
- ✅ Limited runner minutes (free tier ületatud)
- ✅ Simple pipeline (complexity not worth it)

**DevOps best practice:**
- Parallel: lint, unit tests, security scan (sõltumatud)
- Sequential: tests → build → deploy (dependencies)

---

**Minimal näide (kontsept):**

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    needs: [lint, test]  # Wait for lint AND test
    runs-on: ubuntu-latest
    steps:
      - run: kubectl apply -f deployment.yaml
```

**Explanation:**
- `lint` and `test` run in parallel (no dependencies)
- `deploy` waits for both (needs: [lint, test])

**TÄHTIS:** Täielikke multi-job workflow näiteid harjutad **Lab 5'is**.

---

## 15.6 Docker Build Automation - Concepts

### MIKS Automated Docker Builds?

**Manual Docker build:**

```bash
# Developer käsitsi:
docker build -t myapp:latest .
docker tag myapp:latest myusername/myapp:v1.2.3
docker push myusername/myapp:v1.2.3
docker push myusername/myapp:latest
```

**MIKS see on PROBLEEM?**
- ❌ Developer unustab tagida version'iga (ainult `latest`)
- ❌ Inconsistent tags (üks developer kasutab `v1.2.3`, teine `1.2.3`)
- ❌ Slow (developer peab ootama build'i - 5-10 min)
- ❌ No audit trail (kes buildinud selle image?)

---

### Solution: Automated Builds in CI/CD

**Workflow automates:**
1. **Build:** Docker image (every push to main)
2. **Tag:** Versioned (git commit SHA + semver tag)
3. **Push:** To Docker Hub/registry
4. **Audit:** Logged in GitHub Actions

**MIKS see on parem?**
- ✅ Consistent tagging (always git SHA)
- ✅ Parallel builds (ei blokeeri developer'it)
- ✅ Audit trail (GitHub Actions log shows exact build)
- ✅ Reproducible (sama commit SHA → sama image)

---

### Design Decisions

**1. Tagging strategy - MIKS See On Oluline?**

**Option A: Only `latest`**
```
myapp:latest (always overwritten)
```

**MIKS BAD?**
- ❌ No versioning (ei tea, milline version on production'is)
- ❌ Rollback impossible (previous version kadunud)

---

**Option B: Git SHA tagging**
```
myapp:abc1234567 (git commit SHA)
myapp:latest
```

**MIKS GOOD?**
- ✅ Immutable (SHA never changes)
- ✅ Rollback possible (deploy previous SHA)
- ✅ Audit trail (SHA → git commit → code changes)

---

**Option C: Semantic versioning**
```
myapp:v1.2.3
myapp:v1.2
myapp:v1
myapp:latest
```

**MIKS GOOD?**
- ✅ Human-readable (v1.2.3 vs abc1234567)
- ✅ Semver semantics (v1.2.3 → v1.2.4 = patch, v1.3.0 = minor, v2.0.0 = breaking)

**MIKS COMPLEX?**
- ⚠️ Requires version bumping (peab manually uuendama version number)
- ⚠️ CI/CD peab parsima semver tags

**DevOps best practice:** Use **git SHA + semver** (both):
```
myapp:v1.2.3
myapp:abc1234567
myapp:latest
```

---

**2. Multi-platform builds - MILLAL Kasutada?**

**Option A: Single platform (linux/amd64)**

**MILLAL kasutada:**
- ✅ Homogeneous infrastructure (kõik serverid on x86)
- ✅ Speed critical (multi-platform 2x slower)

---

**Option B: Multi-platform (linux/amd64,linux/arm64)**

**MILLAL kasutada:**
- ✅ Heterogeneous infrastructure (x86 + ARM)
- ✅ Cloud-native (AWS Graviton = ARM, cost savings 20%)
- ✅ Apple Silicon support (M1/M2 = ARM)

**Trade-off:**
- ✅ Flexibility (works everywhere)
- ❌ Slower builds (2x time)
- ❌ More runner minutes (double cost)

---

**3. Layer caching - MIKS See On Kriitiline?**

**Without cache:**
```
Build 1: 5 minutes (download all dependencies)
Build 2: 5 minutes (download all dependencies again)
Build 3: 5 minutes (download all dependencies again)
```

**With cache:**
```
Build 1: 5 minutes (download dependencies)
Build 2: 30 seconds (reuse cached dependencies)
Build 3: 30 seconds (reuse cached dependencies)
```

**MIKS cache on oluline?**
- ✅ 10x faster builds
- ✅ Lower runner minutes (cost savings)
- ✅ Faster feedback (developer gets results faster)

**MILLAL cache ei tööta?**
- ❌ Dependency changes (package.json updated → cache invalid)
- ❌ Base image updated (node:18 → node:20 → cache invalid)

**DevOps best practice:** Always enable caching (free speed boost).

---

**Minimal näide (kontsept):**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: myusername/backend:${{ github.sha }}
          cache-from: type=registry,ref=myusername/backend:cache
```

**Explanation:**
- `tags: ${{ github.sha }}` → automatic git SHA tagging
- `cache-from` → reuse cached layers

**TÄHTIS:** Täielikke Docker build workflow'e harjutad **Lab 5: CI/CD Lab'is**.

---

## 15.7 Best Practices - MIKS Oluline?

### 1. Fail Fast - MIKS?

**Concept:** Run fast checks first, slow checks later.

**MIKS see on hea?**
- ✅ If lint fails (30s), don't waste 5min on tests
- ✅ Faster feedback (developer knows immediately)
- ✅ Lower runner minutes (don't run expensive tests if code doesn't lint)

**Example:**
```
Step 1: Lint (30s) ← if fails, stop here
Step 2: Unit tests (3m) ← if fails, stop here
Step 3: Integration tests (5m)
Step 4: Deploy
```

**Without fail-fast:**
```
All steps run even if lint fails → waste 8 minutes
```

**With fail-fast:**
```
Lint fails → stop immediately → save 8 minutes
```

---

### 2. Use Specific Action Versions - MIKS?

**❌ BAD:**
```yaml
uses: actions/checkout@main  # Unstable (main branch changes)
```

**✅ GOOD:**
```yaml
uses: actions/checkout@v4  # Stable (v4 never changes)
```

**MIKS see on oluline?**
- ✅ Reproducible builds (sama workflow alati sama result)
- ✅ No breaking changes (v4 → v5 upgrade controlled)
- ✅ Security (pinned version, ei muutu ilma teadmata)

---

### 3. Separate Workflows - MIKS?

**MIKS mitte 1 gigantic workflow?**

**Problem:**
```
1 workflow:
- Lint
- Test
- Build
- Deploy
- Security scan
- Dependency update

→ 1 fail → entire workflow fails (even if unrelated)
→ Slow feedback (peab ootama kõiki steps)
```

**Solution: Separate workflows**
```
ci.yml → Test, lint (on PR)
build.yml → Build, push (on push to main)
deploy.yml → Deploy (on release tag)
security.yml → Security scan (nightly)
```

**MIKS see on parem?**
- ✅ Faster feedback (tests run independent of security scan)
- ✅ Clear separation (deploy workflow ei sisalda test logic)
- ✅ Easier debugging (väiksem workflow → lihtsam aru saada)

---

### 4. Timeout Jobs - MIKS?

**Problem: Hanging jobs**

```
Test starts → hangs (infinite loop) → runs forever → consumes all runner minutes
```

**Solution:**
```yaml
jobs:
  test:
    timeout-minutes: 10  # Kill after 10 minutes
```

**MIKS see on oluline?**
- ✅ Prevents runaway costs (hanging job ei consume kogu budget)
- ✅ Faster feedback (ei oota 6h, et job eventually fails)

---

### 5. Cache Dependencies - MIKS?

**Without cache:**
```
npm install → download 200 MB dependencies → 2 minutes
(iga build)
```

**With cache:**
```
npm install → reuse cached dependencies → 10 seconds
```

**MIKS cache on oluline?**
- ✅ 10x faster builds
- ✅ Lower costs (less runner minutes)

**MILLAL cache invalideerimine?**
- Dependencies change (package-lock.json updated) → cache rebuilt

---

## 15.8 GitHub-Hosted vs Self-Hosted Runners

### GitHub-Hosted Runners

**Specs:**
- Ubuntu, Windows, macOS
- 2 CPU cores, 7 GB RAM, 14 GB SSD
- Fresh VM every job (clean state)

**Free tier:**
- 2,000 minutes/month (public repos: unlimited)
- After limit: $0.008/minute (~$0.50/hour)

**MIKS GitHub-Hosted?**

**Pros:**
- ✅ **Zero maintenance:** Ei pea OS-i updatedama, security patches automatic
- ✅ **Fast startup:** VM allocated in 10-20 seconds
- ✅ **Clean environment:** Iga job fresh VM (no leftover state)
- ✅ **Security:** Isolated (malicious code ei mõjuta teisi workflows)

**Cons:**
- ❌ **Limited resources:** 2 cores (ei sobi heavy builds)
- ❌ **No GPU:** Deep learning, video rendering ei tööta
- ❌ **Cost after free tier:** $0.008/min = $28.80 kui 3,600 min/month (60h/month)

**MILLAL kasutada GitHub-Hosted?**
- ✅ Small/medium projects (< 2,000 min/month)
- ✅ Open-source (unlimited minutes)
- ✅ Security critical (isolated environment)

---

### Self-Hosted Runners

**Concept:** Use your own VPS/server as runner.

**MIKS Self-Hosted?**

**Pros:**
- ✅ **Unlimited minutes:** Ei maksa GitHub'ile (free)
- ✅ **Custom hardware:** GPU, 32 cores, 128 GB RAM (kui vaja)
- ✅ **Access to internal network:** Deploy to on-premise Kubernetes
- ✅ **Cost savings:** $5/month VPS vs $30/month GitHub-hosted

**Cons:**
- ❌ **Maintenance:** OS updates, security patches (sina pead)
- ❌ **Not isolated:** Persistent state (previous job files jäävad)
- ❌ **Security risk:** Malicious code saab access serverile
- ❌ **Availability:** Kui server down → workflows fail

---

### Design Decision: Millal Kasutada?

**GitHub-Hosted:**
- ✅ Open-source projects (unlimited minutes)
- ✅ Security critical (need isolation)
- ✅ Don't want maintenance burden

**Self-Hosted:**
- ✅ High runner minute usage (> 5,000 min/month = cost savings)
- ✅ Custom hardware needed (GPU, high RAM)
- ✅ Deploy to on-premise infrastructure
- ✅ Private repos with lots of builds

**DevOps best practice:**
- Start with GitHub-Hosted (simple)
- Migrate to Self-Hosted kui costs > $50/month

---

**Security warning:**
- ⚠️ **NEVER** use self-hosted runners for public repos (malicious PR saab access serverile!)
- ✅ **ONLY** use self-hosted for private repos (trust your team)

---

## 15.9 Alternatiivid: GitLab CI ja Bamboo

### MIKS Võrrelda?

**DevOps reaalsus:**
> "GitHub Actions on hea, aga organisatsioon võib kasutada GitLab'i või Bamboo'd. DevOps administraator PEAB mõistma erinevusi."

**Kolm peamist CI/CD platvormi:**
1. **GitHub Actions** - GitHub'i native, populaarne open-source projektidele
2. **GitLab CI/CD** - GitLab'i native, enterprise favorite
3. **Bamboo** - Atlassian (Jira integratsioon), enterprise legacy

---

### GitHub Actions vs GitLab CI/CD

| **Kriteerium** | **GitHub Actions** | **GitLab CI/CD** |
|---|---|---|
| **Workflow syntax** | YAML (`.github/workflows/`) | YAML (`.gitlab-ci.yml`) |
| **Free tier** | 2,000 min/month | 400 min/month |
| **Self-hosted** | Supported | Supported (better tooling) |
| **Marketplace** | 10,000+ actions | Smaller ecosystem |
| **Enterprise** | Good | Better (more features) |
| **Learning curve** | Easy | Moderate |

---

**MILLAL kasutada GitHub Actions?**
- ✅ Repo on GitHubis
- ✅ Open-source (unlimited minutes)
- ✅ Simple workflows (build, test, deploy)
- ✅ Want marketplace actions

**MILLAL kasutada GitLab CI/CD?**
- ✅ Repo on GitLabis
- ✅ Enterprise (better pricing for self-hosted)
- ✅ Complex pipelines (better DAG support)
- ✅ Want GitLab's integrated DevOps platform

---

### GitHub Actions vs Bamboo

| **Kriteerium** | **GitHub Actions** | **Bamboo** |
|---|---|---|
| **Hosting** | Cloud (GitHub) | Self-hosted (Atlassian) |
| **Cost** | Free tier + pay-per-minute | License fee ($10-100k/year) |
| **Setup** | Zero setup | Complex setup |
| **Jira integration** | Via marketplace | Native (excellent) |
| **Modern** | Yes (2019+) | Legacy (2008+) |

---

**MILLAL kasutada Bamboo?**
- ✅ Already using Atlassian stack (Jira, Confluence, Bitbucket)
- ✅ Enterprise legacy (migrating from Bamboo complex)
- ✅ On-premise strict requirements

**MIKS migrate FROM Bamboo?**
- ❌ Expensive license fees
- ❌ Complex maintenance
- ❌ Legacy architecture (less modern features)

**DevOps trend:** Enterprises moving FROM Bamboo TO GitHub Actions / GitLab CI.

---

### Design Decision Framework

**Choosing CI/CD platform:**

**Step 1:** Where is your repo?
- GitHub → GitHub Actions (obvious choice)
- GitLab → GitLab CI/CD (obvious choice)
- Bitbucket → GitHub Actions / GitLab CI (migrate repo)

**Step 2:** Enterprise requirements?
- Yes → GitLab CI/CD (better enterprise features)
- No → GitHub Actions (simpler, cheaper)

**Step 3:** Existing stack?
- Atlassian stack → Bamboo (if already paying)
- No existing stack → GitHub Actions (free tier)

**DevOps best practice:**
- Default: GitHub Actions (jos repo on GitHubis)
- Enterprise: GitLab CI/CD (better pricing, features)
- Legacy: Bamboo (ainult kui juba kasutuses)

---

## Kokkuvõte

**Peamised kontseptid:**

1. **CI/CD revolutsioon:**
   - Manual deployment → automated pipeline
   - 30 min → 5 min, error-prone → consistent
   - Fear of deployment → deploy 10x päevas

2. **GitHub Actions architecture:**
   - Workflow = YAML file
   - Triggers = push, PR, schedule, manual
   - Runners = GitHub-hosted vs self-hosted

3. **Design decisions:**
   - Triggers: Millal kasutada push vs PR vs schedule?
   - Secrets: MIKS secrets management on kriitiline?
   - Parallel jobs: Millal paralleliseerimine on worth it?
   - Docker builds: Tagging strategy (SHA vs semver)
   - Runners: GitHub-hosted vs self-hosted (cost, security, performance)

4. **Best practices:**
   - Fail fast (lint before tests)
   - Specific versions (reproducible builds)
   - Separate workflows (clear separation)
   - Timeout jobs (prevent runaway costs)
   - Cache dependencies (10x faster builds)

5. **Alternatiivid:**
   - GitHub Actions: Cloud-native, simple, good free tier
   - GitLab CI/CD: Enterprise, better pricing, complex features
   - Bamboo: Legacy, expensive, Atlassian integration

---

**Järgmine samm:**

**Lab 5: CI/CD Lab** - Praktilised harjutused:
- Harjutus 1: First GitHub Actions workflow
- Harjutus 2: Multi-job workflows (parallel execution)
- Harjutus 3: Automated Docker builds
- Harjutus 4: Complete CI/CD pipeline (build → test → deploy)
- Harjutus 5: Self-hosted runner setup

**Lab 5'is õpid:**
- Täielikke workflow YAML faile kirjutada
- Debugging GitHub Actions (logs, secrets)
- Production-ready pipelines (security, caching, multi-environment)

---

**Mõtle:**
- MIKS eelistaksid GitHub Actions vs GitLab CI?
- Kuidas disainida CI/CD pipeline, mis on KIIRE ja TURVALINE?
- MILLAL on self-hosted runners worth it?

**Edasi:** Lab 5 või Peatükk 16 (Docker Build Automation).
