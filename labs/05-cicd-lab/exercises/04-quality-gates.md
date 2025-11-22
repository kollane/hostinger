# Harjutus 4: Quality Gates & Testing

**Kestus:** 60 minutit
**Eesmärk:** Lisa quality gates ja post-deployment testing

---

## 📋 Ülevaade

Selles harjutuses **lisa quality gates**, mis blokeerivad deployment kui quality standards ei ole täidetud:
- Test coverage minimum (80%)
- All tests must pass
- No critical security vulnerabilities
- Post-deployment smoke tests
- Automated rollback kui deploy fails

**Quality Gates = Automatic quality checks:**
- Block bad code from production
- Enforce standards
- Reduce bugs
- Improve reliability

---

## 🎯 Õpieesmärgid

- ✅ Seadistada test coverage requirements
- ✅ Luua quality gates CI'sse
- ✅ Implementeerida smoke tests
- ✅ Automated rollback on failure
- ✅ Post-deployment validation

---

## 🏗️ Arhitektuur

```
CI Pipeline
   │
   ├─ Tests run
   │   └─ Coverage: 85% ✓
   │       (minimum: 80%)
   │
   ├─ Security scan
   │   └─ Critical CVEs: 0 ✓
   │       (block if > 0)
   │
   ▼
Quality Gate: PASS ✓
   │
   ▼
CD Pipeline
   │
   ├─ Deploy
   │
   ├─ Smoke Tests
   │   ├─ Health check ✓
   │   ├─ API endpoints ✓
   │   └─ Database connectivity ✓
   │
   └─ If smoke tests FAIL → Rollback
```

---

## 📝 Sammud

### Samm 1: Lisa Coverage Requirement (15 min)

**Update `package.json`:**

```json
{
  "scripts": {
    "test": "jest --coverage --coverageThreshold='{\"global\":{\"branches\":80,\"functions\":80,\"lines\":80,\"statements\":80}}'"
  },
  "jest": {
    "collectCoverageFrom": [
      "**/*.js",
      "!**/node_modules/**",
      "!**/coverage/**"
    ],
    "coverageReporters": ["text", "lcov", "json-summary"]
  }
}
```

**Test local:**

```bash
npm test

# Should fail if coverage < 80%
```

### Samm 2: Update CI Workflow - Quality Gates (20 min)

**Update `.github/workflows/ci.yml` test job:**

```yaml
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

      - name: 🧪 Run tests with coverage
        run: npm test
        env:
          NODE_ENV: test

      - name: 📊 Check coverage threshold
        if: matrix.node-version == 22
        run: |
          COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
          echo "Coverage: $COVERAGE%"
          
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "❌ Coverage below 80%: $COVERAGE%"
            exit 1
          fi
          
          echo "✅ Coverage meets threshold: $COVERAGE%"

      - name: 📊 Upload coverage
        if: matrix.node-version == 22
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/
          retention-days: 30

      - name: 💬 Comment coverage on PR
        if: matrix.node-version == 22 && github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const coverage = JSON.parse(fs.readFileSync('coverage/coverage-summary.json', 'utf8'));
            const pct = coverage.total.lines.pct;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 📊 Test Coverage\n\nCoverage: **${pct}%**\n\nMinimum: 80%\n\nStatus: ${pct >= 80 ? '✅ PASS' : '❌ FAIL'}`
            });
