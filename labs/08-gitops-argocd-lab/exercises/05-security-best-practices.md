# Harjutus 5: GitOps Security & Best Practices

**Kestus:** 60 minutit
**Eesmärk:** Konfigureeri ArgoCD security (RBAC, SSO, secrets) ja best practices.

---

## 📋 Ülevaade

Selles harjutuses konfigureerime **production-ready ArgoCD security**:

1. **RBAC** - Fine-grained access control (developers, ops, admins)
2. **SSO** - GitHub/Google authentication
3. **ArgoCD Image Updater** - Automated image tag updates GitOps-friendly way
4. **Sealed Secrets Integration** - Lab 7 integration
5. **Multi-Cluster** - Manage multiple Kubernetes clusters
6. **Best Practices** - Security hardening

**Security Principles:**
- ✅ Least privilege (minimize permissions)
- ✅ Separation of duties (developers != cluster-admin)
- ✅ Audit trail (who deployed what when)
- ✅ Secrets encryption (never plain text in Git)
- ✅ SSO (centralized authentication)
- ✅ RBAC (fine-grained authorization)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Konfigureerida ArgoCD RBAC policies
- ✅ Integreerida GitHub SSO
- ✅ Luua project-based access control
- ✅ Installida ja konfigureerida Image Updater
- ✅ Integreerida Sealed Secrets (Lab 7)
- ✅ Manageerida multiple Kubernetes clusters
- ✅ Implementeerida security best practices
- ✅ Auditeerida ArgoCD events

---

## 🏗️ ArgoCD Security Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                 ArgoCD Security Layers                          │
│                                                                │
│  1. Authentication (Who are you?)                              │
│  ┌──────────────────────────────────────────────────┐          │
│  │  SSO (GitHub, Google, LDAP, SAML)                │          │
│  │  ├── developer@company.com                       │          │
│  │  ├── ops@company.com                             │          │
│  │  └── admin@company.com                           │          │
│  └──────────────────────────────────────────────────┘          │
│                       │                                         │
│                       ▼                                         │
│  2. Authorization (What can you do?)                           │
│  ┌──────────────────────────────────────────────────┐          │
│  │  RBAC Policies                                   │          │
│  │  ├── role:developer (read apps, sync dev/staging)│          │
│  │  ├── role:ops (manage all apps, no create/delete)│          │
│  │  └── role:admin (full access)                   │          │
│  └──────────────────────────────────────────────────┘          │
│                       │                                         │
│                       ▼                                         │
│  3. Projects (Resource isolation)                              │
│  ┌──────────────────────────────────────────────────┐          │
│  │  Project: team-backend                           │          │
│  │  ├── Allowed repos: github.com/company/backend   │          │
│  │  ├── Allowed clusters: production                │          │
│  │  └── Allowed namespaces: backend-*               │          │
│  └──────────────────────────────────────────────────┘          │
│                       │                                         │
│                       ▼                                         │
│  4. Secrets Management                                         │
│  ┌──────────────────────────────────────────────────┐          │
│  │  Sealed Secrets (Lab 7)                          │          │
│  │  ├── Encrypted in Git                            │          │
│  │  └── Decrypted in cluster only                   │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### PART 1: ArgoCD RBAC

### Samm 1: Understand ArgoCD RBAC Model

**RBAC Components:**
- **Policy CSV:** Define permissions (who can do what)
- **Policy Default:** Default role for unknown users
- **Groups:** Bind users to roles (from SSO)

**RBAC Policy Format:**
```
p, <subject>, <resource>, <action>, <object>, <effect>

p, role:developer, applications, get, */*, allow
│  │                │              │    │     │
│  └─ Role          └─ Resource    │    │     └─ Allow/Deny
│                                  │    └─ Object (project/app)
│                                  └─ Action (get/create/sync/delete)
```

---

### Samm 2: Create RBAC Policies

**Create RBAC ConfigMap:**

