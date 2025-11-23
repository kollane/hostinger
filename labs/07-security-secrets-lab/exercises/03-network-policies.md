# Harjutus 3: Network Policies (Zero-Trust Networking)

**Kestus:** 60 minutit
**Eesmärk:** Implementeeri pod-to-pod communication control zero-trust mudeli alusel.

---

## 📋 Ülevaade

Selles harjutuses konfigureerime **Network Policies** - Kubernetes native network segmentation. Network Policies kontrollivad, millised pod'id saavad omavahel suhelda.

**Miks Network Policies olulised?**
- ❌ Default Kubernetes: kõik pod'id saavad suhelda kõigiga = lateral movement risk
- ❌ Kui üks pod kompromiteeritud → kogu cluster ohus
- ✅ Network Policies: explicit allow, implicit deny
- ✅ Zero-trust networking (never trust, always verify)
- ✅ Compliance: PCI-DSS, HIPAA nõuavad network segmentation
- ✅ Attack surface minimization

**Zero-Trust mudel:** Default deny all, explicit allow only necessary communication.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

✅ Mõista Network Policy types (Ingress, Egress)
✅ Luua default deny-all policy
✅ Luua allow-specific policies
✅ Kasutada label selectors
✅ Testida network connectivity
✅ Debuggida network policy issues
✅ Implementeerida defense-in-depth

---

## 🏗️ Network Policy Arhitektuur

```
┌─────────────────────────────────────────────────────────────┐
│         Kubernetes Cluster (Network Policies Enabled)       │
│                                                             │
│  ┌────────────────┐                                        │
│  │   Frontend     │                                        │
│  │   Pod          │                                        │
│  │   (port 8080)  │                                        │
│  └───────┬────────┘                                        │
│          │ ✅ ALLOW (policy: allow-frontend-backend)       │
│          ▼                                                 │
│  ┌────────────────┐                                        │
│  │  User-Service  │                                        │
│  │  Pod           │                                        │
│  │  (port 3000)   │                                        │
│  └───────┬────────┘                                        │
│          │ ✅ ALLOW (policy: allow-backend-db)            │
│          ▼                                                 │
│  ┌────────────────┐                                        │
│  │  PostgreSQL    │                                        │
│  │  Pod           │                                        │
│  │  (port 5432)   │                                        │
│  └────────────────┘                                        │
│          ▲                                                 │
│          │ ❌ DENY (default deny-all)                     │
│  ┌───────┴────────┐                                        │
│  │  Attacker Pod  │ (blocked from accessing DB directly)  │
│  └────────────────┘                                        │
│                                                             │
│  ┌────────────────┐                                        │
│  │  Prometheus    │                                        │
│  │  (monitoring   │                                        │
│  │   namespace)   │                                        │
│  └───────┬────────┘                                        │
│          │ ✅ ALLOW (policy: allow-monitoring-scrape)     │
│          └──────▶ All pods /metrics endpoints             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Kontrolli CNI Support

Network Policies vajab CNI plugin'i support (Calico, Cilium, Weave Net).

```bash
# Check CNI plugin
kubectl get nodes -o wide

# Check if NetworkPolicy CRD exists
kubectl api-resources | grep networkpolicies

# List existing Network Policies
kubectl get networkpolicies -A
```

**Kui CNI ei toeta Network Policies:**
- Minikube: `minikube start --cni=calico`
- Kind: Lisa Calico manifest
- Cloud providers: Tavaliselt toetavad (GKE, EKS, AKS)

---

### Samm 2: Default Deny-All Policy

Alustame baseline policy'ga: deny kõik traffic.

**Loo fail `default-deny-all.yaml`:**

```yaml
# Default Deny All Ingress Traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}  # Matches all pods in namespace
  policyTypes:
    - Ingress
---
# Default Deny All Egress Traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: production
spec:
  podSelector: {}  # Matches all pods in namespace
  policyTypes:
    - Egress
```

**Apply:**

```bash
kubectl apply -f default-deny-all.yaml

