# Harjutus 1: GitHub Actions Põhitõed

**Kestus:** 60 minutit
**Eesmärk:** Õppida GitHub Actions workflow'de loomist ja põhikontseptsioone

---

## 📋 Ülevaade

Selles harjutuses **lood oma esimese GitHub Actions workflow'i** ja õpid GitHub Actions põhimõisteid. Seadistad repository, GitHub Secrets'id ja käivitad esimese automated workflow'i.

**GitHub Actions = GitHub'i integreeritud CI/CD platvorm**
- Workflow'id käivituvad automaatselt (push, PR, schedule)
- Töötab GitHub'i serverites (runners)
- YAML-based konfiguratsioon
- Tasuta tier: 2000 minutit/kuu (public repos unlimited)

---

## 🎯 Õpieesmärgid

- ✅ Mõista GitHub Actions arhitektuuri
- ✅ Luua esimene workflow YAML fail
- ✅ Seadistada GitHub Secrets
- ✅ Kasutada triggers'eid (push, pull_request, workflow_dispatch)
- ✅ Debuggida workflow'sid

---

## 🏗️ Arhitektuur

```
GitHub Repository
   │
   ├── .github/workflows/hello.yml
   │
   │   Workflow Triggers:
   │   ├─ push (automaatne)
   │   ├─ pull_request (automaatne)
   │   └─ workflow_dispatch (manuaalne)
   │
   ▼
GitHub Actions Runner (ubuntu-latest)
   │
   ├─ Job 1: Greet
   │   ├─ Step 1: Checkout code
   │   ├─ Step 2: Run script
   │   └─ Step 3: Use secret
   │
   └─ Logs (visible in GitHub UI)
```

---

## 📝 Sammud

### Samm 1: Loo GitHub Repository (10 min)

**1a. Loo uus repository:**

GitHub UI'st:
- Mine: https://github.com/new
- Nimi: `user-service-cicd` (või mis tahes)
- Vali: **Public** (tasuta GitHub Actions)
- ✅ Add README
- Create repository

**1b. Clone local'i:**

```bash
git clone https://github.com/YOUR-USERNAME/user-service-cicd.git
cd user-service-cicd
```

### Samm 2: Esimene Workflow - Hello World (15 min)

**2a. Loo workflow directory:**

```bash
mkdir -p .github/workflows
```

**2b. Loo workflow fail:**

`.github/workflows/hello.yml`:

```yaml
# Esimene GitHub Actions Workflow
name: Hello World

# Triggers - millal workflow käivitub
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:  # Manual trigger

# Jobs - paralleelsed tööülesanded
jobs:
  greet:
    name: 👋 Greet
    runs-on: ubuntu-latest  # GitHub-hosted runner
    
    steps:
      # Step 1: Checkout code
      - name: 📥 Checkout code
        uses: actions/checkout@v4
      
      # Step 2: Print hello
      - name: 👋 Say hello
        run: |
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Hello from GitHub Actions!"
          echo "Repository: ${{ github.repository }}"
          echo "Branch: ${{ github.ref_name }}"
          echo "Commit: ${{ github.sha }}"
          echo "Actor: ${{ github.actor }}"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      
      # Step 3: System info
      - name: 🖥️ System info
        run: |
          echo "OS: $(uname -a)"
          echo "CPU: $(nproc) cores"
          echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
          echo "Disk: $(df -h / | tail -1 | awk '{print $4}') free"
```

**2c. Commit ja push:**

```bash
git add .github/workflows/hello.yml
git commit -m "Add Hello World workflow"
git push
```

**2d. Vaata workflow'i:**

- Mine: https://github.com/YOUR-USERNAME/user-service-cicd/actions
- Kliki workflow "Hello World"
- Vaata logs'e

✅ **Kontrolli:** Workflow peaks olema roheline (success)

### Samm 3: Mõista Workflow Süntaksi (10 min)

**Workflow anatomy:**

```yaml
name: Workflow Name              # UI'st nähtav nimi

on:                              # Triggers
  push:                          # Git push event
    branches: [main]             # Ainult main branch
  workflow_dispatch:             # Manual trigger

jobs:                            # Paralleelsed job'id
  build:                         # Job ID
    runs-on: ubuntu-latest       # Runner environment
    
    steps:                       # Järjestikused sammud
      - uses: actions/checkout@v4  # Use action
      - run: echo "Hello"          # Run command
```

**Context variables:**

```yaml
${{ github.repository }}    # owner/repo
${{ github.ref_name }}      # Branch name
${{ github.sha }}           # Commit SHA
${{ github.actor }}         # User who triggered
${{ github.event_name }}    # Event type (push, pull_request)
```

### Samm 4: Seadista GitHub Secrets (15 min)

**4a. Generate Docker Hub token:**

1. Mine: https://hub.docker.com/settings/security
2. New Access Token
3. Nimi: `github-actions`
4. Permissions: Read, Write, Delete
5. Generate & copy token

**4b. Lisa GitHub Secrets:**

