# Võrdlus: Nginx vs Kubernetes Ingress

**Eesmärk:** Aitab sul valida õige reverse proxy lahendust oma projekti jaoks

---

## 📊 Kiire Ülevaade

| Kriteerium | Nginx (VPS) | Kubernetes Ingress | Võitja |
|------------|-------------|-------------------|--------|
| **Õppimiskõver** | Keskmine | Kõrge | 🏆 Nginx |
| **Paigalduskiirus** | 5 min | 20 min | 🏆 Nginx |
| **Skaleeritavus** | Piiratud | Väga hea | 🏆 Ingress |
| **Automaatika** | Madal | Kõrge | 🏆 Ingress |
| **Hind (väike projekt)** | $5-10/kuu (VPS) | $20-50/kuu (K8s) | 🏆 Nginx |
| **Hind (suur projekt)** | $100-500/kuu | $50-200/kuu | 🏆 Ingress |
| **Tõrkekindlus** | Madal (SPOF) | Kõrge (HA) | 🏆 Ingress |
| **Muudatuste kiirus** | SSH + vim + reload | kubectl apply | 🏆 Ingress |

**SPOF** = Single Point of Failure (kui Nginx crashib, kõik teenused on maas)
**HA** = High Availability (kui Ingress pod crashib, K8s käivitab uue)

---

## 🏗️ Arhitektuuri Võrdlus

### Nginx (Traditsiooniline)

```
Internet (port 80/443)
    ↓
VPS Server (93.127.213.242)
    ↓
Nginx Process (port 80) ← SPOF!
    ↓
    ├─→ Docker Container: frontend (port 8080)
    ├─→ Docker Container: user-service (port 3000)
    └─→ Docker Container: todo-service (port 8081)
```

**Eelised:**
- ✅ Lihtne
- ✅ Vähe komponente
- ✅ Kiire setup

**Puudused:**
- ❌ Kui Nginx crashib → kõik teenused kättesaamatud
- ❌ Skaleerumine = suurem VPS (vertikaalne)
- ❌ Käsitsi konfiguratsioon

### Kubernetes Ingress (Kaasaegne)

```
Internet (port 80/443)
    ↓
LoadBalancer / NodePort
    ↓
Ingress Controller Pod #1 ← Replicated (3+ pods)
Ingress Controller Pod #2
Ingress Controller Pod #3
    ↓
Kubernetes Service (Service Discovery)
    ↓
    ├─→ frontend-pod-1, frontend-pod-2
    ├─→ user-service-pod-1, user-service-pod-2
    └─→ todo-service-pod-1, todo-service-pod-2
```

