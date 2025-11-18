# Harjutus 1: GitHub Actions Põhitõed

**Kestus:** 45 minutit
**Eesmärk:** Õppida GitHub Actions workflow'de loomist ja GitHub Secrets'ide kasutamist

---

## 📋 Ülevaade

Selles harjutuses tutvud **GitHub Actions**'iga - GitHub'i integreeritud CI/CD platvormiga. Õpid looma workflow'sid, mis käivituvad automaatselt koodi muutuste peale.

**GitHub Actions** võimaldab automatiseerida build, test ja deploy protsesse otse GitHub repositooriumi sees. Iga workflow koosneb job'idest, mis koosnevad step'idest, kus käivitatakse käske või kasutatakse valmis action'eid.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua GitHub Actions workflow YAML faile
- ✅ Mõista workflow struktuuri (triggers, jobs, steps)
- ✅ Kasutada GitHub Actions marketplace'i
- ✅ Seadistada GitHub Secrets
- ✅ Käivitada workflow'sid automaatselt ja manuaalselt
- ✅ Vaadata workflow logisid ja debuggida
- ✅ Kasutada environment variable'eid

---

## 🏗️ Arhitektuur

```
┌────────────────────────────────────────────────┐
│         GitHub Repository                      │
│                                                │
│  Developer push/PR                             │
│         │                                      │
│         ▼                                      │
│  ┌────────────────────────────────────────┐   │
│  │  .github/workflows/hello.yml          │   │
│  │                                        │   │
│  │  on: [push, pull_request]             │   │
│  │                                        │   │
│  │  jobs:                                 │   │
│  │    hello:                              │   │
│  │      runs-on: ubuntu-latest            │   │
│  │      steps:                            │   │
│  │        - checkout code                 │   │
│  │        - run commands                  │   │
│  └────────────────┬───────────────────────┘   │
│                   │                            │
│                   ▼                            │
│  ┌────────────────────────────────────────┐   │
│  │    GitHub Actions Runner               │   │
│  │    (Ubuntu 22.04 VM)                   │   │
│  │                                        │   │
│  │    [Executing workflow...]             │   │
│  │    ✅ Step 1: Checkout                 │   │
│  │    ✅ Step 2: Run script               │   │
│  └────────────────────────────────────────┘   │
│                                                │
└────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Loo GitHub Repository (5 min)

**1. Loo uus repository või kasuta olemasolevat:**

```bash
# Variant A: Loo uus repo GitHub UI's
# https://github.com/new
# Nimi: user-service-cicd
# Avalik või privaatne

# Variant B: Kasuta GitHub CLI
gh repo create user-service-cicd --public --clone

