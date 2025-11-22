# Harjutus 2: Kubernetes RBAC (Role-Based Access Control)

**Kestus:** 60 minutit
**Eesmärk:** Implementeeri fine-grained access control Kubernetes cluster'is.

---

## 📋 Ülevaade

Selles harjutuses konfigureerime **RBAC (Role-Based Access Control)** - Kubernetes standard access control mechanism. RBAC võimaldab määrata, kes saab teha mida Kubernetes cluster'is.

**Miks RBAC oluline?**
- ❌ Default: kõik kasutavad cluster-admin (full access) = ohtlik!
- ❌ Rakendused kasutavad default ServiceAccount = liiga palju õigusi
- ✅ RBAC: iga kasutaja/rakendus saab ainult vajalikud õigused
- ✅ Audit trail: kes tegi mida
- ✅ Compliance: SOC 2, ISO 27001 nõuavad access control

**Principle of Least Privilege:** Anna minimaalne vajalik ligipääs, mitte rohkem.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

✅ Mõista RBAC komponente (Role, RoleBinding, ClusterRole, ClusterRoleBinding)
✅ Luua Roles erinevate kasutajate jaoks
✅ Luua ServiceAccounts rakendustele
✅ Bindida Roles kasutajate ja ServiceAccounts'iga
✅ Testida permissions (`kubectl auth can-i`)
✅ Debuggida RBAC issues
✅ Implementeerida least privilege principle

---

## 🏗️ RBAC Arhitektuur

```
┌────────────────────────────────────────────────────────────┐
│                    RBAC Components                         │
│                                                            │
│  Subject (Who?)        Role (What?)        Binding        │
│  ───────────────       ────────────        ────────       │
│                                                            │
│  User                  Role                RoleBinding    │
│  developer@company ──▶ developer-role ───▶ bind them     │
│                        │                                   │
│                        ├─ get pods                        │
│                        ├─ list services                   │
│                        ├─ exec pods                       │
│                        └─ view logs                       │
│                                                            │
│  ServiceAccount        ClusterRole          ClusterRole   │
│  user-service      ──▶ read-configmaps ──▶  Binding      │
│  (in production ns)    │                                   │
│                        └─ get configmaps                  │
│                          (cluster-wide)                    │
│                                                            │
│  Namespace-scoped:                                        │
│  ├─ Role (permissions within namespace)                  │
│  └─ RoleBinding (bind to namespace)                      │
│                                                            │
│  Cluster-scoped:                                          │
│  ├─ ClusterRole (permissions cluster-wide)               │
│  └─ ClusterRoleBinding (bind cluster-wide)               │
└────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Kontrolli Praegust RBAC Setup

```bash
# Vaata kõiki Roles production namespace'is
kubectl get roles -n production

# Vaata kõiki ServiceAccounts
kubectl get serviceaccounts -n production

# Vaata ClusterRoles (built-in)
kubectl get clusterroles | head -20
```

**Built-in ClusterRoles:**
- `cluster-admin` - Full access (NEVER use in production!)
- `admin` - Namespace admin
- `edit` - Edit resources
- `view` - Read-only access

---

### Samm 2: Loo Developer Role

Developer vajab ligipääsu pods'le, logs'le, services'le.

**Loo fail `developer-role.yaml`:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: production
rules:
  # Pods
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]

  # Exec into pods (debugging)
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create"]

  # Services
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list"]

  # Deployments
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]

  # ConfigMaps (read-only)
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]

  # Secrets (NO ACCESS - use Vault instead!)
  # Intentionally omitted
```

**Apply:**

```bash
kubectl apply -f developer-role.yaml

# Verify
kubectl get role developer -n production
kubectl describe role developer -n production
```

---

### Samm 3: Loo Read-Only Role

Read-only kasutajad (nt. support team) vajavad ainult view access.

**Loo fail `readonly-role.yaml`:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: readonly
  namespace: production
rules:
  # View pods
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]

  # View services
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list"]

  # View deployments
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list"]

  # View configmaps
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]

  # NO exec, NO edit, NO delete
```

**Apply:**

```bash
kubectl apply -f readonly-role.yaml
```

---

### Samm 4: Loo CI/CD ServiceAccount ja Role

CI/CD pipeline vajab õigusi deploy'miseks.

**Loo fail `cicd-role.yaml`:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cicd-deployer
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cicd-deployer
  namespace: production
rules:
  # Deployments (create, update for deployments)
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update", "patch"]

  # Services (create if needed)
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "create", "update"]

  # ConfigMaps (update configuration)
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "create", "update"]

  # Pods (list for verification)
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]

  # NO delete permissions (safer)
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cicd-deployer-binding
  namespace: production
subjects:
  - kind: ServiceAccount
    name: cicd-deployer
    namespace: production
roleRef:
  kind: Role
  name: cicd-deployer
  apiGroup: rbac.authorization.k8s.io
```