**Eelised:**
- ✅ High Availability (mitu Ingress Controller pod'i)
- ✅ Automaatne failover (K8s restartib crashinud pod'id)
- ✅ Horisontaalne skaleerumine (lisa pod'e, mitte riistvara)
- ✅ Automaatne service discovery

**Puudused:**
- ❌ Keerukam setup
- ❌ Nõuab Kubernetes klastrit
- ❌ Rohkem komponente = rohkem õppida

---

## ⚙️ Konfiguratsiooni Võrdlus

### Näide: Lisa uus teenus (Payment Service)

#### Nginx

**1. Muuda konfiguratsioonifaili:**
```nginx
# /etc/nginx/sites-available/kirjakast.cloud

# Lisa upstream
upstream payment-service {
    server localhost:4000;
}

# Lisa location
location /api/payments {
    proxy_pass http://payment-service;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

**2. Testi ja rakenda:**
```bash
ssh janek@kirjakast
vim /etc/nginx/sites-available/kirjakast.cloud
sudo nginx -t
sudo systemctl reload nginx
```

**Ajakulu:** 5-10 minutit

#### Kubernetes Ingress

**1. Muuda Ingress manifest'i:**
```yaml
# app-ingress.yaml

- path: /api/payments
  pathType: Prefix
  backend:
    service:
      name: payment-service
      port:
        number: 4000
```

**2. Rakenda:**
```bash
vim app-ingress.yaml
kubectl apply -f app-ingress.yaml
# Automaatselt rakenduv (0 downtime)
```

**Ajakulu:** 2-3 minutit

**Võitja:** 🏆 Kubernetes Ingress (kiirem, automatiseerivaum)

---

## 🔄 Skaleerimise Võrdlus

### Stsenaarium: Liiklus kasvas 10x

#### Nginx (Vertikaalne Skaleerimine)

**Probleem:**
```
Praegune VPS: 2 CPU, 8 GB RAM → $10/kuu
Liiklus kasvas → Nginx CPU 90%, vastamised aeglased
```

**Lahendus:**
```
1. Upgrade VPS plan → 8 CPU, 32 GB RAM → $80/kuu
2. Restart teenused uues VPS-is
3. Downtime: 15-30 minutit
```

**Hind:** $80/kuu
**Downtime:** Jah

#### Kubernetes Ingress (Horisontaalne Skaleerimine)

**Probleem:**
```
Praegune: 2 Ingress Controller pod'i
Liiklus kasvas → CPU kasutus kõrge
```

**Lahendus:**
```bash
kubectl scale deployment ingress-nginx-controller \
  --replicas=6 -n ingress-nginx

# K8s automaatselt:
# - Loob 4 uut pod'i
# - Hakkab suunama liiklust nendele
# - 0 downtime
```

**Hind:** Sama (makstad ainult node'ide eest, mitte pod'ide eest)
**Downtime:** Ei

**Võitja:** 🏆 Kubernetes Ingress (parem skaleerumine, 0 downtime)

---

## 🛡️ Tõrkekindluse Võrdlus

### Stsenaarium: Nginx/Ingress crashib

#### Nginx

**Probleem:**
```
Nginx process crash (OOM, bug, vms)
```

**Tagajärg:**
```
✗ Kogu veebileht kättesaamatu
✗ Kõik API'd kättesaamatud
✗ 100% downtime
```

**Lahendus:**
```bash
# Manuaalne restart
ssh janek@kirjakast
sudo systemctl restart nginx
```

**Downtime:** 2-10 minutit (kuni admin märkab ja restartib)

#### Kubernetes Ingress

**Probleem:**
```
Ingress Controller pod #1 crashib
```

**Tagajärg:**
```
✓ Traffic suunatud pod #2 ja #3'le
✓ Kasutajad ei märka midagi
✓ K8s restartib pod #1 automaatselt
```

**Lahendus:**
```
# Automaatne - K8s teeb ise
kubectl get pods -n ingress-nginx
# pod/ingress-nginx-controller-xxx  0/1  CrashLoopBackOff → Running
```

**Downtime:** 0 minutit (teised pod'id jätkavad teenindamist)

**Võitja:** 🏆 Kubernetes Ingress (automaatne taastumine)

---

## 📝 Load Balancing Võrdlus

### Stsenaarium: User Service on 3 pod'i/container'it

#### Nginx

**Konfiguratsioon:**
```nginx
upstream user-service {
    server localhost:3000;  # Container 1
    server localhost:3001;  # Container 2
    server localhost:3002;  # Container 3

    # Load balancing meetod
    least_conn;  # või ip_hash, round_robin
}
```

**Muudatus kui lisa 4. container:**
```bash
# Käsitsi:
1. Lisa docker-compose.yml'i uus port mapping
2. Muuda Nginx config'i (lisa "server localhost:3003;")
3. nginx -t && systemctl reload nginx
```

**Automaatika:** ❌ Käsitsi

#### Kubernetes Ingress

**Konfiguratsioon:**
```yaml
# Ingress viitab lihtsalt Service'ile
backend:
  service:
    name: user-service
    port:
      number: 3000
```

**Service konfiguratsioon:**
```yaml
# user-service Service (Service Discovery)
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service  # Leiab KÕIK pod'id selle label'iga
  ports:
  - port: 3000
    targetPort: 3000
```

**Deployment:**
```yaml
spec:
  replicas: 3  # Muuda lihtsalt siia "4"
```

**Muudatus kui lisa 4. pod:**
```bash
kubectl scale deployment user-service --replicas=4
# Automaatselt:
# - Uus pod tekib
# - Service endpoints uuendatakse
# - Ingress hakkab suunama liiklust ka sellele
```

**Automaatika:** ✅ Täielik

**Võitja:** 🏆 Kubernetes Ingress (automaatne service discovery)

---

## 🔐 SSL/TLS Võrdlus

### Stsenaarium: Lisa HTTPS tugi (Let's Encrypt)

#### Nginx

**Paigaldamine:**
```bash
# 1. Paigalda certbot
sudo apt install certbot python3-certbot-nginx

# 2. Hangi sertifikaat
sudo certbot --nginx -d kirjakast.cloud -d www.kirjakast.cloud

# 3. Certbot muudab automaatselt Nginx config'i
# Lisab SSL listen 443, ssl_certificate, redirect HTTP→HTTPS
```

**Uuendamine:**
```bash
# Automaatne cron job (certbot-renewal.service)
sudo certbot renew --dry-run
```

**Konfiguratsioon:**
```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /etc/letsencrypt/live/kirjakast.cloud/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/kirjakast.cloud/privkey.pem;

    # SSL seaded
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
}
```

**Käsitsi haldamine:** Keskmine (certbot automatiseerib, aga VPS-is)

#### Kubernetes Ingress

**Paigaldamine:**
```bash
# 1. Paigalda cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# 2. Loo ClusterIssuer (Let's Encrypt)
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@kirjakast.cloud
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

**Konfiguratsioon:**
```yaml
# Lihtsalt lisa annotation + tls block
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - kirjakast.cloud
    - www.kirjakast.cloud
    secretName: kirjakast-cloud-tls  # cert-manager loob selle automaatselt
  rules:
  - host: kirjakast.cloud
    http:
      paths:
      - path: /
        ...
```

**Uuendamine:**
- ✅ **Täielik automaatika** - cert-manager uuendab enne aegumist
- ✅ Sertifikaadid Kubernetes Secret'ides (keskne haldus)
- ✅ Mitu domeeni ühes manifest'is

**Käsitsi haldamine:** Minimaalne (cert-manager teeb kõik)

**Võitja:** 🏆 Kubernetes Ingress + cert-manager (täielik automaatika)

---

## 💰 Kulude Võrdlus

### Väike Projekt (1-10 kasutajat päevas)

#### Nginx (VPS)

```
VPS (2 CPU, 8 GB RAM):        $10/kuu
DNS:                          $0-2/kuu (tavaliselt tasuta)
SSL (Let's Encrypt):          $0/kuu
--------------------------------------------
KOKKU:                        $10-12/kuu
```

**Admin aeg:** 2-4h kuus (security updates, monitoring)

#### Kubernetes

```
Managed Kubernetes (DigitalOcean):  $40/kuu (kõige odavam)
Worker node (2 CPU, 4 GB):          $20/kuu
DNS:                                $0-2/kuu
SSL (cert-manager):                 $0/kuu
--------------------------------------------
KOKKU:                              $60-62/kuu
```

**Admin aeg:** 1-2h kuus (K8s automatiseerib rohkem)

**Võitja:** 🏆 Nginx ($10 vs $60)

### Keskmine Projekt (1000-10000 kasutajat päevas)

#### Nginx (VPS)

```
VPS (4 CPU, 16 GB RAM):        $40/kuu
Backup VPS (failover):         $40/kuu
Load Balancer (HAProxy):       $20/kuu
DNS:                           $2/kuu
SSL:                           $0/kuu
--------------------------------------------
KOKKU:                         $102/kuu
```

**Admin aeg:** 20-30h kuus (scaling, monitoring, deploys)

#### Kubernetes

```
Managed Kubernetes:           $40/kuu
Worker nodes (3x 4 CPU, 8 GB): $90/kuu ($30×3)
DNS:                          $2/kuu
SSL:                          $0/kuu
--------------------------------------------
KOKKU:                        $132/kuu
```

**Admin aeg:** 5-10h kuus (automaatika)

**Võitja:** 🏆 Nginx ($102 vs $132), aga Ingress on lähemale
**Arvestades admin aega:** 🏆 Kubernetes (vähem käsitööd)

### Suur Projekt (100k+ kasutajat päevas)

#### Nginx (VPS)

```
VPS (16 CPU, 64 GB RAM):         $200/kuu
Backup VPS:                      $200/kuu
Load Balancer:                   $100/kuu
CDN (Cloudflare):                $20/kuu
Monitoring (Datadog):            $50/kuu
--------------------------------------------
KOKKU:                           $570/kuu
```

**Admin aeg:** 80-120h kuus (full-time admin)

#### Kubernetes

```
Managed Kubernetes:              $100/kuu
Worker nodes (10x 8 CPU, 16 GB): $800/kuu ($80×10)
Auto-scaling:                    Included
Load Balancer:                   $20/kuu
CDN:                             $20/kuu
Monitoring (Prometheus):         $0/kuu (self-hosted)
--------------------------------------------
KOKKU:                           $940/kuu
```

**Admin aeg:** 20-40h kuus (automaatika + DevOps team)

**Võitja:** 🏆 Kubernetes opereerimiskulu (vähem inimtööd)
**Märkus:** K8s kallim riistvara, aga odavam opereerimine

---

## 🚀 Deployment'i Kiiruse Võrdlus

### Stsenaarium: Uuenda User Service v1.0 → v1.1

#### Nginx

**Protsess:**
```bash
# 1. SSH VPS'i
ssh janek@kirjakast

# 2. Pull uus kood
cd /home/janek/apps/user-service
git pull origin main

# 3. Rebuild Docker image
docker build -t user-service:1.1 .

# 4. Stop vana, käivita uus
docker compose stop user-service
docker compose up -d user-service

# 5. Kontrolli logisid
docker compose logs -f user-service
```

**Ajakulu:** 5-10 min
**Downtime:** 10-30 sekundit (stop → start)
**Rollback:** Manuaalne (docker compose up -d user-service:1.0)

#### Kubernetes

**Protsess:**
```bash
# 1. Muuda Deployment image
kubectl set image deployment/user-service \
  user-service=user-service:1.1 -n todo-app

# VÕI muuda YAML ja apply
# kubectl apply -f user-service-deployment.yaml
```

**Mis juhtub automaatselt:**
1. K8s loob uue pod'i (v1.1)
2. Ootab kuni uus pod on `Ready` (readiness probe)
3. Suunab liikluse uuele pod'ile
4. Kustutab vana pod'i (v1.0)

**Ajakulu:** 2-3 min (käsk 5 sekundit, K8s teeb ülejäänud)
**Downtime:** 0 sekundit (rolling update)
**Rollback:** 1 käsk (`kubectl rollout undo deployment/user-service`)

**Võitja:** 🏆 Kubernetes (0 downtime, automaatne rollback)

---

## 🎯 Millal Kasutada Kumbagi?

### Kasuta Nginx (VPS) kui:

✅ **Väike projekt:**
- < 10,000 kasutajat päevas
- 1-5 mikroteenust
- Piiratud eelarve ($10-50/kuu)

✅ **Lihtne arhitektuur:**
- Monolith või paar teenust
- Ei vaja sagedasi deploy'e
- Üks arendaja/väike tiim

✅ **Kiire prototyping:**
- MVP (Minimum Viable Product)
- Proof of Concept
- Personal projekt

✅ **Õppimine:**
- Esimest korda reverse proxy'ga töötamine
- Ei tea veel Kubernetes'e
- Tahad mõista põhitõdesid

**Näited:**
- Isiklik blog + kommentaarium
- Väike e-kauplus (< 100 tellimust päevas)
- Ettevõtte siseveebirakendus

### Kasuta Kubernetes Ingress kui:

✅ **Skaleeritav projekt:**
- > 10,000 kasutajat päevas
- 5+ mikroteenust
- Liiklus võib kasvada 10x-100x

✅ **Keeruline arhitektuur:**
- Mikroteenused
- Service mesh (Istio, Linkerd)
- Multi-region deployment

✅ **Sagedased deploy'id:**
- CI/CD pipeline
- 10+ deployment'i päevas
- Blue-Green / Canary deployments

✅ **High Availability nõue:**
- 99.9% uptime SLA
- Auto-scaling vajalik
- Failover peab olema automaatne

✅ **Suur tiim:**
- DevOps meeskond
- Eraldi arendus/staging/prod keskkonnad
- Gitops workflow

**Näited:**
- E-commerce platvorm (> 1000 tellimust päevas)
- SaaS rakendus (multi-tenant)
- Fintech / Healthcare (HA nõuded)
- Meedia streaming platvorm

---

## 🔀 Hübriidlahendus: Parim Mõlemast Maailmast

### Variant 1: Nginx → Kubernetes (Järkjärguline Migratsioon)

**Samm 1: Algus (kuu 1-3)**
```
Nginx VPS → Docker Compose
(Õpi põhitõed, testi turgu)
```

**Samm 2: Kasv (kuu 4-6)**
```
Nginx VPS → Mõned teenused K8s'is
(Tootmis-kriitiline veel VPS'is, uus funktsioon K8s'is)
```

**Samm 3: Täielik migratsioon (kuu 7-12)**
```
Kõik teenused K8s'is + Ingress
```

**Eelised:**
- ✅ Väiksem risk (järkjärguline)
- ✅ Õpi K8s'e väikese projekti peal
- ✅ Alusta odavalt, skaleeri kui vaja

### Variant 2: Nginx Ees + K8s Taga

```
Internet
    ↓
Nginx (VPS - edge proxy, SSL termination, DDoS kaitse)
    ↓
Kubernetes Ingress (internal routing)
    ↓
Mikroteenused
```

**Eelised:**
- ✅ Nginx tegeleb SSL ja turvalisusega (võib kasutada WAF)
- ✅ K8s haldab rakenduste routing'ut
- ✅ Parim mõlemast: lihtsus ääres, võimsus sees

**Puudused:**
- ❌ Rohkem komponente
- ❌ Keerulisem debugging

---

## 📚 Õppimise Soovitused

### Kui Alustad

1. **Alusta Nginx'ist** (Labor 4, Harjutus 01)
   - Mõistad reverse proxy põhitõdesid
   - Kiire tulemuste nägemine
   - Vähem abstraktsioone

2. **Liikumine Ingress'ile** (Labor 4, Harjutus 02)
   - Nüüd mõistad MIKS Ingress eksisteerib
   - Näed evolutsiooni (Nginx → Ingress)
   - Oskad võrrelda kahte lähenemist

### Kui Juba Oskad Nginx'i

- ✅ **Alusta otse Ingress'ist** (Path B)
- ✅ Sa juba tead upstream, proxy_pass, virtual hosts
- ✅ Ingress on lihtsalt deklaratiivne versioon samast asjast

---

## 🎓 Kokkuvõte

### Nginx VPS

**Parim:** Lihtsad projektid, väike eelarve, kiire setup
**Väldi:** Suur liiklus, high availability nõue, suur tiim

**Metafoor:** Nginx = Isiklik auto
- Odav, lihtne, kontrollib ise kõike
- Piiratud skaleerumine (ei saa paneda 10 inimest autosse)

### Kubernetes Ingress

**Parim:** Suured projektid, skaleerumine, DevOps tiim
**Väldi:** Väike projekt, piiratud eelarve, üks arendaja

**Metafoor:** K8s Ingress = Uber/Bolt
- Automaatne, skaleeritav, alati saadaval
- Kallim ühe inimese jaoks, odavam suurele grupile

---

## 💡 Praktiline Soovitus

**Kui sa pole kindel, alusta Nginx'ist:**

```
Väike projekt → Nginx VPS
    ↓
Kasv 10x → Liikumine K8s'ile
    ↓
Suur projekt → K8s Ingress + Autoscaling
```

**Miks?**
- ✅ Õpid põhitõed (reverse proxy, SSL, routing)
- ✅ Väiksem eelkulu ($10 vs $60)
- ✅ Alati saad liikuda K8s'ile kui vaja

**ÄRGI:**
- ❌ Ära alusta K8s'iga kui sul on personal blog
- ❌ Ära jää Nginx'i juurde kui liiklus on 100k+ päevas

---

**Õnnitleme!** 🎉

Sa mõistad nüüd mõlema lähenemise tugevusi ja nõrkusi. Vali see mis sobib SINU projekti jaoks, mitte see mis on "trendy" või "kõige uuem".

**Õige tööriist õigel ajal > parim tööriist valel ajal**

---

**Viimane uuendus:** 2025-11-16
**Autor:** DevOps Training Labs