```bash
cat > argocd-rbac-cm.yaml << 'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  # Policy CSV
  policy.csv: |
    # ========================================
    # Developers
    # ========================================
    # Can view all applications
    p, role:developer, applications, get, */*, allow
    p, role:developer, applications, list, */*, allow
    
    # Can sync dev and staging (not production!)
    p, role:developer, applications, sync, */dev-*, allow
    p, role:developer, applications, sync, */staging-*, allow
    
    # Can view logs and exec (debugging)
    p, role:developer, logs, get, */*, allow
    p, role:developer, exec, create, */dev-*, allow
    p, role:developer, exec, create, */staging-*, allow
    
    # CANNOT create/delete applications
    # CANNOT sync production
    
    # ========================================
    # Operations Team
    # ========================================
    # Can manage all applications (sync, rollback)
    p, role:ops, applications, *, */*, allow
    
    # Can view cluster info
    p, role:ops, clusters, get, *, allow
    
    # Can view logs and exec everywhere
    p, role:ops, logs, get, */*, allow
    p, role:ops, exec, create, */*, allow
    
    # CANNOT create/delete applications (only admins)
    p, role:ops, applications, create, */*, deny
    p, role:ops, applications, delete, */*, deny
    
    # ========================================
    # Administrators
    # ========================================
    # Full access (built-in admin role)
    p, role:admin, *, *, *, allow
    
    # ========================================
    # CI/CD Service Account
    # ========================================
    # Can only sync (not create/delete)
    p, role:cicd, applications, get, */*, allow
    p, role:cicd, applications, sync, */*, allow
    
    # ========================================
    # Group Bindings (SSO groups)
    # ========================================
    # GitHub team mapping (from SSO)
    g, company:developers, role:developer
    g, company:ops-team, role:ops
    g, company:platform-admins, role:admin
    
    # Local users (for testing without SSO)
    g, developer-user, role:developer
    g, ops-user, role:ops
    g, admin-user, role:admin
  
  # Default policy for unknown users (readonly)
  policy.default: role:readonly
  
  # Readonly role definition
  policy.csv: |
    # ... (add to policy.csv above)
    # ========================================
    # Readonly (default for unknown users)
    # ========================================
    p, role:readonly, applications, get, */*, allow
    p, role:readonly, applications, list, */*, allow
    # NO sync, NO exec, NO logs
YAML
```

**Apply RBAC:**

```bash
# Apply ConfigMap
kubectl apply -f argocd-rbac-cm.yaml

# Restart ArgoCD server to reload RBAC
kubectl rollout restart deployment argocd-server -n argocd

# Wait for restart
kubectl rollout status deployment argocd-server -n argocd
```

---

### Samm 3: Test RBAC (Local Users)

**Create local users (testing without SSO):**

```bash
# Create bcrypt password hash
htpasswd -nbBC 10 "" 'password123' | tr -d ':\n' | sed 's/$2y/$2a/'

# Output: $2a$10$...hash...

# Add to argocd-secret
kubectl patch secret argocd-secret -n argocd --type json -p='[
  {
    "op": "add",
    "path": "/data/accounts.developer-user.password",
    "value": "BASE64_ENCODED_BCRYPT_HASH"
  }
]'
```

**Test permissions via CLI:**

```bash
# Login as developer
argocd login localhost:8080 \
  --username developer-user \
  --password 'password123'

# Try to sync dev app (should succeed)
argocd app sync user-service-dev

# Try to sync production app (should fail: permission denied)
argocd app sync user-service-prod
# Error: permission denied
```

---

### PART 2: SSO Integration (GitHub)

### Samm 4: Configure GitHub OAuth App

**Create GitHub OAuth App:**

1. GitHub → Settings → Developer settings → OAuth Apps → New OAuth App
2. Application name: `ArgoCD Lab 8`
3. Homepage URL: `http://localhost:8080`
4. Authorization callback URL: `http://localhost:8080/api/dex/callback`
5. Click "Register application"
6. Copy **Client ID** and **Client Secret**

---

### Samm 5: Configure ArgoCD for GitHub SSO

**Update argocd-cm ConfigMap:**