**Apply:**

```bash
kubectl apply -f cicd-role.yaml

# Verify ServiceAccount
kubectl get sa -n production cicd-deployer

# Get ServiceAccount token (for GitHub Actions)
kubectl create token cicd-deployer -n production --duration=87600h
# Save this token for Lab 5 CI/CD integration
```

---

### Samm 5: Loo Application ServiceAccount (User-Service)

Rakendused peaksid kasutama dedicated ServiceAccount'i.

**Loo fail `app-serviceaccount.yaml`:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: user-service
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: user-service
  namespace: production
rules:
  # Only read ConfigMaps (application config)
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]

  # NO access to other resources
  # Application should not manage K8s resources
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: user-service-binding
  namespace: production
subjects:
  - kind: ServiceAccount
    name: user-service
    namespace: production
roleRef:
  kind: Role
  name: user-service
  apiGroup: rbac.authorization.k8s.io
```

**Apply:**

```bash
kubectl apply -f app-serviceaccount.yaml
```

**Update user-service Deployment to use ServiceAccount:**

```yaml
# In deployment.yaml
spec:
  template:
    spec:
      serviceAccountName: user-service  # Add this line
      containers:
        - name: user-service
          # ... rest of config
```

```bash
kubectl apply -f user-service-deployment.yaml
```

---

### Samm 6: Test RBAC Permissions

Kubernetes pakub `kubectl auth can-i` command permissions testimiseks.

**Test kui ServiceAccount:**

```bash
# Can user-service get configmaps?
kubectl auth can-i get configmaps \
  --as=system:serviceaccount:production:user-service \
  -n production
# Expected: yes

# Can user-service delete pods?
kubectl auth can-i delete pods \
  --as=system:serviceaccount:production:user-service \
  -n production
# Expected: no

# Can cicd-deployer create deployments?
kubectl auth can-i create deployments \
  --as=system:serviceaccount:production:cicd-deployer \
  -n production
# Expected: yes
```

---

### Samm 7: Simulate User Access (Optional)

Create test kubeconfig erinevate rollidega.

**Create readonly user kubeconfig:**

```bash
# Create RoleBinding for fictional user
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: readonly-user-binding
  namespace: production
subjects:
  - kind: User
    name: john@company.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: readonly
  apiGroup: rbac.authorization.k8s.io
EOF

# Test as user
kubectl auth can-i get pods -n production --as=john@company.com
# Expected: yes

kubectl auth can-i delete pods -n production --as=john@company.com
# Expected: no
```

---

### Samm 8: ClusterRole Example (Monitoring)

Prometheus vajab cluster-wide read access metrics'te jaoks.

**Loo fail `prometheus-clusterrole.yaml`:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  # Nodes metrics
  - apiGroups: [""]
    resources: ["nodes", "nodes/metrics", "nodes/stats"]
    verbs: ["get", "list"]

  # Pods metrics
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]

  # Services and endpoints
  - apiGroups: [""]
    resources: ["services", "endpoints"]
    verbs: ["get", "list", "watch"]

  # Deployments, ReplicaSets (for kube-state-metrics)
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets", "statefulsets"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus-kube-prometheus-prometheus
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: prometheus
  apiGroup: rbac.authorization.k8s.io
```

**Apply:**

```bash
kubectl apply -f prometheus-clusterrole.yaml
```

**Märkus:** Prometheus on juba installitud Lab 6's kube-prometheus-stack'iga, mis automaatselt loob ClusterRole'id.

---

### Samm 9: RBAC Audit

Kontrolli, kes omab mis õigusi.

```bash
# List all RoleBindings in production
kubectl get rolebindings -n production

# Describe specific RoleBinding
kubectl describe rolebinding cicd-deployer-binding -n production

# List all ClusterRoleBindings
kubectl get clusterrolebindings | grep -v system

# Find all subjects with cluster-admin role (DANGEROUS!)
kubectl get clusterrolebindings -o json | \
  jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name'
```

---

### Samm 10: RBAC Best Practices Implementation

**1. Remove default ServiceAccount permissions:**

```yaml
# In deployment
spec:
  template:
    spec:
      automountServiceAccountToken: false  # Disable if not needed
      serviceAccountName: user-service     # Or use dedicated SA
```

