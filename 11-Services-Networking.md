# Peatükk 11: Services ja Networking

**Kestus:** 4 tundi
**Eeldused:** Peatükk 9-10 (Kubernetes alused, Pods, Deployments)
**Eesmärk:** Mõista Kubernetes võrgu abstraktsioone ja Service discovery't

---

## Õpieesmärgid

Selle peatüki lõpuks oskad:
- Mõista Service abstraktsiooni kui stable network endpoint
- Kasutada ClusterIP, NodePort, ja LoadBalancer Service tüüpe
- Seadistada Service discovery DNS'iga
- Mõista Endpoints ja load balancing'u
- Konfigureerida Network Policies (basic)

---

## 11.1 Miks Services? - Pod IP Probleem

### Pod Ephemeral IP Addresses

**Probleem:**

```
Deployment: backend (3 replicas)

Pods:
- backend-abc123 → IP: 10.244.1.5
- backend-def456 → IP: 10.244.1.6
- backend-ghi789 → IP: 10.244.1.7

Frontend proovib ühendust:
→ curl http://10.244.1.5:3000/api/users
→ OK!

Pod crashib:
- backend-abc123 deleted
- NEW Pod backend-jkl012 → IP: 10.244.1.9 (DIFFERENT!)

Frontend:
→ curl http://10.244.1.5:3000
→ ERROR: No route to host (IP ei eksisteeri enam!)
```

**Põhimõtteline probleem:**
- Pod IP on EPHEMERAL (ajutine)
- Pod recreation → NEW IP
- Hardcoded IP addresses → broken connections

---

### Service - Stable Network Abstraction

**Lahendus: Service**

```
Service: backend-service
→ Stable IP: 10.96.0.10 (ClusterIP)
→ Stable DNS: backend-service.default.svc.cluster.local

Frontend:
→ curl http://backend-service:3000/api/users
→ Service routes to healthy Pods (ANY of 3 backends)

Pod crashib:
→ New Pod created with NEW IP
→ Service automatically updates endpoints
→ Frontend still works (Service IP unchanged!)
```

**Service role:**
1. **Stable endpoint:** Single IP/DNS that doesn't change
2. **Load balancing:** Distribute traffic across multiple Pods
3. **Service discovery:** DNS name for Pods
4. **Health-aware:** Only route to READY Pods

**DevOps perspektive:**
> "Service on load balancer + DNS name Pods'idele. Ma ei pea kunagi Pod IP'sid teadma."

---

## 11.2 Service Types

### ClusterIP - Internal Load Balancer

**Default Service type** - accessible ONLY within cluster

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP  # Default (võid ära jätta)
  selector:
    app: backend   # Target Pods with label app=backend
  ports:
  - port: 80       # Service port (external)
    targetPort: 3000  # Container port (internal)
    protocol: TCP
```

**Architecture:**

```
Service: backend-service
  ClusterIP: 10.96.0.10
  Port: 80

Selector: app=backend
  ↓
Endpoints (auto-discovered):
  - 10.244.1.5:3000 (Pod 1)
  - 10.244.1.6:3000 (Pod 2)
  - 10.244.1.7:3000 (Pod 3)

Traffic flow:
Client → curl http://backend-service:80
  ↓
Service (10.96.0.10:80) → Load balance
  ↓
Random Pod: 10.244.1.6:3000
```

**Port mapping:**
- `port: 80` - Service listens on port 80
- `targetPort: 3000` - Forward to Pod port 3000
- Client connects to: `backend-service:80`
- Request forwarded to: `Pod:3000`

**Use case:**
- Internal microservices communication
- Backend → Database
- Frontend → Backend
- NOT accessible from outside cluster

---

### NodePort - External Access via Node IP

**Expose Service on EVERY Node's IP:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080  # Port on every Node (30000-32767)
    protocol: TCP
```

**Architecture:**

```
External request:
  curl http://NODE_IP:30080

Node (any of 3 Nodes):
  → NodePort 30080 open on ALL Nodes

Service: frontend-service
  → ClusterIP: 10.96.0.20
  → NodePort: 30080

Endpoints:
  - 10.244.1.10:80 (frontend Pod 1, Node A)
  - 10.244.1.11:80 (frontend Pod 2, Node B)
  - 10.244.1.12:80 (frontend Pod 3, Node C)

Traffic flow:
Client → http://NODE_B_IP:30080
  ↓
Service (any Node forwards to ClusterIP)
  ↓
Load balance to ANY Pod (even on different Node!)
  ↓
Pod on Node A:80
```

**Key points:**
- NodePort opens port on EVERY Node (even if no Pods on that Node)
- Request to ANY Node IP:30080 works
- Load balances across ALL Pods cluster-wide

**nodePort range:** 30000-32767 (configurable in API server)