# Verify
kubectl get networkpolicy -n production
```

**⚠️ WARNING:** Peale selle apply'mist EI SAA ühtegi pod'i omavahel suhelda (including DNS)!

---

### Samm 3: Allow DNS (CoreDNS)

Kõik pod'id vajavad DNS access.

**Loo fail `allow-dns.yaml`:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}  # All pods
  policyTypes:
    - Egress
  egress:
    # Allow DNS (CoreDNS)
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

**Apply:**

```bash
kubectl apply -f allow-dns.yaml
```

---

### Samm 4: Allow Frontend → User-Service

Frontend peab saama suhelda user-service'ga.

**Loo fail `allow-frontend-backend.yaml`:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: user-service  # Target: user-service pods
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend  # Source: frontend pods
      ports:
        - protocol: TCP
          port: 3000  # user-service port
```

**Apply:**

```bash
kubectl apply -f allow-frontend-backend.yaml
```

**Test connectivity:**

```bash
# From frontend pod to user-service
kubectl run test-frontend --image=curlimages/curl --rm -it -n production -- \
  curl -m 5 http://user-service:3000/health

# Should succeed: {"status":"ok"}
```

---

### Samm 5: Allow User-Service → PostgreSQL

User-service vajab database access.

**Loo fail `allow-backend-db.yaml`:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-db
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: postgres  # Target: PostgreSQL pods
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: user-service  # Source: user-service only
      ports:
        - protocol: TCP
          port: 5432  # PostgreSQL port
```

**Apply:**

```bash
kubectl apply -f allow-backend-db.yaml
```

**Test connectivity:**

```bash
# From user-service pod to postgres
kubectl exec -n production deployment/user-service -- \
  nc -zv postgres 5432

# Should succeed: Connection to postgres 5432 port [tcp/postgresql] succeeded!
```

---

### Samm 6: Allow Prometheus Scraping

Prometheus vajab access kõigile /metrics endpoint'idele.

**Loo fail `allow-monitoring.yaml`:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prometheus-scraping
  namespace: production
spec:
  podSelector: {}  # All pods in production namespace
  policyTypes:
    - Ingress
  ingress:
    # Allow Prometheus from monitoring namespace
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: prometheus
      ports:
        - protocol: TCP
          port: 3000  # user-service metrics port
```

**Apply:**

```bash
kubectl apply -f allow-monitoring.yaml

# Verify Prometheus can scrape metrics
# Prometheus UI → Targets → should see production/user-service UP
```

---

### Samm 7: Allow Egress to External Services

Rakendused võivad vajada internet access (API calls, webhooks).

**Loo fail `allow-external-egress.yaml`:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: user-service
  policyTypes:
    - Egress
  egress:
    # Allow DNS
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53

    # Allow HTTPS to internet
    - to:
        - namespaceSelector: {}  # Any namespace
      ports:
        - protocol: TCP
          port: 443

    # Allow HTTP (if needed - less secure!)
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 80

    # Allow PostgreSQL
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432
```

**Apply:**

```bash
kubectl apply -f allow-external-egress.yaml
```

---

### Samm 8: Test Network Isolation

Kontrolli, kas isolatsioon töötab.

**Test 1: Unauthorized pod cannot access DB**

```bash
# Create attacker pod
kubectl run attacker --image=postgres:16 --rm -it -n production -- bash

# Inside attacker pod:
psql -h postgres -U postgres -d userdb
# Should FAIL: connection timeout (blocked by NetworkPolicy)
```

**Test 2: Frontend can access user-service**

```bash
kubectl run test-frontend --image=curlimages/curl --rm -it -n production \
  --labels="app=frontend" -- \
  curl -m 5 http://user-service:3000/health

# Should SUCCEED
```

**Test 3: Random pod cannot access user-service**

```bash
kubectl run random-pod --image=curlimages/curl --rm -it -n production -- \
  curl -m 5 http://user-service:3000/health

# Should FAIL: timeout (no NetworkPolicy allows this)
```

---

### Samm 9: Visualize Network Policies (Optional)

**Use kubectl plugin:**

```bash
# Install kubectl netpol plugin
kubectl krew install np-viewer

# Visualize policies
kubectl np-viewer -n production
```

**Manual visualization:**

```bash
# List all policies
kubectl get networkpolicy -n production

# Describe each policy
kubectl describe networkpolicy -n production

# Generate diagram (manual)
echo "
Frontend (app=frontend)
   │
   │ ✅ allow-frontend-to-backend
   ▼
User-Service (app=user-service)
   │
   │ ✅ allow-backend-to-db
   ▼
PostgreSQL (app=postgres)
"
```

---

### Samm 10: Network Policy Best Practices

**1. Start with default deny:**

```yaml
# ALWAYS create this first
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

