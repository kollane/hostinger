# Harjutus 3: Liikluse Analüüs ja Monitooring (Traffic Analysis & Monitoring)

**Kestus:** 45 minutit
**Eesmärk:** Võrguliikluse analüüs ja jõudluse monitooring professionaalsete tööriistadega

---

## 📋 Ülevaade

Selles harjutuses õpid:
- Packet capture `tcpdump`'iga
- Traffic filtering (port, protocol, host)
- Connection monitoring (`ss`, `netstat`)
- Performance analysis (latency, throughput)
- DNS traffic analysis
- Bottleneck detection

---

## ⚠️ Enne Alustamist

```bash
# Kontrolli, et Lab 2 stack töötab
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project
docker compose ps

# Installi vajalikud tööriistad
# tcpdump on tavaliselt juba olemas Linux süsteemides
```

---

## 📝 Sammud

### Samm 1: Packet Capture Põhitõed (tcpdump) (15 min)

#### 1.1. tcpdump Põhikäsud

```bash
# Jälgi KOGU liiklust frontend konteineris
docker compose exec frontend tcpdump -i eth0 -n

# Väljund näeb välja umbes nii:
# 21:30:45.123456 IP 172.21.0.2.54321 > 172.21.0.3.3000: Flags [S], seq 123, win 64240
# 21:30:45.123789 IP 172.21.0.3.3000 > 172.21.0.2.54321: Flags [S.], seq 456, ack 124, win 65160
# ...

# Selgitus:
# - Timestamp: 21:30:45.123456
# - Source: 172.21.0.2.54321 (frontend)
# - Destination: 172.21.0.3.3000 (user-service)
# - Flags: [S] = SYN (connection establishment)

# Peata: Ctrl+C
```

