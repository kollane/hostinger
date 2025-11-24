# Harjutus 4: Automatiseeritud Testimine ja Security Audit

**Kestus:** 30 minutit
**Eesmärk:** Automated testing scripts, security auditing ja CI/CD integratsioon

---

## 📋 Ülevaade

Selles harjutuses õpid:
- Looma automated testing bash skripte
- Security auditing tööriistu kasutama
- Port scanning'u ja vulnerability assessment'i
- Load testing metoodikaid
- CI/CD testimise integratsi ooni

---

## ⚠️ Enne Alustamist

```bash
# Kontrolli, et Lab 2 stack töötab
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project
docker compose ps

# Installi nmap, kui puudub
which nmap || sudo apt-get install -y nmap
```

---

## 📝 Sammud

### Samm 1: Automated Network Testing Script (10 min)

#### 1.1. Põhiline Test Script

Loome comprehensive network testing skripti, mis testib kõiki harjutuste 1-3 aspekte automaatselt.

```bash
# Loo skript
cat > /tmp/test-network-full.sh << 'EOF'
#!/bin/bash
# ======================================================
# Comprehensive Network Testing Script
# Tests: Network inspection, connectivity, isolation
# ======================================================

set -e  # Exit on error

PROJECT_DIR="/home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project"
cd "$PROJECT_DIR"

echo "========================================================"
echo "  Docker Network Segmentation - Full Test Suite"
echo "========================================================"
echo ""

PASS=0
FAIL=0
TOTAL=0

# Helper: Test function
test_check() {
    local name="$1"
    local command="$2"
    local expected="$3"  # "pass" or "fail" or "contains:string"

    ((TOTAL++))
    echo -n "[$TOTAL] Testing: $name ... "

    set +e
    result=$(eval "$command" 2>&1)
    exit_code=$?
    set -e

    if [[ "$expected" == "pass" ]]; then
        if [ $exit_code -eq 0 ]; then
            echo "✅ PASS"
            ((PASS++))
        else
            echo "❌ FAIL"
            ((FAIL++))
            echo "  Error: $result"
        fi
    elif [[ "$expected" == "fail" ]]; then
        if [ $exit_code -ne 0 ]; then
            echo "✅ PASS (correctly failed)"
            ((PASS++))
        else
            echo "❌ FAIL (should have failed!)"
            ((FAIL++))
        fi
    elif [[ "$expected" == contains:* ]]; then
        search_string="${expected#contains:}"
        if echo "$result" | grep -q "$search_string"; then
            echo "✅ PASS"
            ((PASS++))
        else
            echo "❌ FAIL (expected '$search_string')"
            ((FAIL++))
            echo "  Got: $result"
        fi
    fi
}

echo "=== SECTION 1: Container Health ==="
test_check "All containers running" \
    "docker compose ps --format '{{.State}}' | grep -v 'running' | wc -l" \
    "contains:0"

echo ""
echo "=== SECTION 2: Network Existence ==="
test_check "frontend-network exists" \
    "docker network inspect frontend-network >/dev/null 2>&1" \
    "pass"

test_check "backend-network exists" \
    "docker network inspect backend-network >/dev/null 2>&1" \
    "pass"

test_check "database-network exists" \
    "docker network inspect database-network >/dev/null 2>&1" \
    "pass"

echo ""
echo "=== SECTION 3: Network Configuration ==="
test_check "database-network is internal" \
    "docker network inspect database-network | jq -r '.[0].Internal'" \
    "contains:true"

test_check "frontend in frontend-network" \
    "docker network inspect frontend-network | jq -r '.[0].Containers' | grep -q 'frontend'" \
    "pass"

test_check "frontend in backend-network" \
    "docker network inspect backend-network | jq -r '.[0].Containers' | grep -q 'frontend'" \
    "pass"

test_check "user-service in backend-network" \
    "docker network inspect backend-network | jq -r '.[0].Containers' | grep -q 'user-service'" \
    "pass"

test_check "user-service in database-network" \
    "docker network inspect database-network | jq -r '.[0].Containers' | grep -q 'user-service'" \
    "pass"

test_check "postgres-user in database-network" \
    "docker network inspect database-network | jq -r '.[0].Containers' | grep -q 'postgres-user'" \
    "pass"

echo ""
echo "=== SECTION 4: DNS Resolution ==="
test_check "Frontend can resolve user-service" \
    "docker compose exec -T frontend nslookup user-service >/dev/null 2>&1" \
    "pass"

test_check "Frontend CANNOT resolve postgres-user" \
    "docker compose exec -T frontend nslookup postgres-user >/dev/null 2>&1" \
    "fail"

test_check "user-service can resolve postgres-user" \
    "docker compose exec -T user-service nslookup postgres-user >/dev/null 2>&1" \
    "pass"

echo ""
echo "=== SECTION 5: Connectivity ==="
test_check "Frontend → user-service:3000" \
    "docker compose exec -T frontend timeout 2 nc -zv user-service 3000 2>&1" \
    "contains:open"

test_check "Frontend → todo-service:8081" \
    "docker compose exec -T frontend timeout 2 nc -zv todo-service 8081 2>&1" \
    "contains:open"

test_check "user-service → postgres-user:5432" \
    "docker compose exec -T user-service timeout 2 nc -zv postgres-user 5432 2>&1" \
    "contains:open"

echo ""
echo "=== SECTION 6: Isolation (должны failit) ==="
test_check "Frontend CANNOT reach postgres-user:5432" \
    "docker compose exec -T frontend timeout 2 nc -zv postgres-user 5432 2>&1" \
    "fail"

test_check "Frontend CANNOT reach postgres-todo:5432" \
    "docker compose exec -T frontend timeout 2 nc -zv postgres-todo 5432 2>&1" \
    "fail"

echo ""
echo "=== SECTION 7: HTTP Endpoints ==="
test_check "user-service health endpoint" \
    "docker compose exec -T frontend curl -sf http://user-service:3000/health" \
    "contains:ok"

test_check "todo-service health endpoint" \
    "docker compose exec -T frontend curl -sf http://todo-service:8081/health" \
    "contains:UP"

echo ""
echo "=== SECTION 8: Public Port Exposure ==="
PUBLIC_PORTS=$(sudo lsof -i -P -n | grep LISTEN | grep docker-proxy | grep -c "\*:" || echo "0")
test_check "Only 1 public port exposed (frontend:8080)" \
    "echo $PUBLIC_PORTS" \
    "contains:1"

echo ""
echo "========================================================"
echo "  TEST SUMMARY"
echo "========================================================"
echo "Total tests: $TOTAL"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✅ ALL TESTS PASSED! Network segmentation is correct."
    exit 0
else
    echo "❌ SOME TESTS FAILED! Review network configuration."
    exit 1
fi
EOF

chmod +x /tmp/test-network-full.sh
```