**2. Use descriptive names:**
```yaml
# Good
name: allow-frontend-to-backend-http

# Bad
name: np-1
```

**3. Document policies:**

```yaml
metadata:
  name: allow-backend-to-db
  annotations:
    description: "Allow user-service to connect to PostgreSQL on port 5432"
    owner: "platform-team"
    jira-ticket: "SEC-123"
```

**4. Test before applying to production:**

```bash
# Apply to dev first
kubectl apply -f policy.yaml -n development

# Test connectivity
# If OK → apply to staging → test → production
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Default deny-all policies created
- [ ] DNS access allowed (all pods)
- [ ] Frontend → User-Service allowed
- [ ] User-Service → PostgreSQL allowed
- [ ] Prometheus scraping allowed
- [ ] External egress configured
- [ ] Unauthorized access blocked (tested)
- [ ] Network policies documented

### Verifitseerimine

```bash
# 1. List all Network Policies
kubectl get networkpolicy -n production

# 2. Test DNS
kubectl run test-dns --image=busybox --rm -it -n production -- nslookup google.com
# Should work

# 3. Test isolation
kubectl run unauthorized --image=curlimages/curl --rm -it -n production -- \
  curl -m 5 http://user-service:3000
# Should timeout

# 4. Test legitimate traffic
kubectl run frontend-test --image=curlimages/curl --rm -it -n production \
  --labels="app=frontend" -- \
  curl -m 5 http://user-service:3000/health
# Should work
```

---

## 🔍 Troubleshooting

### Probleem: DNS ei tööta

**Lahendus:**

```bash
# Check CoreDNS namespace label
kubectl get namespace kube-system --show-labels

# Ensure allow-dns policy uses correct label
kubectl describe networkpolicy allow-dns -n production

# Test DNS manually
kubectl run test-dns --image=busybox --rm -it -n production -- nslookup kubernetes.default
```

---

### Probleem: Legitimate traffic blocked

**Lahendus:**

```bash
# Check pod labels
kubectl get pods -n production --show-labels

# Ensure NetworkPolicy selector matches
kubectl get networkpolicy allow-frontend-to-backend -o yaml

# Check policy allows correct port
# Source pod → Target pod port must match policy
```

---

### Probleem: Cannot determine if policy works

**Lahendus:**

```bash
# Enable network policy logging (CNI-dependent)
# For Calico:
kubectl annotate networkpolicy <policy-name> \
  projectcalico.org/metadata='{"annotations":{"logging":"true"}}' \
  -n production

# Check logs
kubectl logs -n kube-system -l k8s-app=calico-node
```

---

## 📚 Mida Sa Õppisid?

✅ **Network Policy types**
  - Ingress: incoming traffic control
  - Egress: outgoing traffic control
  - Default deny baseline

✅ **Selectors**
  - podSelector: target pods
  - namespaceSelector: cross-namespace rules
  - Label-based matching

✅ **Zero-trust networking**
  - Explicit allow, implicit deny
  - Minimal necessary permissions
  - Defense in depth

✅ **Security improvements**
  - Lateral movement prevention
  - Attack surface minimization
  - Compliance (network segmentation)

---

## 🚀 Järgmised Sammud

**Exercise 4: Security Scanning** - Vulnerability detection ja management:
- Trivy image scanning
- Kubernetes manifest scanning
- CI/CD integration
- SARIF reports

```bash
cat exercises/04-security-scanning.md
```

---

## 💡 Network Policy Best Practices

✅ **Defense in Depth:**
- Network Policies + RBAC + Pod Security Standards
- Multiple layers of security

✅ **Start Strict:**
- Default deny-all
- Add allow rules incrementally
- Document each exception

✅ **Test Thoroughly:**
- Test in dev/staging first
- Verify legitimate traffic works
- Verify unauthorized traffic blocks

✅ **Monitor:**
- Network policy violations
- Blocked connection attempts
- Policy changes (GitOps audit trail)

✅ **Environment Separation:**
- Separate namespaces per environment
- No cross-environment traffic (unless explicitly needed)
- Monitoring namespace can scrape all

✅ **CNI Choice:**
- Calico: Advanced features (global policies, logging)
- Cilium: eBPF-based (better performance)
- Ensure CNI supports NetworkPolicy before implementation

---

**Õnnitleme! Network Policies configured (Zero-Trust)! 🔒🌐**

**Kestus:** 60 minutit
**Järgmine:** Exercise 4 - Security Scanning