**tcpdump Flag'id:**
- `-i eth0` - Interface (eth0 on Docker container'i network interface)
- `-n` - Ära resolve hostnames/ports (kiirem)
- `-v` - Verbose (rohkem infot)
- `-c 10` - Capture ainult 10 paketti
- `-w file.pcap` - Salvesta faili (Wireshark'iga analüüsimiseks)

#### 1.2. Capture Piiratud Arv Pakette

```bash
# Jälgi ainult 10 paketti
docker compose exec frontend tcpdump -i eth0 -n -c 10

# Oodatud: Peale 10 paketti tcpdump lõpetab automaatselt
```

#### 1.3. Quiet Mode (ainult statistika)

```bash
# Näita ainult kokkuvõtet (ei prindi iga paketti)
docker compose exec frontend tcpdump -i eth0 -n -c 100 -q

# Oodatud väljund lõpus:
# 100 packets captured
# 100 packets received by filter
# 0 packets dropped by kernel
```

---

### Samm 2: Traffic Filtering (15 min)

#### 2.1. Filter Port'i Järgi

**Jälgi ainult HTTP liiklust user-service'ile (port 3000):**

```bash
docker compose exec frontend tcpdump -i eth0 'port 3000' -n

# Nüüd tee päring teises terminalis:
# docker compose exec frontend curl http://user-service:3000/health

# Näed:
# - SYN packet (connection establishment)
# - SYN-ACK packet
# - ACK packet
# - HTTP GET request
# - HTTP response
# - FIN packets (connection close)
```

**Jälgi ainult PostgreSQL liiklust (port 5432):**

```bash
docker compose exec user-service tcpdump -i eth0 'port 5432' -n -c 20

# Teises terminalis tee database query:
# docker compose exec user-service node -e "require('pg').Client..."

# Näed PostgreSQL protocol pakette
```

#### 2.2. Filter Host'i Järgi

**Jälgi ainult liiklust konkreetsele IP'le:**

```bash
# Leia user-service IP
USER_SERVICE_IP=$(docker inspect user-service | jq -r '.[0].NetworkSettings.Networks["backend-network"].IPAddress')

echo "user-service IP: $USER_SERVICE_IP"

# Jälgi ainult liiklust user-service'ile
docker compose exec frontend tcpdump -i eth0 "host $USER_SERVICE_IP" -n -c 10
```

#### 2.3. Filter Protocol'i Järgi

**Jälgi ainult TCP liiklust:**

```bash
docker compose exec frontend tcpdump -i eth0 'tcp' -n -c 10
```

**Jälgi ainult DNS päringuid (UDP port 53):**

```bash
docker compose exec frontend tcpdump -i eth0 'udp port 53' -n

# Teises terminalis:
# docker compose exec frontend nslookup user-service

# Näed DNS query ja response
```

#### 2.4. Kombineeritud Filtrid

**Jälgi HTTP liiklust user-service'ile VÕI todo-service'ile:**

```bash
docker compose exec frontend tcpdump -i eth0 'port 3000 or port 8081' -n
```

**Jälgi HTTP GET päringuid:**

```bash
docker compose exec frontend tcpdump -i eth0 'tcp port 3000 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' -A -n

# -A flag näitab ASCII väljundit (HTTP headers)
```

**Lihtsam variant (ainult HTTP text):**

```bash
docker compose exec frontend tcpdump -i eth0 'port 3000' -A -n | grep "GET\|POST\|HTTP"
```

---

### Samm 3: Connection Monitoring (ss, netstat) (10 min)

#### 3.1. Active Connections (ss)

```bash
# Näita KÕIKI aktiivseid TCP/UDP connections
docker compose exec user-service ss -tunap

# Oodatud väljund (näide):
# Netid  State   Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
# tcp    LISTEN  0       511     0.0.0.0:3000         0.0.0.0:*          users:(("node",pid=1,fd=19))
# tcp    ESTAB   0       0       172.21.0.3:3000      172.21.0.2:54321   users:(("node",pid=1,fd=21))
# tcp    ESTAB   0       0       172.22.0.2:45678     172.22.0.4:5432    users:(("node",pid=1,fd=23))

# Selgitus:
# - LISTEN: user-service kuulab port'i 3000
# - ESTAB: Aktiivne ühendus frontend'iga (172.21.0.2:54321)
# - ESTAB: Aktiivne ühendus postgres-user'iga (172.22.0.4:5432)
```

**ss Flag'id:**
- `-t` - TCP connections
- `-u` - UDP connections
- `-n` - Ära resolve hostnames (numbrid)
- `-a` - All (listening + established)
- `-p` - Process info

#### 3.2. Listening Ports

```bash
# Näita ainult LISTENING porte
docker compose exec user-service ss -tlnp

# Oodatud väljund:
# State   Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
# LISTEN  0       511     0.0.0.0:3000        0.0.0.0:*          users:(("node",pid=1,fd=19))

# ✅ KONTROLLI: user-service kuulab port'i 3000
```

**Frontend listening ports:**

```bash
docker compose exec frontend ss -tlnp

# Oodatud:
# LISTEN  0.0.0.0:80    # Nginx
```

#### 3.3. Connection States

```bash
# Näita ainult ESTABLISHED ühendusi
docker compose exec user-service ss -tn state established

# Oodatud: Aktiivsed ühendused frontend'i ja postgres'ega
```

**Võimalikud state'd:**
- `LISTEN` - Kuulab porte (server)
- `ESTAB` (ESTABLISHED) - Aktiivne ühendus
- `TIME-WAIT` - Ühendus suletud, ootab timeout'i
- `CLOSE-WAIT` - Teine pool sulges ühenduse
- `SYN-SENT` - Connection establishment (client)
- `SYN-RECV` - Connection establishment (server)

#### 3.4. netstat (vanem alternatiiv ss'ile)

```bash
# netstat on vanem, aga veel laialdaselt kasutusel
docker compose exec user-service netstat -tlnp

# Sarnane väljund ss'iga
```

---

### Samm 4: Performance Analysis (10 min)

#### 4.1. Latency Measurement

**Ping latency:**

```bash
# Mõõda latentsust frontend → user-service
docker compose exec frontend ping -c 10 user-service | tail -1

# Oodatud väljund:
# rtt min/avg/max/mdev = 0.089/0.123/0.234/0.045 ms

# ✅ KONTROLLI:
# - avg <1ms (Docker same host on väga kiire)
# - mdev väike (stabiilne)
```

**HTTP latency (curl timing):**

```bash
# Detailne HTTP timing
docker compose exec frontend sh -c '
for i in {1..10}; do
  curl -w "Request $i: %{time_total}s\n" -s -o /dev/null http://user-service:3000/health
done
'

# Oodatud väljund:
# Request 1: 0.012s
# Request 2: 0.009s
# Request 3: 0.011s
# ...
# Request 10: 0.010s

# Arvuta keskmine:
# (0.012 + 0.009 + ... + 0.010) / 10 ≈ 0.010s = 10ms

# ✅ KONTROLLI: avg <50ms on hea
```

#### 4.2. Throughput Testing

**Simple throughput test (parallel requests):**

```bash
# Tee 100 päringut paralleelselt
docker compose exec frontend sh -c '
for i in {1..100}; do
  curl -s http://user-service:3000/health &
done
wait
echo "100 requests completed"
'

# Mõõda aega
time docker compose exec frontend sh -c '
for i in {1..100}; do
  curl -s -o /dev/null http://user-service:3000/health &
done
wait
'

# Oodatud väljund:
# real    0m2.123s    # 100 requests in 2.1s = ~47 req/s
# user    0m0.234s
# sys     0m0.456s

# ✅ KONTROLLI:
# - real <5s on OK small scale test'iks
# - Throughput: 100 / real_time = requests per second
```

#### 4.3. Connection Pool Analysis

**PostgreSQL connection count:**

```bash
# Mitu ühendust on postgres-user'iga?
docker compose exec postgres-user psql -U postgres -d user_service_db -c "SELECT count(*) FROM pg_stat_activity WHERE datname='user_service_db';"

# Oodatud väljund:
#  count
# -------
#      2    # Näiteks: 1 psql + 1 user-service connection
# (1 row)
```

**Monitor connections realtime:**

```bash
# Jälgi ühendusi reaalajas (10s intervals)
watch -n 10 "docker compose exec -T postgres-user psql -U postgres -d user_service_db -c \"SELECT count(*) FROM pg_stat_activity WHERE datname='user_service_db';\""

# Peata: Ctrl+C
```

---

### Samm 5: DNS Traffic Analysis (5 min)

#### 5.1. DNS Query Monitoring

```bash
# Jälgi DNS päringuid
docker compose exec frontend tcpdump -i eth0 'udp port 53' -n -c 5

# Teises terminalis tee päring:
# docker compose exec frontend nslookup user-service

# Näed:
# 1. DNS query: frontend → 127.0.0.11 (Docker embedded DNS)
# 2. DNS response: 127.0.0.11 → frontend (IP: 172.21.0.3)
```

#### 5.2. DNS Timing

```bash
# Mõõda DNS resolution aega
docker compose exec frontend time nslookup user-service

# Oodatud väljund:
# ...
# real    0m0.003s    # DNS resolution <5ms
# user    0m0.001s
# sys     0m0.002s

# ✅ KONTROLLI: Docker embedded DNS on väga kiire (<5ms)
```

---

## ✅ Traffic Analysis Script

Loo automatiseeritud skript traffic monitoring'uks:

```bash
cat > /tmp/monitor-traffic.sh << 'EOF'
#!/bin/bash
echo "==================================="
echo "Traffic Monitoring Tool"
echo "==================================="
echo ""

CONTAINER=${1:-user-service}
DURATION=${2:-10}

cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project

echo "Monitoring container: $CONTAINER"
echo "Duration: ${DURATION}s"
echo ""

echo "=== Active Connections ==="
docker compose exec $CONTAINER ss -tn state established

echo ""
echo "=== Listening Ports ==="
docker compose exec $CONTAINER ss -tlnp

echo ""
echo "=== Capturing $DURATION seconds of traffic ==="
timeout $DURATION docker compose exec $CONTAINER tcpdump -i eth0 -n -c 50 2>&1 | head -20

echo ""
echo "=== Traffic Summary ==="
echo "Captured $(timeout $DURATION docker compose exec $CONTAINER tcpdump -i eth0 -n -c 100 -q 2>&1 | grep "packets captured" | awk '{print $1}') packets in ${DURATION}s"

EOF

chmod +x /tmp/monitor-traffic.sh
/tmp/monitor-traffic.sh user-service 5
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **Kasutada tcpdump'i** - packet capture, filtering
- [ ] **Filtreerida liiklust** - port, host, protocol
- [ ] **Monitoorida connections'id** - `ss -tunap`, `netstat`
- [ ] **Analüüsida connection state'sid** - LISTEN, ESTAB, TIME-WAIT
- [ ] **Mõõta latentsust** - ping, curl timing
- [ ] **Testida throughput'i** - parallel requests
- [ ] **Jälgida DNS traffic'ut** - UDP port 53
- [ ] **Luua monitoring skripte** - automatiseeritud analüüs

---

## 🎓 Õpitud Mõisted

### tcpdump Concepts:

- **Packet Capture** - Võrguliikluse salvestamine
- **Filter Expression** - BPF (Berkeley Packet Filter) syntax
- **PCAP File** - Salvestatud liiklus Wireshark'ile
- **Promiscuous Mode** - Kuula KOGU liiklust (mitte ainult enda)

### Connection States:

- **LISTEN** - Server ootab ühendusi
- **ESTABLISHED** - Aktiivne ühendus
- **TIME-WAIT** - Ühendus suletud, cleanup
- **CLOSE-WAIT** - Peer sulges, local pool sulgemata

### Performance Metrics:

- **Latency** - Aeg päringu ja vastuse vahel
- **Throughput** - Päringuid sekundis (req/s)
- **RTT (Round-Trip Time)** - Ping aeg
- **Connection Pool** - Pooled persistent connections

---

## 🐛 Levinud Probleemid

### Probleem 1: "tcpdump: eth0: You don't have permission to capture on that device"

```bash
# PROBLEEM: tcpdump vajab root õigusi

# Lahendus: Käivita docker compose exec ilma -T flag'ita
docker compose exec frontend tcpdump -i eth0 -n -c 10

# VÕI kasuta sudo host'is (väljaspool konteinerit)
sudo tcpdump -i docker0 -n
```

### Probleem 2: "tcpdump: command not found"

```bash
# Installi tcpdump konteinerisse
# Alpine (nginx, etc):
docker compose exec frontend apk add --no-cache tcpdump

# Debian/Ubuntu:
docker compose exec user-service apt-get update && apt-get install -y tcpdump
```

### Probleem 3: "ss: command not found"

```bash
# Kasuta netstat alternatiivina
docker compose exec user-service netstat -tlnp

# VÕI installi iproute2
docker compose exec user-service apt-get install -y iproute2
```

---

## 🔗 Järgmine Samm

Suurepärane! Traffic analysis oskused on omandatud. Nüüd automatiseerime testid.

**Järgmine harjutus:** [04-automated-testing.md](04-automated-testing.md) - Automated testing ja security audit!

---

**Viimane uuendus:** 2025-11-24