**Use case:**
- Development/testing external access
- Small-scale production (no load balancer)
- NOT recommended for production (use LoadBalancer or Ingress)

---

### LoadBalancer - Cloud Provider Integration

**Provision external load balancer (AWS ELB, GCP LB, Azure LB):**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
```

**Architecture (AWS example):**

```
External request:
  curl http://abc123.us-east-1.elb.amazonaws.com

AWS ELB (auto-provisioned):
  → External IP: 54.123.45.67
  → Backends: Node IPs

Kubernetes Service:
  → ClusterIP: 10.96.0.30
  → LoadBalancer external IP: 54.123.45.67

Endpoints:
  - Pod 1, Pod 2, Pod 3

Traffic flow:
Client → ELB (54.123.45.67:80)
  ↓
Load balances to Nodes
  ↓
Node forwards to Service ClusterIP
  ↓
Load balances to Pods
```

**What happens:**
1. kubectl apply -f service.yaml (type: LoadBalancer)
2. Kubernetes cloud-controller-manager:
   - Calls AWS API: CreateLoadBalancer
   - Configures backend: Node IPs
   - Assigns external IP
3. Service gets `.status.loadBalancer.ingress.ip`
4. External traffic → ELB → Nodes → Pods

**Cost warning:**
- Each LoadBalancer Service = separate cloud load balancer
- AWS ELB: ~$20/month per load balancer
- 10 Services = 10 ELBs = $200/month

**Better alternative:** Ingress (single load balancer for multiple Services)

**Use case:**
- Production cloud environments (AWS, GCP, Azure)
- When you need external IP per Service
- Simple setup (no Ingress controller needed)

---

### ExternalName - DNS CNAME

**Map Service name to external DNS:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-external
spec:
  type: ExternalName
  externalName: postgres.company.com  # External hostname
```

**Use case:**

```
Scenario: PostgreSQL runs OUTSIDE Kubernetes (legacy VPS)

Without ExternalName:
  Pods: DB_HOST=postgres.company.com (hardcoded)

With ExternalName:
  Pods: DB_HOST=postgres-external (Kubernetes Service)
  → Service resolves to postgres.company.com

Benefit:
  Migration path: Later move PostgreSQL INTO Kubernetes
  → Change Service type to ClusterIP
  → Pods don't need config changes!
```

---

## 11.3 Service Discovery - DNS

### Kubernetes DNS (CoreDNS)

**Automatic DNS records:**

```yaml
Service: backend-service
Namespace: default

DNS names created:
1. backend-service (same namespace)
2. backend-service.default (with namespace)
3. backend-service.default.svc.cluster.local (FQDN)
```

**DNS resolution:**

```
Pod in same namespace (default):
→ curl http://backend-service:80
→ DNS query: backend-service
→ CoreDNS: 10.96.0.10 (Service ClusterIP)

Pod in different namespace (production):
→ curl http://backend-service.default:80
→ DNS query: backend-service.default
→ CoreDNS: 10.96.0.10

Full FQDN:
→ curl http://backend-service.default.svc.cluster.local:80
```

**Best practice:**

```yaml
# Same namespace - short name
env:
  - name: DB_HOST
    value: postgres-service  # Lühike, loetav

# Cross-namespace - full name
env:
  - name: DB_HOST
    value: postgres-service.production  # Namespace included
```

---

### Service Discovery Example

**Setup:**

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: backend-nodejs:1.0
        env:
        - name: DB_HOST
          value: postgres-service  # DNS name!
        - name: DB_PORT
          value: "5432"
        ports:
        - containerPort: 3000

---
# backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 3000

---
# postgres-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```

**Communication flow:**

```
Frontend Pod:
→ HTTP request to http://backend-service/api/users

DNS resolution:
→ backend-service → 10.96.0.10

Service load balances:
→ Backend Pod 2 (10.244.1.6:3000)

Backend connects to database:
→ pool.connect('postgres-service:5432')

DNS resolution:
→ postgres-service → 10.96.0.50

Service forwards:
→ PostgreSQL Pod (10.244.2.10:5432)

Result:
→ Frontend → Backend → PostgreSQL (zero hardcoded IPs!)
```

📖 **Praktika:** Labor 3, Harjutus 6 - Service discovery multi-tier app

---

## 11.4 Endpoints - Service Backend

### Endpoints Object

**Automatic creation:**

```yaml
# Service
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend  # Label selector
  ports:
  - port: 80
    targetPort: 3000
```

**Kubernetes auto-creates Endpoints:**

```yaml
# Auto-generated (don't create manually)
apiVersion: v1
kind: Endpoints
metadata:
  name: backend-service  # Same name as Service
subsets:
- addresses:
  - ip: 10.244.1.5    # Pod 1 (READY)
  - ip: 10.244.1.6    # Pod 2 (READY)
  - ip: 10.244.1.7    # Pod 3 (READY)
  ports:
  - port: 3000
```