cd user-service-cicd
```

**2. Kopeeri User Service rakendus:**

```bash
# Kopeeri backend-nodejs kood
cp -r ../../../apps/backend-nodejs/* .

# Kontrolli
ls -la

# Peaks näitama:
# package.json
# server.js
# routes/
# middleware/
# ...

# Commit ja push
git add .
git commit -m "Initial commit: User Service"
git push origin main
```

---

### Samm 2: Loo Esimene Workflow (10 min)

**Loo kataloog ja workflow fail:**

```bash
# Loo workflow directory
mkdir -p .github/workflows

# Loo esimene workflow
vim .github/workflows/hello.yml
```

**`.github/workflows/hello.yml`:**

```yaml
name: Hello World

# Triggers - millal workflow käivitub
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:  # Manual trigger

# Jobs - paralleelsed tööd
jobs:
  hello:
    runs-on: ubuntu-latest

    steps:
      # Step 1: Checkout code
      - name: Checkout code
        uses: actions/checkout@v3

      # Step 2: Print environment info
      - name: Print environment
        run: |
          echo "🚀 Workflow triggered by: ${{ github.event_name }}"
          echo "📁 Repository: ${{ github.repository }}"
          echo "🌿 Branch: ${{ github.ref_name }}"
          echo "👤 Actor: ${{ github.actor }}"
          echo "💻 Runner OS: ${{ runner.os }}"

      # Step 3: List files
      - name: List files
        run: |
          echo "📂 Repository contents:"
          ls -la

      # Step 4: Node.js version
      - name: Check Node.js version
        run: |
          node --version
          npm --version
```

**Workflow struktuuri selgitus:**

- **name:** Workflow nimi (nähtav GitHub UI's)
- **on:** Trigger events (push, PR, manual)
- **jobs:** Tööde kollektsioon (võivad joosta paralleelselt)
- **runs-on:** Runner OS (ubuntu-latest, windows-latest, macos-latest)
- **steps:** Sammud job'i sees (järjekordne)
- **uses:** Valmis action marketplace'ist
- **run:** Shell käsud

**Commit ja push:**

```bash
git add .github/workflows/hello.yml
git commit -m "Add GitHub Actions hello world workflow"
git push origin main
```

---

### Samm 3: Vaata Workflow Käivitumist (5 min)

**GitHub UI's:**

1. Mine oma repository → **Actions** tab
2. Peaks näitama workflow "Hello World" käivitumas
3. Kliki workflow run'ile → vaata job'e
4. Kliki "hello" job'ile → vaata iga step'i logisid

**Oodatud väljund:**

```
✅ Checkout code
✅ Print environment
   🚀 Workflow triggered by: push
   📁 Repository: your-username/user-service-cicd
   🌿 Branch: main
   👤 Actor: your-username
   💻 Runner OS: Linux

✅ List files
   📂 Repository contents:
   drwxr-xr-x    .github/
   -rw-r--r--    package.json
   -rw-r--r--    server.js
   ...

✅ Check Node.js version
   v18.x.x
   9.x.x
```

**GitHub CLI kaudu:**

```bash
# Vaata workflow runs
gh run list

# Vaata viimase run'i logisid
gh run view --log
```

---

### Samm 4: Käivita Workflow Manuaalselt (5 min)

**workflow_dispatch** võimaldab manuaalset käivitamist.

**GitHub UI's:**

1. Actions tab → "Hello World" workflow
2. Kliki "Run workflow" → vali branch → "Run workflow"

**GitHub CLI kaudu:**

```bash
# Käivita workflow manuaalselt
gh workflow run hello.yml --ref main

# Vaata staatust
gh run list --workflow=hello.yml
```

---

### Samm 5: Lisa GitHub Secrets (10 min)

**Secrets** = turvaliselt salvestatud muutujad (API keys, passwords, tokens).

**Loo secrets GitHub UI's:**

1. Repository → **Settings** → **Secrets and variables** → **Actions**
2. Kliki **New repository secret**
3. Nimi: `SUPER_SECRET`
4. Value: `my-secret-value-12345`
5. Kliki **Add secret**

**Loo veel üks:**
- Nimi: `API_KEY`
- Value: `test-api-key-xyz`

**Kasuta secret'eid workflow's:**

Muuda `hello.yml`:

```yaml
name: Hello World

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  hello:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Use secrets
        run: |
          echo "🔐 Secret length: ${#SUPER_SECRET}"
          echo "🔑 API key starts with: ${API_KEY:0:4}..."
          echo "⚠️  Full secrets are NEVER printed in logs!"
        env:
          SUPER_SECRET: ${{ secrets.SUPER_SECRET }}
          API_KEY: ${{ secrets.API_KEY }}

      - name: Conditional step (using secrets)
        if: secrets.API_KEY != ''
        run: |
          echo "✅ API key is configured!"
```

**Commit ja push:**

```bash
git add .github/workflows/hello.yml
git commit -m "Add secrets usage to workflow"
git push origin main
```

**Kontrolli logisid:**

- Secrets'id on GitHub'i poolt automaatselt maskeeritud
- Kui printid `${{ secrets.SUPER_SECRET }}`, näed `***`

---

### Samm 6: Loo Multi-Job Workflow (5 min)

**Loo uus workflow mitme job'iga:**

Loo fail `.github/workflows/multi-job.yml`:

```yaml
name: Multi-Job Example

on:
  workflow_dispatch:

jobs:
  # Job 1: Build
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build step
        run: |
          echo "🔨 Building application..."
          sleep 2
          echo "✅ Build complete!"

  # Job 2: Test (depends on build)
  test:
    runs-on: ubuntu-latest
    needs: build  # Käivitub alles peale build'i
    steps:
      - uses: actions/checkout@v3
      - name: Test step
        run: |
          echo "🧪 Running tests..."
          sleep 2
          echo "✅ Tests passed!"

  # Job 3: Deploy (depends on test)
  deploy:
    runs-on: ubuntu-latest
    needs: test  # Käivitub alles peale test'i
    steps:
      - name: Deploy step
        run: |
          echo "🚀 Deploying..."
          sleep 2
          echo "✅ Deployed!"
```

**needs** võimaldab defineerida sõltuvusi job'ide vahel:

```
build → test → deploy
```

**Commit ja testi:**

```bash
git add .github/workflows/multi-job.yml
git commit -m "Add multi-job workflow example"
git push origin main

# Käivita manuaalselt
gh workflow run multi-job.yml --ref main

# Vaata progressi
gh run watch
```

---

### Samm 7: Kasuta Actions Marketplace (5 min)

**GitHub Actions Marketplace** sisaldab tuhandeid valmis action'eid.

**Näide: Setup Node.js action:**

Loo fail `.github/workflows/nodejs.yml`:

```yaml
name: Node.js Setup

on:
  workflow_dispatch:

jobs:
  setup-node:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      # Setup Node.js
      - name: Setup Node.js 18
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      # Install dependencies
      - name: Install dependencies
        run: npm ci

      # Run script
      - name: Run script
        run: npm run --if-present start &
```

**Populaarsed action'id:**

- `actions/checkout@v3` - Checkout code
- `actions/setup-node@v3` - Setup Node.js
- `actions/setup-python@v4` - Setup Python
- `docker/build-push-action@v4` - Build/push Docker image
- `actions/upload-artifact@v3` - Upload artifacts
- `actions/download-artifact@v3` - Download artifacts

**Otsi marketplace'ist:**
https://github.com/marketplace?type=actions

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **GitHub repository:**
  - [ ] User Service kood
  - [ ] `.github/workflows/` kataloog

- [ ] **Workflows:**
  - [ ] `hello.yml` - basic workflow
  - [ ] `multi-job.yml` - job dependencies
  - [ ] `nodejs.yml` - marketplace actions

- [ ] **GitHub Secrets:**
  - [ ] `SUPER_SECRET`
  - [ ] `API_KEY`

- [ ] **Workflow runs:**
  - [ ] Vähemalt 1 edukas workflow run
  - [ ] Logid nähtavad Actions tab'is

- [ ] **Mõistad:**
  - [ ] Triggers (push, PR, workflow_dispatch)
  - [ ] Jobs ja steps
  - [ ] Secrets kasutamist
  - [ ] Marketplace actions

---

## 🐛 Troubleshooting

### Probleem 1: Workflow ei käivitu

**Sümptom:**
```bash
git push origin main
# Aga workflow ei käivitu GitHub Actions tab'is
```

**Diagnoos:**

1. **Kontrolli workflow faili asukohta:**

```bash
# Peab olema täpselt:
.github/workflows/hello.yml

# MITTE:
github/workflows/hello.yml  # Vale!
.github/workflow/hello.yml  # Vale (puudub 's')
```

2. **Kontrolli YAML syntax:**

```bash
# GitHub Actions tab → workflow → "Invalid workflow file"
# Vaata vea sõnumit

# Või kasuta online validator:
# https://www.yamllint.com/
```

3. **Kontrolli trigger'it:**

```yaml
on:
  push:
    branches: [main]  # Kas push'isid main branch'i?
```

**Lahendus:**

```bash
# Paranda YAML syntax
vim .github/workflows/hello.yml

# Commit uuesti
git add .github/workflows/hello.yml
git commit -m "Fix workflow syntax"
git push origin main
```

---

### Probleem 2: Secret ei ole defineeritud

**Sümptom:**
```yaml
env:
  API_KEY: ${{ secrets.API_KEY }}
```

**Workflow logis:**
```
⚠️  Warning: The 'API_KEY' environment variable is not set.
```

**Diagnoos:**

```bash
# Kontrolli, kas secret on loodud:
# Settings → Secrets → Actions
```

**Lahendus:**

1. Mine repository → Settings → Secrets and variables → Actions
2. Kliki "New repository secret"
3. Lisa `API_KEY` secret
4. Käivita workflow uuesti (Re-run jobs)

---

### Probleem 3: Job ebaõnnestub

**Sümptom:**
```
❌ Test step
   Error: Command failed with exit code 1
```

**Diagnoos:**

```yaml
- name: Test step
  run: |
    npm test  # Kui test'e pole, see failib
```

**Vaata logisid:**

1. Actions tab → workflow run → failed job
2. Kliki samm, mis failis
3. Loe error message

**Lahendus:**

```yaml
# Variant A: Paranda käsk
- name: Test step
  run: |
    npm run --if-present test  # Fail'ib ainult kui script olemas JA failib

# Variant B: Ignoreeri error
- name: Test step
  continue-on-error: true
  run: |
    npm test
```

---

## 🎓 Õpitud Mõisted

### GitHub Actions:
- **Workflow:** Automatiseeritud protsess (YAML fail `.github/workflows/` kaustas)
- **Trigger:** Event, mis käivitab workflow (push, PR, schedule, manual)
- **Job:** Tööde kogum, mis käivituvad runner'il
- **Step:** Individuaalne käsk või action job'i sees
- **Runner:** Virtuaalne masin, mis käivitab workflow'sid (Ubuntu, Windows, macOS)
- **Action:** Reusable step (marketplace või custom)

### Triggers:
- **push:** Koodi push repository'sse
- **pull_request:** PR loomine või update
- **workflow_dispatch:** Manuaalne käivitamine
- **schedule:** Cron-based (nt iga päev kell 2:00)
- **release:** GitHub release loomine

### Secrets:
- **Repository secret:** Saadaval kõigile workflow'dele
- **Environment secret:** Specific environment'ile (dev, prod)
- **Organization secret:** Jagatud mitme repo vahel

### Workflow Syntax:
- **on:** Trigger definitsioon
- **jobs:** Job'ide kollektsioon
- **runs-on:** Runner OS
- **needs:** Job sõltuvused
- **if:** Conditional execution
- **env:** Environment variables
- **uses:** Action kasutamine
- **run:** Shell käsk

---

## 💡 Parimad Tavad

1. **Nimeta workflow'sid selgelt** - Kasuta kirjeldavaid nimesid (`CI`, `Deploy Production`)
2. **Kasuta secrets'eid** - Ära kunagi harda-code API key'sid YAML'is
3. **Määra timeout** - `timeout-minutes: 10` (vältimaks kinni jäänud job'e)
4. **Kasuta cache'i** - `actions/cache@v3` (kiirenda dependency install'i)
5. **Fail fast** - `fail-fast: true` (stop teised job'id kui üks failib)
6. **Kasuta matrix** - Testi mitme Node.js versiooniga paralleelselt
7. **Lisa badge** - Repository README'sse: `![CI](https://github.com/user/repo/workflows/CI/badge.svg)`
8. **Versiooni actions** - `actions/checkout@v3` (mitte `@main`)
9. **Documenti workflow'sid** - Lisa kommentaarid YAML'is
10. **Testi local** - Kasuta [act](https://github.com/nektos/act) tool'i local testimiseks

---

## 🔗 Järgmine Samm

Nüüd oskad luua GitHub Actions workflow'sid! Järgmises harjutuses automatiseerime **Docker image build'i ja push'i Docker Hub'i**.

**Jätka:** [Harjutus 2: Docker Build ja Push](02-docker-build-push.md)

---

## 📚 Viited

### GitHub Actions Dokumentatsioon:
- [GitHub Actions](https://docs.github.com/en/actions)
- [Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Events that trigger workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- [Using secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

### Marketplace:
- [Actions Marketplace](https://github.com/marketplace?type=actions)
- [actions/checkout](https://github.com/actions/checkout)
- [actions/setup-node](https://github.com/actions/setup-node)

### Tools:
- [act - Run GitHub Actions locally](https://github.com/nektos/act)
- [actionlint - Workflow linter](https://github.com/rhysd/actionlint)

---

**Õnnitleme! Oled loonud oma esimesed GitHub Actions workflow'd! 🎉**