```bash
cat > argocd-cm-sso.yaml << 'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  # GitHub SSO via Dex
  dex.config: |
    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: YOUR_GITHUB_CLIENT_ID
          clientSecret: $dex.github.clientSecret  # Reference to secret
          orgs:
            - name: YOUR_GITHUB_ORG  # Replace with your GitHub org
              teams:
                - developers
                - ops-team
                - platform-admins
YAML

# Apply
kubectl apply -f argocd-cm-sso.yaml
```

**Add GitHub client secret:**

```bash
# Add to argocd-secret
kubectl patch secret argocd-secret -n argocd --type json -p='[
  {
    "op": "add",
    "path": "/data/dex.github.clientSecret",
    "value": "BASE64_ENCODED_CLIENT_SECRET"
  }
]'

# Example:
echo -n 'YOUR_GITHUB_CLIENT_SECRET' | base64
```

**Restart Dex and ArgoCD Server:**

```bash
# Restart
kubectl rollout restart deployment argocd-dex-server -n argocd
kubectl rollout restart deployment argocd-server -n argocd

# Wait
kubectl rollout status deployment argocd-dex-server -n argocd
kubectl rollout status deployment argocd-server -n argocd
```

---

### Samm 6: Login via GitHub SSO

**Access ArgoCD UI:**

1. Open: http://localhost:8080
2. Click "Login via GitHub"
3. Authorize ArgoCD to access your GitHub org
4. Redirected to ArgoCD dashboard
5. Your permissions based on RBAC policy (GitHub team → ArgoCD role)

**Verify SSO user:**

```bash
# Get current user info
argocd account get-user-info

# Output:
# Logged In: Yes
# Username: github:YOUR_USERNAME
# Groups: company:developers
```

---

### PART 3: ArgoCD Projects (Resource Isolation)

### Samm 7: Create ArgoCD Projects

Projects võimaldavad isoleerida resources per team.

**Create backend team project:**

```bash
cat > argocd-project-backend.yaml << 'YAML'
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-backend
  namespace: argocd
spec:
  description: Backend team applications
  
  # Source repositories (whitelist)
  sourceRepos:
    - https://github.com/YOUR_ORG/backend-services.git
    - https://github.com/YOUR_ORG/hostinger.git  # Lab repo
  
  # Destination clusters and namespaces (whitelist)
  destinations:
    - namespace: 'backend-*'  # Only backend-* namespaces
      server: https://kubernetes.default.svc
    - namespace: development
      server: https://kubernetes.default.svc
    - namespace: staging
      server: https://kubernetes.default.svc
  
  # Cluster resource whitelist
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace  # Can create namespaces
  
  # Namespace resource whitelist
  namespaceResourceWhitelist:
    - group: 'apps'
      kind: Deployment
    - group: ''
      kind: Service
    - group: ''
      kind: ConfigMap
    - group: ''
      kind: Secret
  
  # Roles (project-specific RBAC)
  roles:
    # Backend developers
    - name: developer
      description: Backend developers
      policies:
        - p, proj:team-backend:developer, applications, *, team-backend/*, allow
      groups:
        - company:backend-developers
YAML

# Apply
kubectl apply -f argocd-project-backend.yaml
```

**Use project in Application:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service
  namespace: argocd
spec:
  project: team-backend  # Use team-backend project (not default)
  # ... rest of spec
```

---

### PART 4: ArgoCD Image Updater

### Samm 8: Install ArgoCD Image Updater

Image Updater автоматично updates image tags in Git when new images published.

**Install via Helm:**

```bash
# Add Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install Image Updater
helm install argocd-image-updater argo/argocd-image-updater \
  --namespace argocd \
  --set config.argocd.serverAddress=http://argocd-server.argocd.svc \
  --set config.registries[0].name=docker.io \
  --set config.registries[0].api_url=https://registry-1.docker.io \
  --wait

# Verify
kubectl get pods -n argocd | grep image-updater
```

---

### Samm 9: Configure Image Updater for Application

**Annotate Application to enable Image Updater:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service-prod
  namespace: argocd
  
  annotations:
    # Enable Image Updater
    argocd-image-updater.argoproj.io/image-list: user-service=YOUR_USERNAME/user-service
    
    # Update strategy (semver, latest, digest)
    argocd-image-updater.argoproj.io/user-service.update-strategy: semver
    
    # Allow tags matching pattern
    argocd-image-updater.argoproj.io/user-service.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
    
    # Git write-back (update Git with new tag)
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/git-branch: main
spec:
  # ... rest of Application
```

