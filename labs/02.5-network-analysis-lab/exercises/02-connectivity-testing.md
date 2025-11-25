# Harjutus 2: Võrguühenduste Testimine (Connectivity Testing)

**Kestus:** 45 minutit
**Eesmärk:** Süstemaatiline võrguühenduste ja isolatsiooni testimine

---

## 📋 Ülevaade

Selles harjutuses õpid:
- DNS resolution'i ja service discovery testimist
- Port connectivity testing'ut connectivity matrix'i alusel
- HTTP endpoint'ide valideerimist
- Database connection'ide testimist
- Isolatsiooni verifikatsiooni (millised ühendused PEAKSID FAILIMA)

---

## ⚠️ Enne Alustamist

```bash
# Kontrolli, et Lab 2 stack töötab
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project
docker compose ps

# Oodatud: Kõik 5 teenust UP ja healthy
```

---

## 📝 Sammud

### Samm 1: DNS Resolution Testing (15 min)

#### 1.1. Docker Embedded DNS Mõistmine

Docker kasutab embedded DNS server'it (**127.0.0.11**), mis resolvib service name'id IP aadressideks.

**Kuidas see töötab:**
- Iga konteiner saab `/etc/resolv.conf` faili DNS server'iga 127.0.0.11
- Service name'd (nt. "user-service") resolvitakse IP aadressideks
- Ainult samas võrgus olevad teenused on resolvable

```bash
# Vaata frontend DNS konfiguratsiooni
docker compose exec frontend cat /etc/resolv.conf

# Oodatud väljund:
# nameserver 127.0.0.11
# options ndots:0
```

#### 1.2. Service Discovery Testing (nslookup)

**Test 1: Frontend → user-service (PEAKS TÖÖTAMA)**

```bash
# Frontend on backend-network'is koos user-service'ga
docker compose exec frontend nslookup user-service

# Oodatud väljund:
# Server:         127.0.0.11
# Address:        127.0.0.11:53
#
# Non-authoritative answer:
# Name:   user-service
# Address: 172.21.0.3    # IP backend-network'is

# ✅ ÕIGE: Service name resolved edukalt!
```

**Test 2: Frontend → postgres-user (PEAKS FAILIMA)**

```bash
# Frontend EI OLE database-network'is
docker compose exec frontend nslookup postgres-user

# Oodatud väljund:
# Server:         127.0.0.11
# Address:        127.0.0.11:53
#
# ** server can't find postgres-user: NXDOMAIN

# ✅ ÕIGE: Service ei ole visible (eri võrkudes)!
```

**Test 3: user-service → postgres-user (PEAKS TÖÖTAMA)**

```bash
# user-service ON database-network'is koos postgres-user'iga
docker compose exec user-service nslookup postgres-user

# Oodatud väljund:
# Name:   postgres-user
# Address: 172.22.0.4    # IP database-network'is

# ✅ ÕIGE: Backend saab ligi oma andmebaasile!
```

#### 1.3. Detailne DNS Testing (dig)

```bash
# Installi dig, kui puudub
docker compose exec frontend sh -c 'which dig || apk add --no-cache bind-tools'

# Test user-service DNS resolution'it
docker compose exec frontend dig user-service

# Oodatud väljund:
# ;; QUESTION SECTION:
# ;user-service.                 IN      A
#
# ;; ANSWER SECTION:
# user-service.           600     IN      A       172.21.0.3

# Näita ainult IP'd
docker compose exec frontend dig user-service +short

# Oodatud: 172.21.0.3 (või sarnane)
```

#### 1.4. DNS Response Time Testing

```bash
# Mõõda DNS query latentsust
docker compose exec frontend dig user-service +stats | grep "Query time"

# Oodatud väljund (näide):
# ;; Query time: 0 msec

# ✅ ÕIGE: Docker embedded DNS on väga kiire (<1ms)
```

---

### Samm 2: Port Connectivity Testing (15 min)

#### 2.1. Port Connectivity Matrix

Testime, millised ühendused PEAKSID TÖÖTAMA ja millised PEAKSID FAILIMA.

**Connectivity Matrix:**