#### 1.2. Käivita Automated Test

```bash
# Käivita test suite
/tmp/test-network-full.sh

# Oodatud väljund:
# ========================================================
#   Docker Network Segmentation - Full Test Suite
# ========================================================
#
# === SECTION 1: Container Health ===
# [1] Testing: All containers running ... ✅ PASS
#
# === SECTION 2: Network Existence ===
# [2] Testing: frontend-network exists ... ✅ PASS
# [3] Testing: backend-network exists ... ✅ PASS
# [4] Testing: database-network exists ... ✅ PASS
# ...
# === SECTION 8: Public Port Exposure ===
# [20] Testing: Only 1 public port exposed ... ✅ PASS
#
# ========================================================
#   TEST SUMMARY
# ========================================================
# Total tests: 20
# Passed: 20
# Failed: 0
#
# ✅ ALL TESTS PASSED! Network segmentation is correct.
```

#### 1.3. CI/CD Integration

Skript on valmis GitHub Actions, GitLab CI või muu CI/CD integratsiooniks:

```yaml
# .github/workflows/network-test.yml (näide)
name: Network Segmentation Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Start Docker Compose stack
        run: |
          cd 02-docker-compose-lab/compose-project
          docker compose up -d
          sleep 10  # Wait for healthchecks
      - name: Run network tests
        run: |
          bash /tmp/test-network-full.sh
```

---

### Samm 2: Security Audit (10 min)

#### 2.1. Port Scanning (nmap)

**Scan host'i avalikke porte:**

```bash
# Skaneeri localhost porte
sudo nmap -sT localhost -p 1-10000

# Oodatud väljund:
# Starting Nmap ...
# Nmap scan report for localhost (127.0.0.1)
# PORT     STATE SERVICE
# 8080/tcp open  http-proxy    # ✅ Frontend - OK
#
# Nmap done: 1 IP address scanned

# ✅ KONTROLLI: Ainult port 8080 peaks olema open
# Kui näed 3000, 8081, 5432, 5433 → ❌ TURVARISK!
```

**Detailne port scan:**

```bash
# Skaneeri koos service detection'iga
sudo nmap -sV localhost -p 8080,3000,8081,5432,5433

# Oodatud väljund:
# PORT     STATE    SERVICE     VERSION
# 8080/tcp open     http        nginx
# 3000/tcp filtered unknown     # ✅ filtered = blocked
# 8081/tcp filtered unknown     # ✅ filtered = blocked
# 5432/tcp filtered postgresql  # ✅ filtered = blocked
# 5433/tcp filtered unknown     # ✅ filtered = blocked
```