GitHub repository → Settings → Secrets and variables → Actions → New repository secret:

```
Name: DOCKER_USERNAME
Secret: your-dockerhub-username
```

```
Name: DOCKER_PASSWORD
Secret: <paste Docker Hub token>
```

**4c. Test secrets workflow'is:**

`.github/workflows/test-secrets.yml`:

```yaml
name: Test Secrets

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: 🔐 Test Docker Hub secret
        run: |
          # Secrets are masked in logs
          echo "Docker username: ${{ secrets.DOCKER_USERNAME }}"
          echo "Docker password: ***"  # Never print secrets!
          
          # Test Docker Hub login
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          
          echo "✅ Docker Hub authentication successful!"
```

**4d. Push ja käivita:**

```bash
git add .github/workflows/test-secrets.yml
git commit -m "Add secrets test workflow"
git push
```

GitHub UI → Actions → "Test Secrets" → Run workflow → Run workflow

✅ **Kontrolli:** Login peaks õnnestuma

### Samm 5: Multi-Job Workflow (10 min)

**Loo workflow mitme job'iga:**

`.github/workflows/multi-job.yml`:

```yaml
name: Multi-Job Example

on:
  workflow_dispatch:

jobs:
  # Job 1: Lint
  lint:
    name: 🔍 Lint
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Run lint
        run: echo "✅ Lint passed"
  
  # Job 2: Test (depends on lint)
  test:
    name: 🧪 Test
    runs-on: ubuntu-latest
    needs: lint  # Wait for lint to complete
    
    strategy:
      matrix:
        version: [20, 22]  # Test on Node 20 and 22
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Node ${{ matrix.version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.version }}
      
      - name: Node version
        run: node --version
  
  # Job 3: Build (depends on test)
  build:
    name: 🐳 Build
    runs-on: ubuntu-latest
    needs: test
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Simulate build
        run: echo "✅ Build completed"
```

**Push ja käivita:**

```bash
git add .github/workflows/multi-job.yml
git commit -m "Add multi-job workflow"
git push
```

✅ **Kontrolli:** 
- lint käivitub esimesena
- test käivitub 2x (Node 20 + 22) paralleelselt
- build käivitub viimasena

---

## ✅ Kontrolli Tulemusi

- [ ] GitHub repository loodud
- [ ] Esimene workflow käivitus edukas
- [ ] GitHub Secrets seadistatud (DOCKER_USERNAME, DOCKER_PASSWORD)
- [ ] Secrets test workflow edukas
- [ ] Multi-job workflow töötab õigesti
- [ ] Mõistad workflow süntaksi

---

## 🎓 Õpitud Mõisted

**Workflow:**
- YAML fail `.github/workflows/` kataloogis
- Defineerib automated tasks
- Käivitub triggers'i peale

**Job:**
- Paralleelne tööülesanne
- Töötab eraldi runner'is
- Võib sõltuda teistest job'idest (`needs`)

**Step:**
- Järjestikuline samm job'is
- Kas `run` (bash command) või `uses` (action)

**Runner:**
- GitHub-hosted VM (ubuntu-latest, windows-latest, macos-latest)
- Self-hosted runner (oma server)

**Secrets:**
- Turvaliselt salvestatud väärtused
- Masked logides
- Access: `${{ secrets.SECRET_NAME }}`

**Matrix:**
- Parallel runs erinevate väärtustega
- Näide: test mitmel Node versioonil

---

## 💡 Best Practices

1. **Kasuta semantic workflow names** - "CI Pipeline" mitte "test.yml"
2. **Job dependencies** - Use `needs` logical järjestuse jaoks
3. **Never log secrets** - GitHub maskib automaatselt, aga ära printi
4. **Matrix strategy** - Test mitmel versioonil paralleelselt
5. **Manual triggers** - Lisa `workflow_dispatch` debugging'uks
6. **Descriptive step names** - Use emojis ja clear descriptions

---

## 🐛 Troubleshooting

### Workflow ei käivitu?

```bash
# Kontrolli:
# 1. Fail on .github/workflows/ kataloogis
# 2. YAML syntax on korrektne (use YAML validator)
# 3. Trigger on seadistatud (on: push)
```

### "Invalid workflow file"?

```bash
# YAML syntax error
# Kasuta YAML lint'i või GitHub UI
# Common errors:
# - Indentation (use 2 spaces, not tabs)
# - Missing colons
# - Wrong quotes
```

### Secret ei tööta?

```bash
# Kontrolli:
# 1. Secret name on korrektne (case-sensitive)
# 2. Secret on repository level (not organization)
# 3. Secret on seadistatud enne workflow run'i
```

---

## 🔗 Järgmine Samm

Järgmises harjutuses ehitad **täieliku CI pipeline'i** linting, testing ja Docker build'iga!

**Jätka:** [Harjutus 2: CI Pipeline](02-ci-pipeline.md)

---

## 📚 Viited

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub-hosted Runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
- [Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

**Õnnitleme! Oled loonud oma esimese GitHub Actions workflow'i! 🎉**