```
┌────────────────┬──────────────┬──────────────┬──────────────┬────────────────┬────────────────┐
│ FROM \ TO      │ frontend:80  │ user-svc:3000│ todo-svc:8081│ postgres-u:5432│ postgres-t:5432│
├────────────────┼──────────────┼──────────────┼──────────────┼────────────────┼────────────────┤
│ frontend       │      -       │      ✅      │      ✅      │      ❌        │      ❌        │
│ user-service   │      ✅      │      -       │      ❌*     │      ✅        │      ❌        │
│ todo-service   │      ✅      │      ❌*     │      -       │      ❌        │      ✅        │
│ postgres-user  │      ❌      │      ❌      │      ❌      │      -         │      ❌        │
│ postgres-todo  │      ❌      │      ❌      │      ❌      │      ❌        │      -         │
└────────────────┴──────────────┴──────────────┴──────────────┴────────────────┴────────────────┘

Legend:
  ✅ = Should work (same network)
  ❌ = Should fail (different network / isolation)
  * = Technically works (both in backend-network), but not used
```

#### 2.2. Testing Expected Connectivity (nc -zv)

**Test 1: Frontend → user-service:3000 (✅ SHOULD WORK)**

```bash
docker compose exec frontend nc -zv user-service 3000

# Oodatud väljund:
# user-service (172.21.0.3:3000) open

# ✅ PASS: Frontend saab ligi user-service'ile
```

**Test 2: Frontend → todo-service:8081 (✅ SHOULD WORK)**

```bash
docker compose exec frontend nc -zv todo-service 8081

# Oodatud väljund:
# todo-service (172.21.0.4:8081) open

# ✅ PASS: Frontend saab ligi todo-service'ile
```

**Test 3: user-service → postgres-user:5432 (✅ SHOULD WORK)**

```bash
docker compose exec user-service nc -zv postgres-user 5432

# Oodatud väljund:
# postgres-user (172.22.0.4:5432) open

# ✅ PASS: user-service saab ligi oma andmebaasile
```

**Test 4: todo-service → postgres-todo:5432 (✅ SHOULD WORK)**

```bash
docker compose exec todo-service nc -zv postgres-todo 5432

# Oodatud väljund:
# postgres-todo (172.22.0.5:5432) open

# ✅ PASS: todo-service saab ligi oma andmebaasile
```

#### 2.3. Testing Expected Isolation (nc -zv)

**Test 5: Frontend → postgres-user:5432 (❌ SHOULD FAIL)**

```bash
docker compose exec frontend nc -zv postgres-user 5432 2>&1

# Oodatud väljund:
# nc: getaddrinfo for host "postgres-user" port 5432: Name or service not known

# ✅ PASS: Frontend EI SAA ligi andmebaasile (isoleeritud)!
```

**Test 6: Frontend → postgres-todo:5432 (❌ SHOULD FAIL)**

```bash
docker compose exec frontend nc -zv postgres-todo 5432 2>&1

# Oodatud väljund:
# nc: getaddrinfo for host "postgres-todo" port 5432: Name or service not known

# ✅ PASS: Frontend EI SAA ligi andmebaasile (isoleeritud)!
```

**Test 7: user-service → postgres-todo:5432 (❌ SHOULD FAIL)**

```bash
docker compose exec user-service nc -zv postgres-todo 5432 2>&1

# MÄRKUS: See VÕIB töötada, sest mõlemad on database-network'is!
# Aga rakenduslikult user-service EI KASUTA postgres-todo'd.

# Täiendav turvalisus: PostgreSQL autentimine (paroolid), firewall rules, K8s Network Policies
```

#### 2.4. Latency Testing (ping)

```bash
# Test latentsust frontend → user-service
docker compose exec frontend ping -c 5 user-service

# Oodatud väljund (näide):
# PING user-service (172.21.0.3): 56 data bytes
# 64 bytes from 172.21.0.3: seq=0 ttl=64 time=0.123 ms
# 64 bytes from 172.21.0.3: seq=1 ttl=64 time=0.089 ms
# ...
# --- user-service ping statistics ---
# 5 packets transmitted, 5 packets received, 0% packet loss
# round-trip min/avg/max = 0.089/0.106/0.123 ms

# ✅ KONTROLLI:
# - 0% packet loss
# - Latency <1ms (Docker same host)
```

---

### Samm 3: HTTP Endpoint Testing (10 min)

#### 3.1. User Service Health Check