#### 2.2. Exposed Ports Verification (lsof)

```bash
# Kontrolli, millised pordid on avalikult ligipääsetavad
sudo lsof -i -P -n | grep LISTEN | grep docker-proxy

# Oodatud väljund:
# docker-pr ... *:8080 (LISTEN)              # ✅ Frontend - OK
# docker-pr ... 127.0.0.1:3000 (LISTEN)      # ✅ Localhost-only - OK
# docker-pr ... 127.0.0.1:8081 (LISTEN)      # ✅ Localhost-only - OK
# docker-pr ... 127.0.0.1:5432 (LISTEN)      # ✅ Localhost-only - OK
# docker-pr ... 127.0.0.1:5433 (LISTEN)      # ✅ Localhost-only - OK

# ✅ KONTROLLI:
# - Ainult 8080 on *:port (avalik)
# - Teised on 127.0.0.1:port (localhost-only)
```

#### 2.3. Container Capabilities Audit

```bash
# Kontrolli, kas konteinerid töötavad minimaalse privileegia tasemega
docker inspect frontend | jq '.[0].HostConfig | {Privileged, CapAdd, CapDrop}'

# Oodatud väljund:
# {
#   "Privileged": false,        # ✅ Not privileged
#   "CapAdd": null,              # ✅ No added capabilities
#   "CapDrop": null              # Could drop more for hardening
# }

# ✅ KONTROLLI: Privileged peaks olema false
```

#### 2.4. Docker Scout Vulnerability Scan

```bash
# Skaneeri Docker image vulnerabilities (vajab Docker Scout)
docker scout quickview user-service:1.0-optimized

# Oodatud väljund (näide):
#   ✓ Image stored for indexing
#   ✓ Indexed 123 packages
#   ✓ No vulnerabilities found
#
#   ## Overview
#   packages: 123
#   vulnerabilities: 0 (0 critical, 0 high, 0 medium, 0 low)

# Kui leitakse vulnerabilities:
docker scout cves user-service:1.0-optimized

# Näitab detailset CVE nimekirja
```

---

### Samm 3: Load Testing (5 min)

#### 3.1. Simple Load Test

```bash
# Test 100 paralleelset päringut
cat > /tmp/load-test.sh << 'EOF'
#!/bin/bash
echo "Starting load test: 100 parallel requests"
echo ""

cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project

start_time=$(date +%s)

for i in {1..100}; do
    docker compose exec -T frontend curl -s -o /dev/null http://user-service:3000/health &
done

wait

end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo "Load test completed:"
echo "  Requests: 100"
echo "  Duration: ${duration}s"
echo "  Throughput: $((100 / duration)) req/s"

if [ $duration -lt 5 ]; then
    echo "  Status: ✅ PASS (good performance)"
else
    echo "  Status: ⚠️  SLOW (review performance)"
fi
EOF

chmod +x /tmp/load-test.sh
/tmp/load-test.sh

# Oodatud väljund:
# Starting load test: 100 parallel requests
#
# Load test completed:
#   Requests: 100
#   Duration: 2s
#   Throughput: 50 req/s
#   Status: ✅ PASS (good performance)
```

#### 3.2. Stress Test (Connection Pool)

```bash
# Test database connection pool limits
cat > /tmp/stress-test-db.sh << 'EOF'
#!/bin/bash
echo "Database connection stress test"
echo ""

cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project

# Monitor initial connections
initial=$(docker compose exec -T postgres-user psql -U postgres -d user_service_db -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname='user_service_db';" | tr -d ' ')

echo "Initial connections: $initial"
echo "Creating 50 parallel connections..."

for i in {1..50}; do
    docker compose exec -T user-service node -e "
        const { Client } = require('pg');
        const client = new Client({
            host: 'postgres-user',
            database: 'user_service_db',
            user: 'postgres',
            password: 'postgres'
        });
        client.connect();
        setTimeout(() => client.end(), 5000);
    " &
done

sleep 1

# Check peak connections
peak=$(docker compose exec -T postgres-user psql -U postgres -d user_service_db -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname='user_service_db';" | tr -d ' ')

echo "Peak connections: $peak"

wait

final=$(docker compose exec -T postgres-user psql -U postgres -d user_service_db -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname='user_service_db';" | tr -d ' ')

echo "Final connections: $final"
echo ""
echo "Connection pool handled $((peak - initial)) concurrent connections"
EOF

chmod +x /tmp/stress-test-db.sh
/tmp/stress-test-db.sh
```