**Workflow:**
1. CI builds new image: `YOUR_USERNAME/user-service:v2.1.0`
2. Image Updater detects new tag (semver)
3. Image Updater updates manifest in Git (`image: ...v2.1.0`)
4. Image Updater commits to Git
5. ArgoCD detects Git change
6. ArgoCD syncs new version

**GitOps-friendly!** Everything via Git commits.

---

### PART 5: Sealed Secrets Integration (Lab 7)

### Samm 10: Integrate Sealed Secrets with ArgoCD

**Sealed Secrets (from Lab 7) + ArgoCD = Secure secrets in Git.**

**Workflow:**

1. **Create secret:**
   ```bash
   kubectl create secret generic db-password \
     --from-literal=password=SuperSecret123 \
     --dry-run=client -o yaml > secret.yaml
   ```

2. **Seal secret (Lab 7):**
   ```bash
   kubeseal < secret.yaml > sealed-secret.yaml
   ```

3. **Commit sealed secret to Git:**
   ```bash
   git add k8s/user-service/base/sealed-secret.yaml
   git commit -m "Add DB password (sealed)"
   git push
   ```

4. **ArgoCD deploys SealedSecret:**
   - ArgoCD syncs SealedSecret CRD to cluster
   - Sealed Secrets controller decrypts
   - Regular Secret created in cluster
   - Application consumes Secret

**Security:** Plain secret NEVER in Git. Only encrypted SealedSecret.

---

### PART 6: Multi-Cluster Management

### Samm 11: Add External Cluster to ArgoCD

ArgoCD võib hallata mitmeid clusters.

**Add cluster via CLI:**

```bash
# List contexts
kubectl config get-contexts

# Add cluster to ArgoCD
argocd cluster add <context-name>

# Example:
argocd cluster add production-cluster

# Verify
argocd cluster list

# Output:
# SERVER                          NAME                VERSION
# https://kubernetes.default.svc  in-cluster          1.28
# https://prod.k8s.example.com    production-cluster  1.28
```

**Deploy to external cluster:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service-prod-external
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/hostinger.git
    targetRevision: HEAD
    path: k8s/user-service/overlays/production
  
  destination:
    server: https://prod.k8s.example.com  # External cluster!
    namespace: production
```

---

### PART 7: Security Best Practices

### Samm 12: Security Hardening Checklist

**1. Disable admin account (use SSO only):**

```bash
# Remove admin account password
kubectl patch secret argocd-secret -n argocd -p '{"data": {"admin.password": null}}'

# Admin can only login via SSO now
```

**2. Network Policies (Lab 7 integration):**

```yaml
# Allow only Ingress traffic to ArgoCD
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-server-ingress
  namespace: argocd
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
```

**3. Enable audit logging:**

```yaml
# In argocd-cm ConfigMap
data:
  server.rbac.log.enforce.enable: "true"  # Log RBAC denials
  
  # Send logs to stdout (collected by Lab 6 Loki)
  server.log.level: info
  server.log.format: json
```

**4. Limit repository access (HTTPS only, no SSH):**

```yaml
# In argocd-cm ConfigMap
data:
  repositories: |
    - url: https://github.com/YOUR_ORG/repo.git
      type: git
      # NO SSH keys
```

**5. Enable TLS for ArgoCD UI (production):**

```yaml
# Use cert-manager (Lab 4) for TLS certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: argocd-server-tls
  namespace: argocd
spec:
  secretName: argocd-server-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - argocd.example.com
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] RBAC policies created (developer, ops, admin)
- [ ] SSO configured (GitHub OAuth)
- [ ] SSO login tested
- [ ] ArgoCD Project created (team isolation)
- [ ] Image Updater installed
- [ ] Image Updater annotation configured
- [ ] Sealed Secrets integrated
- [ ] External cluster added (optional)
- [ ] Security hardening applied

### Verifitseerimine