```bash
# Test user-service health endpoint
docker compose exec frontend curl -v http://user-service:3000/health

# Oodatud väljund:
# * Connected to user-service (172.21.0.3) port 3000
# > GET /health HTTP/1.1
# > Host: user-service:3000
# >
# < HTTP/1.1 200 OK
# < Content-Type: application/json
# <
# {"status":"ok","database":"connected"}

# ✅ KONTROLLI:
# - HTTP 200 OK
# - {"status":"ok","database":"connected"}
```

#### 3.2. Todo Service Health Check

```bash
# Test todo-service health endpoint
docker compose exec frontend curl -v http://todo-service:8081/health

# Oodatud väljund:
# * Connected to todo-service (172.21.0.4) port 8081
# > GET /health HTTP/1.1
# > Host: todo-service:8081
# >
# < HTTP/1.1 200 OK
# < Content-Type: application/json
# <
# {"status":"UP"}

# ✅ KONTROLLI:
# - HTTP 200 OK
# - {"status":"UP"}
```

#### 3.3. HTTP Response Time Measurement

```bash
# Mõõda HTTP päringu aega (curl -w)
docker compose exec frontend curl -w "\nTime: %{time_total}s\n" -s -o /dev/null http://user-service:3000/health

# Oodatud väljund:
# Time: 0.012s

# ✅ KONTROLLI: <50ms on hea (Docker same host)
```

#### 3.4. Detailed HTTP Timing

```bash
# Loo timing format fail
docker compose exec frontend sh -c 'cat > /tmp/curl-timing.txt << EOF
    time_namelookup:  %{time_namelookup}s
       time_connect:  %{time_connect}s
    time_appconnect:  %{time_appconnect}s
      time_redirect:  %{time_redirect}s
   time_pretransfer:  %{time_pretransfer}s
time_starttransfer:  %{time_starttransfer}s
                      ----------
        time_total:  %{time_total}s
EOF'

# Test HTTP timing
docker compose exec frontend curl -w "@/tmp/curl-timing.txt" -o /dev/null -s http://user-service:3000/health

# Oodatud väljund (näide):
#     time_namelookup:  0.000123s    # DNS resolution
#        time_connect:  0.000456s    # TCP handshake
#     time_appconnect:  0.000000s    # SSL/TLS (N/A)
#       time_redirect:  0.000000s    # Redirect (N/A)
#    time_pretransfer:  0.000567s    # Pre-transfer
# time_starttransfer:  0.011234s    # First byte
#                       ----------
#         time_total:  0.011456s    # Total

# ✅ KONTROLLI:
# - time_namelookup <1ms (fast DNS)
# - time_total <50ms (good performance)
```

---

### Samm 4: Database Connection Testing (5 min)

#### 4.1. PostgreSQL Connection from user-service

```bash
# Test PostgreSQL ühendust user-service'st
docker compose exec user-service sh -c 'echo "SELECT version();" | psql -h postgres-user -U postgres -d user_service_db'

# Sisesta parool: postgres

# Oodatud väljund:
#                                                 version
# --------------------------------------------------------------------------------------------------------
#  PostgreSQL 16.x on x86_64-pc-linux-musl, compiled by gcc ...
# (1 row)

# ✅ PASS: user-service saab ühendust postgres-user'iga
```

#### 4.2. PostgreSQL Connection from todo-service

```bash
# Test PostgreSQL ühendust todo-service'st
docker compose exec todo-service sh -c 'psql -h postgres-todo -U postgres -d todo_service_db -c "SELECT version();"'

# Sisesta parool: postgres

# Oodatud väljund:
# PostgreSQL 16.x ...

# ✅ PASS: todo-service saab ühendust postgres-todo'ga
```

#### 4.3. Verify Database Isolation

```bash
# Test: Kas frontend SAAB ühendust postgres-user'iga? (PEAKS FAILIMA)
docker compose exec frontend sh -c 'timeout 5 nc -zv postgres-user 5432 2>&1'

# Oodatud väljund:
# nc: getaddrinfo for host "postgres-user" port 5432: Name or service not known

# ✅ PASS: Frontend EI SAA ligi andmebaasile!
```

---

## ✅ Connectivity Matrix Verification Script

Loo automatiseeritud skript, mis testib kogu connectivity matrix'i:

```bash
cat > /tmp/test-connectivity-matrix.sh << 'EOF'
#!/bin/bash
echo "==================================="
echo "Connectivity Matrix Verification"
echo "==================================="
echo ""

PASS=0
FAIL=0

# Helper function
test_connection() {
    local from=$1
    local to=$2
    local port=$3
    local expected=$4  # "pass" or "fail"

    echo -n "Testing $from → $to:$port ... "

    result=$(docker compose exec -T $from nc -zv $to $port 2>&1)

    if echo "$result" | grep -q "open"; then
        # Connection succeeded
        if [ "$expected" == "pass" ]; then
            echo "✅ PASS (expected)"
            ((PASS++))
        else
            echo "❌ FAIL (should be blocked!)"
            ((FAIL++))
        fi
    else
        # Connection failed
        if [ "$expected" == "fail" ]; then
            echo "✅ PASS (correctly blocked)"
            ((PASS++))
        else
            echo "❌ FAIL (should work!)"
            ((FAIL++))
        fi
    fi
}

cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project

# Expected to work
echo "Expected Connectivity:"
test_connection "frontend" "user-service" "3000" "pass"
test_connection "frontend" "todo-service" "8081" "pass"
test_connection "user-service" "postgres-user" "5432" "pass"
test_connection "todo-service" "postgres-todo" "5432" "pass"

echo ""
echo "Expected Isolation:"
test_connection "frontend" "postgres-user" "5432" "fail"
test_connection "frontend" "postgres-todo" "5432" "fail"

echo ""
echo "==================================="
echo "Summary: $PASS passed, $FAIL failed"
echo "==================================="

if [ $FAIL -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed!"
    exit 1
fi
EOF

chmod +x /tmp/test-connectivity-matrix.sh
/tmp/test-connectivity-matrix.sh
```

**Oodatud väljund:**

```
===================================
Connectivity Matrix Verification
===================================

Expected Connectivity:
Testing frontend → user-service:3000 ... ✅ PASS (expected)
Testing frontend → todo-service:8081 ... ✅ PASS (expected)
Testing user-service → postgres-user:5432 ... ✅ PASS (expected)
Testing todo-service → postgres-todo:5432 ... ✅ PASS (expected)

Expected Isolation:
Testing frontend → postgres-user:5432 ... ✅ PASS (correctly blocked)
Testing frontend → postgres-todo:5432 ... ✅ PASS (correctly blocked)

===================================
Summary: 6 passed, 0 failed
===================================
✅ All tests passed!
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **Testida DNS resolution'it** - `nslookup`, `dig`
- [ ] **Mõista Docker embedded DNS** - 127.0.0.11
- [ ] **Testida port connectivity'd** - `nc -zv`
- [ ] **Verifi fitseerida isolatsiooni** - millised ühendused failivad
- [ ] **Testida HTTP endpoint'e** - `curl -v`
- [ ] **Mõõta HTTP timing'uid** - `curl -w`
- [ ] **Testida database connections** - `psql`
- [ ] **Mõista connectivity matrix'it** - kes saab kellega suhelda

---

## 🐛 Levinud Probleemid

### Probleem 1: "nc: command not found"

```bash
# Alpine-based image's (nginx, postgres)
docker compose exec frontend apk add --no-cache netcat-openbsd

# Debian-based image's
docker compose exec user-service apt-get update && apt-get install -y netcat
```

### Probleem 2: "Frontend saab ligi postgres-user'ile" (❌ EI TOHIKS!)

```bash
# TURVARISK! Frontend on ka database-network'is!

# Lahendus: Paranda docker-compose.yml
# Frontend teenus PEAKS olema ainult:
networks:
  - frontend-network
  - backend-network
# MITTE database-network!

# Taaskäivita:
docker compose down && docker compose up -d
```

### Probleem 3: "DNS resolution failib, aga IP töötab"

```bash
# Test DNS
docker compose exec frontend nslookup user-service
# FAIL

# Test IP otse
docker compose exec frontend nc -zv 172.21.0.3 3000
# SUCCESS

# PROBLEEM: DNS broken, aga network töötab

# Lahendus: Taaskäivita Docker daemon
sudo systemctl restart docker
docker compose up -d
```

---

## 🔗 Järgmine Samm

Suurepärane! Connectivity testing on läbitud. Nüüd saad analüüsida liiklust sügavamalt.

**Järgmine harjutus:** [03-traffic-analysis.md](03-traffic-analysis.md) - Võrguliikluse analüüs tcpdump'iga!

---

**Viimane uuendus:** 2025-11-24