---

### Samm 4: Production-Ready Test Suite (5 min)

#### 4.1. All-in-One Test Script

Kopeeri valmisskriptid solutions/ kausta:

```bash
# Kopeeri test skriptid solutions kausta
cd /home/janek/projects/hostinger/labs/02.5-network-analysis-lab

cp /tmp/test-network-full.sh solutions/test-network-segmentation.sh
cp /tmp/load-test.sh solutions/test-performance.sh

# Loo security audit skript
cat > solutions/security-audit.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "  Security Audit - Network Segmentation"
echo "=========================================="
echo ""

echo "=== 1. Port Exposure Check ==="
echo "Public ports (should be only :8080):"
sudo lsof -i -P -n | grep LISTEN | grep docker-proxy | grep "\*:"

echo ""
echo "=== 2. Port Scan (nmap) ==="
sudo nmap -sT localhost -p 8080,3000,8081,5432,5433

echo ""
echo "=== 3. Container Privileges ==="
for container in frontend user-service todo-service; do
    priv=$(docker inspect $container | jq -r '.[0].HostConfig.Privileged')
    echo "$container: Privileged=$priv"
done

echo ""
echo "=== 4. Network Isolation Check ==="
internal=$(docker network inspect database-network | jq -r '.[0].Internal')
if [ "$internal" == "true" ]; then
    echo "✅ database-network is internal: true"
else
    echo "❌ database-network is NOT internal!"
fi

echo ""
echo "=========================================="
echo "  Security Audit Complete"
echo "=========================================="
EOF

chmod +x solutions/security-audit.sh

# Käivita security audit
./solutions/security-audit.sh
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Automated test script** - test-network-segmentation.sh
- [ ] **Security audit script** - security-audit.sh
- [ ] **Load test script** - test-performance.sh
- [ ] **Port scanning oskused** - nmap
- [ ] **Vulnerability scanning** - Docker Scout
- [ ] **CI/CD integration** - GitHub Actions ready
- [ ] **Production-ready monitoring** - Bash scripts

---

## 🎓 Õpitud Mõisted

### Automated Testing:

- **Test Suite** - Testide kogu, mis testib kogu süsteemi
- **Pass/Fail Reporting** - Selge tulemus (exit code 0 vs 1)
- **CI/CD Integration** - Automated testid build pipeline'is
- **Regression Testing** - Veendu, et muudatused ei puruks asju

### Security Auditing:

- **Port Scanning** - nmap, avalike portide tuvastamine
- **Vulnerability Assessment** - CVE scanning (Docker Scout)
- **Least Privilege** - Minimaalsed õigused konteineritele
- **Attack Surface** - Avalikud entry point'id

### Performance Testing:

- **Load Testing** - Süsteemi käitumine koormuse all
- **Stress Testing** - Piiride testimine (connection pool)
- **Throughput** - Päringuid sekundis (req/s)
- **Capacity Planning** - Kui palju süsteem võib taluda

---

## 🐛 Levinud Probleemid

### Probleem 1: "test-network-full.sh fails with timeout"

```bash
# PROBLEEM: Konteinerid ei vasta aegsasti

# Lahendus: Suurenda timeout'e skriptis
# Muuda: timeout 2 → timeout 5
sed -i 's/timeout 2/timeout 5/g' /tmp/test-network-full.sh
```

### Probleem 2: "nmap: command not found"

```bash
# Installi nmap
sudo apt-get update && sudo apt-get install -y nmap
```

### Probleem 3: "Docker Scout not available"

```bash
# Docker Scout on vanem kui Docker 23.0 või vajab login'it

# Alternatiiv: Kasuta Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy image user-service:1.0-optimized
```

---

## 🔗 Järgmine Samm

🎉 **Õnnitleme! Oled läbinud kõik Lab 2.5 harjutused!**

Nüüd oskad:
- ✅ Inspekteerida Docker võrke professionaalselt
- ✅ Testida võrguühendusi süstemaatiliselt
- ✅ Analüüsida võrguliiklust
- ✅ Automatiseerida network teste
- ✅ Auditeerida network security'd

### Mis edasi?

**Variant A: Jätka Kubernetes'ega**
→ [Lab 3: Kubernetes Basics](../../03-kubernetes-basics-lab/README.md)

**Variant B: Korda ja harjuta**
- Modifitseeri test skripte
- Lisa rohkem teste
- Proovi erinevaid stsenaariume

**Variant C: Prod Deployment**
- Kasuta neid skripte production deployments'is
- Integreeri CI/CD pipeline'i
- Automatiseeri monitooringut

---

**Viimane uuendus:** 2025-11-24