**View Endpoints:**

```bash
kubectl get endpoints backend-service

# Output:
NAME              ENDPOINTS                                 AGE
backend-service   10.244.1.5:3000,10.244.1.6:3000,...       5m
```

---

### Endpoints Updates (Dynamic)

**Scenario: Pod becomes unready**

```
1. Initial state:
   Endpoints:
   - 10.244.1.5:3000 (READY)
   - 10.244.1.6:3000 (READY)
   - 10.244.1.7:3000 (READY)

2. Pod 10.244.1.6 fails readiness probe:
   Endpoints controller removes from list:
   - 10.244.1.5:3000
   - 10.244.1.7:3000

3. Traffic only to READY Pods:
   Service → 10.244.1.5 or 10.244.1.7 (NOT 10.244.1.6!)

4. Pod 10.244.1.6 becomes READY again:
   Endpoints controller adds back:
   - 10.244.1.5:3000
   - 10.244.1.6:3000
   - 10.244.1.7:3000
```

**DevOps benefit:**
> "Endpoints automatically track Pod health. Failed Pods removed from load balancing. No manual intervention."

---

### Headless Service - No Load Balancing

**Scenario:** StatefulSet (PostgreSQL cluster) - need direct Pod access

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
spec:
  clusterIP: None  # Headless Service
  selector:
    app: postgres
  ports:
  - port: 5432
```

**Behavior:**

```
Normal Service:
→ DNS: postgres-service → Single ClusterIP (10.96.0.50)
→ Load balances to ANY Pod

Headless Service:
→ DNS: postgres-headless → ALL Pod IPs
→ Client chooses which Pod to connect

DNS A records:
postgres-headless.default.svc.cluster.local
  → 10.244.1.10 (postgres-0)
  → 10.244.1.11 (postgres-1)
  → 10.244.1.12 (postgres-2)

Individual Pod DNS:
postgres-0.postgres-headless.default.svc.cluster.local → 10.244.1.10
postgres-1.postgres-headless.default.svc.cluster.local → 10.244.1.11
postgres-2.postgres-headless.default.svc.cluster.local → 10.244.1.12
```

**Use case:**
- StatefulSets (direct Pod access)
- PostgreSQL clustering (primary vs replicas)
- Distributed systems (Kafka, Cassandra)

📖 **Praktika:** Labor 3, Harjutus 7 - Headless Services for StatefulSets

---

## 11.5 Load Balancing

### kube-proxy - Service Implementation

**How Services actually work:**

```
Service is NOT a process!
→ It's an abstraction (IP + load balancing rules)

kube-proxy (runs on every Node):
→ Watches Services and Endpoints
→ Programs iptables/IPVS rules
→ Implements load balancing
```

**iptables mode (default):**

```
Client Pod → curl http://backend-service:80

1. DNS: backend-service → 10.96.0.10 (ClusterIP)

2. Packet: dst=10.96.0.10:80

3. iptables rules (on Node):
   → If dst=10.96.0.10:80
   → DNAT to random Pod:
      - 33% chance → 10.244.1.5:3000
      - 33% chance → 10.244.1.6:3000
      - 33% chance → 10.244.1.7:3000

4. Packet rewritten: dst=10.244.1.6:3000

5. Routed to Pod
```

**Load balancing algorithm:**
- **iptables mode:** Random selection (stateless)
- **IPVS mode:** Round-robin, least connection, etc. (more algorithms)

---

### Session Affinity (Sticky Sessions)

**Problem:**

```
Session-based app (shopping cart in memory)

Request 1 → Pod A (cart: item1)
Request 2 → Pod B (cart: EMPTY!) - different Pod!
```

**Solution: sessionAffinity**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  sessionAffinity: ClientIP  # Sticky sessions
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 hours
```

**Behavior:**

```
Client IP: 192.168.1.100

Request 1:
→ Hash(192.168.1.100) → Pod A
→ Store cart in Pod A memory

Request 2 (same client IP):
→ Hash(192.168.1.100) → Pod A (SAME!)
→ Cart persists!

Timeout: 3 hours
→ After 3h, client may be routed to different Pod
```

**Limitation:**
- Based on source IP only (not cookies/headers)
- Not reliable for external clients (NAT, load balancers change IP)

**Better solution:** External session storage (Redis, Memcached)

---

## 11.6 Network Policies - Firewall Rules

### Default Behavior - All Traffic Allowed

**Without Network Policies:**

```
Any Pod can talk to any Pod:
- Frontend → Backend ✅
- Frontend → Database ✅ (SECURITY RISK!)
- Backend → Database ✅
```

**Security problem:**
- Compromised frontend Pod → direct database access
- No network segmentation

---

### Network Policy - Basic Firewall