```

### Samm 3: Security Quality Gate (10 min)

**Update security job to fail on critical vulnerabilities:**

```yaml
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
          exit-code: true  # Fail workflow if critical CVEs found

      - name: 🛡️ Trivy scan
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: ${{ env.IMAGE_NAME }}:${{ github.ref_name }}-${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'  # Fail if vulnerabilities found

      - name: 📊 Upload to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
```

### Samm 4: Smoke Tests Post-Deployment (15 min)

**Loo `tests/smoke.sh`:**

```bash
#!/bin/bash
set -e

NAMESPACE=$1
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app=user-service -o jsonpath='{.items[0].metadata.name}')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Running Smoke Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Namespace: $NAMESPACE"
echo "Pod: $POD_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test 1: Health endpoint
echo "Test 1: Health check..."
HEALTH=$(kubectl exec -n $NAMESPACE $POD_NAME -- wget -qO- http://localhost:3000/health)
if echo "$HEALTH" | grep -q "healthy"; then
  echo "✅ Health check passed"
else
  echo "❌ Health check failed"
  exit 1
fi

# Test 2: Database connectivity
echo "Test 2: Database connectivity..."
READY=$(kubectl exec -n $NAMESPACE $POD_NAME -- wget -qO- http://localhost:3000/ready)
if echo "$READY" | grep -q "ready"; then
  echo "✅ Database connectivity OK"
else
  echo "❌ Database connectivity failed"
  exit 1
fi

# Test 3: API endpoint (list users)
echo "Test 3: API endpoint..."
kubectl exec -n $NAMESPACE $POD_NAME -- wget -qO- http://localhost:3000/api/users > /dev/null
if [ $? -eq 0 ]; then
  echo "✅ API endpoint accessible"
else
  echo "❌ API endpoint failed"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All smoke tests passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Make executable:**

```bash
chmod +x tests/smoke.sh
```

**Update CD workflow - add smoke tests:**

```yaml
      - name: 🧪 Smoke tests
        run: |
          ENV="${{ needs.determine-environment.outputs.environment }}"
          
          echo "🧪 Running smoke tests..."
          bash tests/smoke.sh $ENV

      - name: ⏮️ Rollback on failure
        if: failure()
        run: |
          ENV="${{ needs.determine-environment.outputs.environment }}"

          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "❌ Deployment failed, rolling back..."
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

          # Helm rollback
          helm rollback user-service 0 --namespace=$ENV --wait

          echo "✅ Rollback completed"
          
          # Show status
          helm status user-service --namespace=$ENV
```

---

## ✅ Kontrolli Tulemusi

- [ ] Coverage threshold 80% enforced
- [ ] CI fails kui coverage < 80%
- [ ] Security scan fails kui critical CVEs
- [ ] Smoke tests loodud (`tests/smoke.sh`)
- [ ] Smoke tests käivituvad post-deployment
- [ ] Automated rollback kui smoke tests fail
- [ ] Coverage comment PR'idel

---

## 🎓 Õpitud Mõisted

**Quality Gates:**
- Automated quality checks
- Block low-quality code
- Enforce standards

**Coverage Threshold:**
- Minimum test coverage %
- Ensures code is tested
- CI fails if not met

**Smoke Tests:**
- Basic functionality tests
- Post-deployment validation
- Quick sanity checks

**Automated Rollback:**
- Undo failed deployment
- Helm rollback command
- Restore previous version

---

## 💡 Best Practices

1. **Coverage threshold** - 80% minimum
2. **Fail fast** - Block bad deployments
3. **Smoke tests** - Always post-deploy
4. **Automated rollback** - Never manual
5. **PR comments** - Visibility to reviewers
6. **Security gates** - Block critical CVEs

---

## 🐛 Troubleshooting

### Coverage below threshold?

```bash
# Run coverage locally
npm test

# Find uncovered code
open coverage/lcov-report/index.html

# Write more tests
```

### Smoke tests fail?

```bash
# Debug manually
kubectl exec -n development <pod> -- wget -qO- http://localhost:3000/health

# Check logs
kubectl logs -n development <pod>
```

### Rollback fails?

```bash
# Check Helm history
helm history user-service -n development

# Manual rollback
helm rollback user-service <revision> -n development
```

---

## 🔗 Järgmine Samm

Viimases harjutuses lood **production pipeline** approval'ite ja notificationitega!

**Jätka:** [Harjutus 5: Production Pipeline](05-production-pipeline.md)

---

## 📚 Viited

- [Jest Coverage](https://jestjs.io/docs/configuration#coveragethreshold-object)
- [GitHub Script Action](https://github.com/actions/github-script)
- [Helm Rollback](https://helm.sh/docs/helm/helm_rollback/)

---

**Õnnitleme! Quality gates on seadistatud! 🎉**