```bash
# 1. Check RBAC ConfigMap
kubectl get configmap argocd-rbac-cm -n argocd -o yaml

# 2. Test SSO login
argocd login localhost:8080 --sso

# 3. Check user groups
argocd account get-user-info

# 4. Check projects
kubectl get appprojects -n argocd

# 5. Check Image Updater
kubectl get pods -n argocd | grep image-updater

# 6. Check audit logs
kubectl logs -n argocd deployment/argocd-server | grep RBAC
```

---

## 🔍 Troubleshooting

### Probleem: SSO login fails "Callback URL mismatch"

**Lahendus:**

```bash
# Ensure GitHub OAuth App callback URL matches:
# http://localhost:8080/api/dex/callback

# Or for production:
# https://argocd.example.com/api/dex/callback
```

---

### Probleem: User has no permissions after SSO login

**Lahendus:**

```bash
# Check user groups
argocd account get-user-info

# Ensure GitHub team matches RBAC group binding
# In argocd-rbac-cm:
# g, company:developers, role:developer

# User must be member of "developers" team in GitHub org
```

---

### Probleem: Image Updater not updating images

**Lahendus:**

```bash
# Check Image Updater logs
kubectl logs -n argocd deployment/argocd-image-updater

# Common issues:
# - Registry credentials missing
# - Tag pattern doesn't match
# - Git write-back credentials missing

# Enable debug logging:
kubectl set env deployment/argocd-image-updater \
  -n argocd \
  ARGOCD_IMAGE_UPDATER_LOG_LEVEL=debug
```

---

## 📚 Mida Sa Õppisid?

✅ **RBAC**
  - Policy CSV format
  - Role-based permissions
  - Group bindings (SSO integration)
  - Default policies

✅ **SSO**
  - GitHub OAuth integration
  - Dex connector configuration
  - Centralized authentication
  - Team-based authorization

✅ **Projects**
  - Resource isolation per team
  - Repository whitelisting
  - Cluster/namespace restrictions
  - Project-specific RBAC

✅ **Image Updater**
  - Automated image tag updates
  - GitOps-friendly workflow
  - Semver strategy
  - Git write-back

✅ **Security**
  - Sealed Secrets integration
  - Network Policies
  - Audit logging
  - Multi-cluster access control

---

## 🚀 Lab 8 Complete!

**Õnnitleme! Sa läbisid Lab 8: GitOps with ArgoCD! 🎉🚀**

**Mida sa saavutasid:**
- ✅ ArgoCD installitud ja konfigureeritud
- ✅ Esimene rakendus deployed GitOps workflow'ga
- ✅ Multi-environment deployment (Kustomize)
- ✅ ApplicationSet ja Argo Rollouts (advanced workflows)
- ✅ Production-ready security (RBAC, SSO, secrets)

**Järgmised sammud:**
- Lab 9: Backup & Disaster Recovery (Velero)
- Lab 10: Infrastructure as Code (Terraform + Kubernetes)

---

## 💡 GitOps Security Best Practices Summary

✅ **Authentication:**
- Always use SSO (never local users in production)
- Disable admin password after SSO configured
- Rotate credentials regularly

✅ **Authorization:**
- Principle of least privilege (minimal permissions)
- Use Projects for team isolation
- RBAC policies in Git (version controlled)

✅ **Secrets:**
- Never plain secrets in Git
- Use Sealed Secrets or External Secrets Operator
- Rotate secrets regularly

✅ **Audit:**
- Enable RBAC audit logging
- Send logs to centralized logging (Lab 6 Loki)
- Monitor ArgoCD metrics (Prometheus)

✅ **Network:**
- Network Policies (Lab 7) for ArgoCD namespace
- TLS for ArgoCD UI (cert-manager)
- Restrict repository access (HTTPS only)

✅ **GitOps Hygiene:**
- Git as single source of truth
- All changes via Git commits (no manual kubectl)
- Review all PRs before merge
- Use branch protection (require reviews)

---

**Kestus:** 60 minutit
**Lab 8 Total:** 5 hours (5 exercises × 60 min)
**Status:** ✅ Complete