**Deny frontend → database:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: postgres  # Apply to PostgreSQL Pods

  policyTypes:
  - Ingress  # Control incoming traffic

  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend  # Allow ONLY from backend Pods
    ports:
    - protocol: TCP
      port: 5432
```

**Effect:**

```
Before Network Policy:
- Frontend → PostgreSQL:5432 ✅
- Backend → PostgreSQL:5432 ✅

After Network Policy:
- Frontend → PostgreSQL:5432 ❌ BLOCKED
- Backend → PostgreSQL:5432 ✅ ALLOWED
```

---

### Namespace Isolation

**Allow cross-namespace traffic:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-allow-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend

  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend-namespace
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 3000
```

**Use case:**
- Multi-tenant clusters (namespace per team/env)
- Security isolation (production vs staging)

---

### Default Deny All Policy

**Production best practice:**

```yaml
# Deny all ingress by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all-ingress
  namespace: production
spec:
  podSelector: {}  # Apply to ALL Pods in namespace
  policyTypes:
  - Ingress
  # No ingress rules → DENY ALL

---
# Then allow specific traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 3000
```

**Security posture:**
- Default: DENY all
- Explicit: ALLOW specific traffic
- Principle of least privilege

📖 **Praktika:** Labor 4, Harjutus 3 - Network Policies

---

## 11.7 Service Best Practices

### 1. Use ClusterIP by Default

```yaml
# Internal communication
spec:
  type: ClusterIP  # Default, secure
```

**Väldi:**
- NodePort for production (use Ingress instead)
- LoadBalancer for every Service (expensive, use Ingress)

---

### 2. Named Ports

```yaml
# Deployment
spec:
  containers:
  - name: backend
    ports:
    - name: http  # Named port
      containerPort: 3000

# Service
spec:
  ports:
  - port: 80
    targetPort: http  # Reference by name (not number)
```

**Benefit:** Change port number in one place (Deployment) → Service still works

---

### 3. Health Checks Required

```yaml
# Service ONLY routes to READY Pods
readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  periodSeconds: 5
```

**Without readiness probe:**
- All Pods in Endpoints (even unhealthy!)
- Traffic to broken Pods → errors

---

### 4. Consistent Labeling

```yaml
# Deployment
metadata:
  labels:
    app: backend
    tier: api
    version: v1.2.3

# Service selector
selector:
  app: backend  # Match Deployment labels
```

**Avoid:**
- Typos in labels (selector doesn't match)
- Overly specific selectors (version: v1.2.3) → breaks on updates

---

### 5. DNS Names in Config

```yaml
# ✅ GOOD
env:
  - name: DB_HOST
    value: postgres-service

# ❌ BAD
env:
  - name: DB_HOST
    value: 10.96.0.50  # Hardcoded ClusterIP
```

---

## Kokkuvõte

### Mida sa õppisid?

**Service abstraction:**
- Stable endpoint for ephemeral Pods
- Load balancing across Pods
- Automatic service discovery (DNS)

**Service types:**
- **ClusterIP:** Internal load balancer (default, production)
- **NodePort:** External access via Node IPs (dev/test)
- **LoadBalancer:** Cloud load balancer (expensive, use Ingress)
- **ExternalName:** DNS CNAME for external services

**Service discovery:**
- Automatic DNS records (CoreDNS)
- Short names (same namespace): `backend-service`
- Full names (cross-namespace): `backend-service.production`

**Endpoints:**
- Auto-generated backend list (Pod IPs)
- Dynamic updates (failed Pods removed)
- Health-aware (readiness probes)

**Load balancing:**
- kube-proxy (iptables/IPVS)
- Session affinity (sticky sessions by client IP)

**Network Policies:**
- Firewall rules for Pods
- Default deny + explicit allow (security best practice)
- Namespace and label-based isolation

---

### DevOps Administraatori Vaatenurk

**Iga päev:**
```bash
kubectl get services              # List Services
kubectl get endpoints             # Check backend Pods
kubectl describe service backend  # Service details
```

**Service creation:**
```bash
kubectl expose deployment backend --port=80 --target-port=3000
# Creates ClusterIP Service automatically
```

**Troubleshooting:**
```bash
# Service not working:
kubectl get endpoints backend-service  # Are there backends?
kubectl describe service backend-service  # Check selector

# DNS not resolving:
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup backend-service

# Network Policy blocking:
kubectl describe networkpolicy <name>  # Check rules
```

---

### Järgmised Sammud

**Peatükk 12:** ConfigMaps ja Secrets (configuration management)
**Peatükk 13:** Persistent Storage (volumes, StatefulSets)

---

**Kestus kokku:** ~4 tundi teooriat + praktilised harjutused labides

📖 **Praktika:** Labor 3, Harjutused 6-7 - Services, service discovery, Network Policies
