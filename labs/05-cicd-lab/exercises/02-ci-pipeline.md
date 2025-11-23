# Harjutus 2: Continuous Integration Pipeline

**Kestus:** 60 minutit
**Eesmärk:** Ehita täielik CI pipeline - lint, test, build, security scan

---

## 📋 Ülevaade

Selles harjutuses **ehitad täieliku CI (Continuous Integration) pipeline'i**, mis automaatselt:
- Lintib koodi (ESLint)
- Testib mitmel Node versioonil (20 + 22)
- Ehitab Docker image'i
- Skaneerib turvaauke (Docker Scout + Trivy)

**CI = Continuous Integration:**
- Iga code commit trigger'dab automated checks
- Leiab bugid vara (enne deploy'i)
- Tagab code quality
- Blokeerib deploy kui tests fail

---

## 🎯 Õpieesmärgid

- ✅ Luua täielik CI workflow
- ✅ Automatiseerida linting ja testing
- ✅ Multi-version testing (matrix strategy)
- ✅ Docker image build automation
- ✅ Security scanning integration
- ✅ Artifact management

---

## 🏗️ Arhitektuur

```
Git Push
   │
   ▼
┌──────────────────────────────────────┐
│  CI Workflow (.github/workflows/ci.yml)│
│                                       │
│  Job 1: Lint                         │
│  ├─ Checkout code                    │
│  ├─ Setup Node 22                    │
│  ├─ npm ci                           │
│  └─ npm run lint ✓                   │
│      │                                │
│      ▼                                │
│  Job 2: Test (Matrix: Node 20, 22)  │
│  ├─ Checkout code                    │
│  ├─ Setup Node $version              │
│  ├─ npm ci                           │
│  ├─ npm test ✓                       │
│  └─ Upload coverage report           │
│      │                                │
│      ▼                                │
│  Job 3: Build                        │
│  ├─ Checkout code                    │
│  ├─ Docker Buildx setup              │
│  ├─ Login Docker Hub                 │
│  ├─ Build & Push image ✓             │
│  └─ Tag: branch-sha                  │
│      │                                │
│      ▼                                │
│  Job 4: Security                     │
│  ├─ Docker Scout scan                │
│  ├─ Trivy vulnerability scan         │
│  └─ Upload SARIF to GitHub ✓         │
│                                       │
└───────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Kopeeri User Service Kood (10 min)

```bash
# Navigate to your repository
cd user-service-cicd

# Copy backend-nodejs code
cp -r ../labs/apps/backend-nodejs/* .

# Verify
ls -la
# Should see: package.json, server.js, routes/, etc.
```

**Verifitseeri package.json scripts:**

```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest --coverage",
    "lint": "eslint ."
  }
}
```

Kui puudub, lisa:

```bash
npm install --save-dev eslint jest nodemon
```

### Samm 2: Loo CI Workflow (25 min)

**Loo `.github/workflows/ci.yml`:**

```yaml
name: Continuous Integration

on:
  push:
    branches: [main, develop, staging]
  pull_request:
    branches: [main]
  workflow_dispatch:

env:
  NODE_VERSION: '22'
  IMAGE_NAME: ${{ secrets.DOCKER_USERNAME }}/user-service

jobs:
  # ========================================
  # Job 1: Lint Code
  # ========================================
  lint:
    name: 🔍 Lint Code
    runs-on: ubuntu-latest
    timeout-minutes: 5

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🔧 Setup Node.js ${{ env.NODE_VERSION }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: 📦 Install dependencies
        run: npm ci

      - name: 🔍 Run ESLint
        run: npm run lint

  # ========================================
  # Job 2: Test (Matrix)
  # ========================================
  test:
    name: 🧪 Test (Node ${{ matrix.node-version }})
    runs-on: ubuntu-latest
    needs: lint
    timeout-minutes: 10

    strategy:
      matrix:
        node-version: [20, 22]

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🔧 Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: 📦 Install dependencies
        run: npm ci

      - name: 🧪 Run tests
        run: npm test
        env:
          NODE_ENV: test

      - name: 📊 Upload coverage (Node 22 only)
        if: matrix.node-version == 22
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/
          retention-days: 30

  # ========================================
  # Job 3: Build Docker Image
  # ========================================
  build:
    name: 🐳 Build Docker Image
    runs-on: ubuntu-latest
    needs: test
    timeout-minutes: 20

    permissions:
      contents: read
      packages: write

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🔧 Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: 🔐 Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: 🏷️ Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: 🐳 Build and push
        id: build
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64
          provenance: mode=max
          sbom: true

      - name: 📝 Image summary
        run: |
          echo "✅ Image built: ${{ env.IMAGE_NAME }}"
          echo "${{ steps.meta.outputs.tags }}"

  # ========================================
  # Job 4: Security Scanning
  # ========================================
  security:
    name: 🔒 Security Scan
    runs-on: ubuntu-latest
    needs: build
    timeout-minutes: 10

    permissions:
      contents: read
      security-events: write

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🔐 Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: 🐳 Docker Scout CVEs
        uses: docker/scout-action@v1
        with:
          command: cves
          image: ${{ env.IMAGE_NAME }}:${{ github.ref_name }}-${{ github.sha }}
          only-severities: critical,high
          exit-code: false

      - name: 🛡️ Trivy vulnerability scan
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: ${{ env.IMAGE_NAME }}:${{ github.ref_name }}-${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: 📊 Upload to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

  # ========================================
  # Summary
  # ========================================
  summary:
    name: 📋 CI Summary
    runs-on: ubuntu-latest
    needs: [lint, test, build, security]
    if: always()

    steps:
      - name: 📊 Print summary
        run: |
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "           CI Pipeline Summary              "
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "🔍 Lint:     ${{ needs.lint.result }}"
          echo "🧪 Test:     ${{ needs.test.result }}"
          echo "🐳 Build:    ${{ needs.build.result }}"
          echo "🔒 Security: ${{ needs.security.result }}"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          
          if [[ "${{ needs.lint.result }}" == "success" ]] && \
             [[ "${{ needs.test.result }}" == "success" ]] && \
             [[ "${{ needs.build.result }}" == "success" ]] && \
             [[ "${{ needs.security.result }}" == "success" ]]; then
            echo "✅ All checks passed!"
            exit 0
          else
            echo "❌ Some checks failed"
            exit 1
          fi
```

### Samm 3: Lisa Dockerfile (5 min)

Kui Dockerfile puudub, kopeeri Lab 1'st:

```bash
cp ../labs/01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized Dockerfile
```

### Samm 4: Test CI Workflow (10 min)

```bash
# Commit and push
git add .
git commit -m "Add CI workflow"
git push
```

**Vaata GitHub Actions:**
- Mine: https://github.com/YOUR-USERNAME/user-service-cicd/actions
- Kliki "Continuous Integration"
- Vaata kõiki 4 job'i

✅ **Kontrolli:**
- Lint ✅
- Test (2 jobs: Node 20 + 22) ✅
- Build ✅
- Security ✅

### Samm 5: Vaata Security Scan Tulemusi (10 min)

**GitHub Security tab:**

- Repository → Security → Code scanning alerts
- Vaata Trivy tulemusi
- Filtreeri: Critical + High

**Docker Scout:**

- Vaata workflow logs
- Security job → Docker Scout step
- CVE report

---

## ✅ Kontrolli Tulemusi

- [ ] CI workflow loodud (`.github/workflows/ci.yml`)
- [ ] Workflow käivitub push'il
- [ ] Lint job töötab
- [ ] Test job töötab mõlemal Node versioonil
- [ ] Docker image builds ja push'itakse
- [ ] Security scan completes
- [ ] Coverage report uploaditakse
- [ ] Kõik job'id on rohelised

---

## 🎓 Õpitud Mõisted

**CI Pipeline:**
- Automated quality checks
- Iga commit trigger'dab workflow'i
- Fail fast - leia bugid vara

**Matrix Strategy:**
- Paralleelsed run'id erinevate väärtustega
- Näide: test Node 20 + 22

**Docker Build Cache:**
- GitHub Actions cache (GHA)
- Kiirendab build'e (reuse layers)

**SBOM & Provenance:**
- Software Bill of Materials
- Build provenance (build metadata)
- Supply chain security

**SARIF:**
- Static Analysis Results Interchange Format
- Upload security results GitHub'i

---

## 💡 Best Practices

1. **Cache npm dependencies** - `cache: 'npm'`
2. **Matrix testing** - Test mitmel versioonil
3. **Job dependencies** - `needs: lint`
4. **Timeout** - Väldib stuck workflow'e
5. **Artifact retention** - 30 days coverage reports
6. **Security scanning** - Iga build'iga
7. **SARIF upload** - GitHub Security integration

---

## 🐛 Troubleshooting

### Lint fails?

```bash
# Local test
npm run lint

# Fix
npm run lint -- --fix
```

### Tests fail?

```bash
# Local test
npm test

# Debug
npm test -- --verbose
```

### Docker build fails?

```bash
# Local test
docker build -t user-service:test .

# Check Dockerfile syntax
```

### Security scan fails?

```bash
# Normal - vulnerabilities võivad eksisteerida
# Vaata GitHub Security tab
# Fix kritilised vulnerabilities
```

---

## 🔗 Järgmine Samm

Järgmises harjutuses automatiseerid **Helm deployment'i**!

**Jätka:** [Harjutus 3: Helm Deployment](03-helm-deployment.md)

---

## 📚 Viited

- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Docker Scout](https://docs.docker.com/scout/)
- [Trivy](https://github.com/aquasecurity/trivy)
- [Matrix Strategy](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)

---

**Õnnitleme! CI pipeline on valmis! 🎉**