**2. Regular RBAC audits:**

```bash
# Create audit script
cat > rbac-audit.sh << 'EOF'
#!/bin/bash
echo "=== RBAC Audit ==="
echo ""
echo "Cluster-admin users (HIGH RISK):"
kubectl get clusterrolebindings -o json | \
  jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .subjects[]? | "\(.kind): \(.name)"'
echo ""
echo "ServiceAccounts with cluster-admin (HIGH RISK):"
kubectl get clusterrolebindings -o json | \
  jq -r '.items[] | select(.roleRef.name=="cluster-admin") | select(.subjects[]?.kind=="ServiceAccount") | .subjects[]? | "\(.namespace)/\(.name)"'
EOF

chmod +x rbac-audit.sh
./rbac-audit.sh
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Developer Role created (production namespace)
- [ ] Read-only Role created
- [ ] CI/CD ServiceAccount ja Role created
- [ ] Application ServiceAccount created (user-service)
- [ ] RoleBindings created
- [ ] Permissions tested (`kubectl auth can-i`)
- [ ] No cluster-admin usage in production
- [ ] All apps use dedicated ServiceAccounts

### Verifitseerimine

```bash
# 1. List all Roles
kubectl get roles -n production

# 2. List all ServiceAccounts
kubectl get sa -n production

# 3. Test permissions
kubectl auth can-i get pods --as=system:serviceaccount:production:user-service -n production

# 4. Verify no cluster-admin in production
kubectl get rolebindings,clusterrolebindings -A -o json | \
  jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name' | \
  grep -v "^system:" || echo "✅ No cluster-admin found (good!)"
```

---

## 🔍 Troubleshooting

### Probleem: "User cannot list pods... forbidden"

**Põhjus:** Missing RBAC permissions

**Lahendus:**

```bash
# Check if RoleBinding exists
kubectl get rolebinding -n production

# Describe RoleBinding
kubectl describe rolebinding <name> -n production

# Check if Role has correct permissions
kubectl describe role <role-name> -n production

# Fix: Add missing permission to Role
kubectl edit role <role-name> -n production
```

---

### Probleem: ServiceAccount token ei tööta

**Lahendus:**

```bash
# Recreate token
kubectl create token <sa-name> -n production --duration=8760h

# Või get token from Secret (older K8s versions)
kubectl get secret -n production
kubectl describe secret <sa-token-secret> -n production
```

---

### Probleem: "error: You must be logged in to the server"

**Põhjus:** Kubeconfig issue

**Lahendus:**

```bash
# Check current context
kubectl config current-context

# View kubeconfig
kubectl config view

# Switch context
kubectl config use-context <context-name>
```

---

## 📚 Mida Sa Õppisid?

✅ **RBAC Components**
  - Role: namespace-scoped permissions
  - RoleBinding: bind Role to Subject
  - ClusterRole: cluster-wide permissions
  - ClusterRoleBinding: bind ClusterRole cluster-wide

✅ **ServiceAccounts**
  - Dedicated SA per application
  - Token-based authentication
  - Minimal permissions (least privilege)

✅ **Permission testing**
  - `kubectl auth can-i`
  - Impersonation (`--as`)
  - RBAC audit

✅ **Security improvements**
  - No cluster-admin in production
  - No default ServiceAccount usage
  - Fine-grained access control

---

## 🚀 Järgmised Sammud

**Exercise 3: Network Policies** - Control pod-to-pod communication:
- Default deny-all policy
- Allow-specific rules
- Zero-trust networking
- Testing network connectivity

```bash
cat exercises/03-network-policies.md
```

---

## 💡 RBAC Best Practices

✅ **Least Privilege:**
- Start with minimal permissions
- Add permissions as needed (not vice versa)
- Review permissions regularly

✅ **Namespace Isolation:**
- Use Roles (not ClusterRoles) when possible
- Separate environments (dev, staging, prod namespaces)
- No cross-namespace access unless required

✅ **ServiceAccount Management:**
- Dedicated SA per application
- No default ServiceAccount usage
- Disable `automountServiceAccountToken` kui ei vajata

✅ **Audit:**
- Regular RBAC audits
- Monitor cluster-admin usage
- Log all RBAC changes

✅ **Documentation:**
- Document why each permission is needed
- Maintain RBAC change log
- Onboarding guide for new users

---

**Õnnitleme! RBAC on configured! 👥🔐**

**Kestus:** 60 minutit
**Järgmine:** Exercise 3 - Network Policies
