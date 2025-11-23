# Peatükk 22: Security Best Practices

**Kestus:** 5 tundi
**Eeldused:** Peatükk 9-14 (Kubernetes core + advanced)
**Eesmärk:** Mõista security mindset'i ja defense-in-depth strateegiaid

---

## Õpieesmärgid

- Security mindset (defense in depth, least privilege, zero trust)
- RBAC fundamentals (millal kasutada, millal mitte)
- Secret management strategies (Vault, Sealed Secrets, external providers)
- Network isolation (Network Policies, service mesh)
- Container security (image scanning, runtime security)
- Security trade-offs (convenience vs security)
- Compliance basics (GDPR, SOC2, PCI-DSS)

---

## 22.1 Security Mindset

### Defense in Depth

**Concept: Multiple security layers**

```
Security is NOT one wall - it's multiple concentric walls:

Layer 1: Network perimeter (firewall, VPN)
  → Attacker bypasses (phishing email)

Layer 2: Application authentication (JWT, OAuth)
  → Attacker steals token (XSS vulnerability)

Layer 3: Database encryption (TLS, encryption at rest)
  → Attacker gains DB access (SQL injection)

Layer 4: Audit logging (who accessed what, when)
  → Detection of breach (forensics)

Result: Even if Layer 1-3 fail, Layer 4 detects the breach
```

**Põhjendus:** Single layer security FAILS. Defense in depth = multiple layers (attacker must break ALLE layers).

---

### Least Privilege Principle

**Concept: Give MINIMUM necessary permissions**

```
❌ BAD:
  Developer needs to deploy app
  → Give cluster-admin access (full Kubernetes control)

  Result: Developer accidentally deletes production namespace!

✅ GOOD:
  Developer needs to deploy app
  → Give deploy-only access (specific namespace)

  Result: Developer CAN deploy, but CANNOT delete namespaces
```

**Põhjendus:** "With great power comes great responsibility" - but also great RISK. Limit blast radius (minimize damage if compromised).

---

### Zero Trust Architecture

**Traditional security (perimeter-based):**

```
Inside network: TRUSTED (no auth between services)
Outside network: UNTRUSTED (firewall blocks)

Problem: If attacker gets inside → free access to everything!
```

**Zero Trust (verify everything):**

```
NO implicit trust - EVERY request authenticated & authorized:

Service A → Service B:
  1. Service A presents certificate (mutual TLS)
  2. Service B verifies certificate
  3. Service B checks RBAC (is Service A allowed?)
  4. Request permitted

Result: Breach of Service A ≠ access to Service B
```

**Põhjendus:** "Never trust, always verify" - assume breach has happened, verify EVERY interaction.

---

## 22.2 RBAC (Role-Based Access Control)

### Why RBAC?

**Scenario WITHOUT RBAC:**

```
All users have cluster-admin access:
  - Developers can delete production Pods
  - QA can modify secrets
  - Intern can delete PersistentVolumes

Result: Accidents happen, data lost!
```

**Scenario WITH RBAC:**

```
Roles:
  - cluster-admin: Infra team (full access)
  - developer: Deploy to dev/staging namespaces
  - viewer: Read-only access (logs, metrics)
  - ci-cd-bot: Deploy to all namespaces (automated)

Result: Developers CAN deploy, CANNOT delete production
```

---

### RBAC Components

**Roles:**

```
Role = Set of permissions

Example "pod-reader" Role:
  - Can: get, list, watch Pods
  - Cannot: create, delete, update Pods

Example "deployer" Role:
  - Can: get, list, create, update, delete Pods, Deployments
  - Cannot: delete namespaces, modify RBAC
```

**RoleBinding:**

```
RoleBinding = Assign Role to User/Group

Example:
  Role: "deployer"
  User: "alice@company.com"
  Namespace: "staging"

Result: Alice can deploy to staging namespace (not production!)
```

**ClusterRole vs Role:**

```
Role: Namespace-scoped (specific namespace only)
ClusterRole: Cluster-wide (all namespaces)

Use ClusterRole for:
  - Cluster-admin (infra team)
  - Viewer (read-only all namespaces)

Use Role for:
  - Developers (specific namespace)
```

---

### Common RBAC Patterns

**1. Namespace isolation (multi-team)**

```
Team A:
  - Namespace: team-a
  - Role: deployer (full access to team-a namespace)
  - Cannot access: team-b namespace

Team B:
  - Namespace: team-b
  - Role: deployer (full access to team-b namespace)
  - Cannot access: team-a namespace

Benefit: Teams isolated (Team A cannot break Team B)
```

---

**2. CI/CD service account**

```
Service Account: "ci-cd-bot"
  - Role: deployer (can deploy to all namespaces)
  - Cannot: modify RBAC, delete PVs

GitHub Actions uses this account:
  - kubectl apply -f deployment.yaml (permitted)
  - kubectl delete namespace prod (denied!)

Benefit: CI/CD automated, but restricted (cannot delete critical resources)
```

---

**3. Read-only access (QA, auditors)**

```
Role: "viewer"
  - Can: get, list, watch (all resources)
  - Cannot: create, update, delete

Use case: QA needs to check logs, metrics (not modify)
```

---

### RBAC Anti-Patterns

**❌ Everyone gets cluster-admin**

```
Reason: "It's easier"
Risk: Anyone can delete production (accidental or malicious)
```

**❌ One service account for all apps**

```
Reason: "Less management"
Risk: Compromised app = access to ALL namespaces
```

**Fix:** One service account PER app (isolated blast radius)

---

## 22.3 Secret Management

### Why Secrets Don't Belong in Git

**❌ NEVER COMMIT SECRETS:**

```
# .env file (committed to Git)
DB_PASSWORD=supersecret123
JWT_SECRET=mytoken456

Problem:
  - Git history is PERMANENT (secret exposed forever!)
  - Public repo = secret leaked to internet
  - Developer laptop stolen = attacker has secrets
```

**✅ USE external secret management:**

```
Git repository:
  - deployment.yaml (references Secret, not contains Secret)

Kubernetes Secret (created separately):
  - kubectl create secret ... (not committed to Git)

External Vault (best):
  - Secrets stored in HashiCorp Vault
  - Kubernetes fetches at runtime (short-lived tokens)
```

---

### Kubernetes Secrets Limitations

**Kubernetes Secret = base64 encoded (NOT encrypted!)**

```
Create Secret:
  kubectl create secret generic db-pass --from-literal=password=secret123

Stored in etcd (base64):
  cGFzc3dvcmQ6c2VjcmV0MTIz  (anyone with etcd access can decode!)

Decode:
  echo "cGFzc3dvcmQ6c2VjcmV0MTIz" | base64 -d
  → password:secret123

Problem: Base64 is NOT encryption (just encoding)!
```

**Mitigation:**
- ✅ Enable etcd encryption at rest (encrypt etcd datastore)
- ✅ RBAC (restrict Secret access to specific ServiceAccounts)
- ✅ External secret managers (Vault, AWS Secrets Manager)

---

### External Secret Managers

**HashiCorp Vault:**

```
Architecture:
  1. Secrets stored in Vault (encrypted)
  2. App requests secret (authenticates with Kubernetes token)
  3. Vault verifies token (is this Pod allowed?)
  4. Vault returns short-lived secret (expires in 1h)

Benefit:
  - Secrets NEVER stored in Kubernetes
  - Short-lived tokens (limit blast radius)
  - Audit log (who accessed what secret, when)
```

**Sealed Secrets (Bitnami):**

```
Problem: Can't commit Secrets to Git (plaintext)

Solution: Sealed Secrets (encrypted Secret)
  1. Create Secret (plaintext)
  2. Encrypt with kubeseal tool (public key)
  3. Commit SealedSecret to Git (encrypted, safe!)
  4. Sealed Secrets Controller decrypts (private key in cluster)

Benefit: GitOps-friendly (secrets in Git, but encrypted)
```

**Cloud provider secret managers:**

```
AWS Secrets Manager, Azure Key Vault, GCP Secret Manager:
  - Store secrets in cloud provider
  - Kubernetes fetches at runtime (IAM authentication)
  - Rotation supported (auto-rotate DB passwords)
```

---

### Secret Rotation

**Why rotate secrets?**

```
Scenario: Employee leaves company

Without rotation:
  - Ex-employee knows DB password (risk!)

With rotation:
  - DB password rotated weekly (ex-employee's knowledge expired)

Benefit: Limit window of exposure
```

**Rotation strategies:**

```
Manual rotation (bad):
  - DevOps changes secret monthly
  - Risky (forgotten, inconsistent)

Automated rotation (good):
  - Vault rotates DB password daily
  - App fetches new password automatically
  - No manual intervention
```

---

## 22.4 Network Security

### Network Policies - Firewall for Pods

**Without Network Policies:**

```
Default Kubernetes behavior: ALL Pods can talk to ALL Pods

Scenario:
  - Frontend Pod can access Database Pod (expected)
  - Backend Pod can access Database Pod (expected)
  - Random Pod can access Database Pod (UNEXPECTED!)

Risk: Compromised Pod = access to entire cluster
```

**With Network Policies:**

```
Policy: "Database Pod accepts connections ONLY from Backend Pod"

Result:
  - Frontend Pod → Database: BLOCKED
  - Backend Pod → Database: ALLOWED
  - Random Pod → Database: BLOCKED

Benefit: Lateral movement prevented (compromised Frontend ≠ access to DB)
```

---

### Network Policy Concept

**Ingress vs Egress:**

```
Ingress = Incoming traffic TO Pod
  Example: "Backend Pod accepts traffic FROM Frontend Pod"

Egress = Outgoing traffic FROM Pod
  Example: "Frontend Pod can connect TO api.external.com"
```

**Default deny pattern (best practice):**

```
Step 1: Block ALL traffic (default deny)
Step 2: Allow specific traffic (whitelist)

Example:
  1. Default: No Pod can talk to Database
  2. Allow: Backend Pod → Database (port 5432)

Result: Only Backend can access Database (everything else blocked)
```

---

### Service Mesh (Advanced)

**Problem: Network Policies = Layer 4 (IP/port only)**

```
Network Policy:
  "Pod A can connect to Pod B port 3000"

But CANNOT:
  - Authenticate (is Pod A really Pod A, or attacker spoofing?)
  - Encrypt (traffic plaintext, sniffable)
  - Rate limit (Pod A sending 1M req/s, DDoS)
```

**Solution: Service Mesh (Layer 7 security)**

```
Service Mesh (Istio, Linkerd):
  - Mutual TLS (authenticate BOTH sides, encrypt traffic)
  - Authorization (is Pod A allowed to call /users endpoint?)
  - Observability (trace requests, detect anomalies)
  - Rate limiting (Pod A max 100 req/s)

Benefit: Zero-trust network (verify EVERY request)
```

**Trade-off:**

```
Benefit: Strong security (mutual TLS, fine-grained policies)
Cost: Complexity (learning curve, operational overhead)

Recommendation: Start with Network Policies → add Service Mesh if needed
```

---

## 22.5 Container Security

### Image Scanning (Vulnerability Detection)

**Why scan images?**

```
Scenario:
  Your code: Secure ✅
  Base image (node:18): Contains CVE-2023-12345 (CRITICAL exploit) ❌

Result: Production vulnerable (attacker exploits base image)
```

**Image scanning tools:**

```
Trivy (CNCF project):
  - Scan: trivy image myorg/backend:1.0
  - Detects: CVE-2023-12345 (CRITICAL)
  - Action: Update base image OR apply patch

Harbor (registry with built-in scanning):
  - Auto-scan on push
  - Block deployment if CRITICAL vulnerabilities

Benefit: Catch vulnerabilities BEFORE production
```

---

### Minimal Base Images

**❌ BAD: Full OS image**

```
FROM ubuntu:22.04  (1GB image)

Problem:
  - Contains: bash, curl, wget, gcc, ssh (attack surface!)
  - Vulnerabilities: 500+ packages = 500+ CVEs to patch
```

**✅ GOOD: Minimal image**

```
FROM node:18-alpine  (100MB image, 10x smaller)

Benefit:
  - Minimal packages (only Node.js + essential libs)
  - Fewer vulnerabilities (less attack surface)
  - Faster pulls (smaller size)
```

**BEST: Distroless image**

```
FROM gcr.io/distroless/nodejs:18  (50MB, no shell!)

Benefit:
  - NO shell (attacker cannot run bash commands!)
  - NO package manager (cannot install tools)
  - Minimal CVEs

Trade-off: Harder to debug (no shell for troubleshooting)
```

---

### Runtime Security

**Pod Security Standards (PSS):**

```
Privileged (unsafe):
  - Root user allowed
  - Host network allowed
  - Privileged containers allowed

Baseline (moderate):
  - Non-root user
  - Read-only root filesystem
  - No privileged containers

Restricted (secure):
  - All of Baseline +
  - Drop all capabilities
  - Seccomp profile (syscall filtering)
```

**Example restriction:**

```
Baseline policy:
  - Container MUST run as non-root (UID 1000)
  - Container CANNOT mount host filesystem

Result: Compromised container CANNOT:
  - Access host filesystem (isolated)
  - Run as root (limited privileges)
```

---

### Security Contexts

**Why security contexts?**

```
Default container behavior:
  - Runs as root (UID 0)
  - Read-write filesystem
  - All Linux capabilities

Risk: Compromised container = root access!
```

**Security context example (concept):**

```
Run as non-root (UID 1000):
  - Benefit: Attacker cannot modify /etc/passwd (permission denied)

Read-only filesystem:
  - Benefit: Attacker cannot write malware to disk

Drop capabilities:
  - Benefit: Attacker cannot open raw sockets (network sniffing blocked)
```

---

## 22.6 Supply Chain Security

### Image Provenance (Where Did This Image Come From?)

**Problem: Untrusted images**

```
Scenario:
  Developer pulls: docker pull randomuser/backend:latest

Risk:
  - Who is "randomuser"? (not verified)
  - Image contains malware? (backdoor, crypto miner)
  - Image modified after build? (man-in-the-middle)
```

**Solution: Image signing and verification**

```
Cosign (CNCF project):
  1. Build image: docker build -t myorg/backend:1.0 .
  2. Sign image: cosign sign myorg/backend:1.0 (cryptographic signature)
  3. Verify before deploy: cosign verify myorg/backend:1.0

Benefit: Only signed images deployed (provenance verified)
```

---

### SBOM (Software Bill of Materials)

**What is SBOM?**

```
SBOM = List of ALL dependencies in image

Example SBOM:
  - Node.js 18.19.0
  - Express 4.18.2
  - PostgreSQL client 8.11.3
  - OpenSSL 3.0.2

Use case: Vulnerability discovered in OpenSSL 3.0.2
  → Query SBOM: Which images contain vulnerable OpenSSL?
  → Rebuild affected images

Benefit: Rapid response to vulnerabilities
```

---

## 22.7 Compliance and Auditing

### Compliance Requirements

**GDPR (EU):**

```
Requirements:
  - Data encryption (at rest, in transit)
  - Access control (who can access user data)
  - Audit logging (track data access)
  - Data deletion (right to be forgotten)

Kubernetes implications:
  - etcd encryption (data at rest)
  - TLS everywhere (data in transit)
  - RBAC + audit logs (access control)
```

**SOC 2 (US):**

```
Requirements:
  - Access control (least privilege)
  - Change management (audit trail for changes)
  - Monitoring and alerting (detect anomalies)

Kubernetes implications:
  - RBAC (least privilege)
  - GitOps (all changes in Git = audit trail)
  - Prometheus + alerting (anomaly detection)
```

**PCI-DSS (payment data):**

```
Requirements:
  - Network segmentation (isolate payment systems)
  - Encryption (TLS, encryption at rest)
  - Logging and monitoring (detect breaches)

Kubernetes implications:
  - Network Policies (isolate payment namespace)
  - TLS everywhere (encryption)
  - Centralized logging (audit trail)
```

---

### Audit Logging

**Kubernetes Audit Logs:**

```
What gets logged:
  - Who: User/ServiceAccount
  - What: kubectl delete pod
  - When: 2025-01-23 10:15:32
  - Where: Namespace=production
  - Result: Success or Failure

Use case: "Who deleted production database Pod?"
  → Audit log: User=john@company.com, Action=delete Pod, Time=...

Benefit: Forensics (investigate incidents)
```

---

## 22.8 Security Checklist

### Pre-Production Security Checklist

**Infrastructure:**
- [ ] etcd encryption enabled (encrypt secrets at rest)
- [ ] TLS everywhere (API server, kubelet, etcd)
- [ ] Network Policies enabled (default deny)
- [ ] RBAC configured (least privilege)
- [ ] Audit logging enabled (who did what, when)

**Application:**
- [ ] Images scanned (no CRITICAL vulnerabilities)
- [ ] Images signed (cosign/notary)
- [ ] Secrets in external manager (Vault, AWS Secrets Manager)
- [ ] Non-root containers (runAsNonRoot: true)
- [ ] Read-only filesystem (readOnlyRootFilesystem: true)

**Monitoring:**
- [ ] Audit log monitoring (detect suspicious activity)
- [ ] Vulnerability alerts (new CVEs discovered)
- [ ] Failed auth alerts (brute force attempts)

**Compliance:**
- [ ] GDPR requirements met (if EU users)
- [ ] SOC 2 requirements met (if B2B SaaS)
- [ ] PCI-DSS requirements met (if handling payment data)

---

## Kokkuvõte

**Security mindset:**
- **Defense in depth:** Multiple security layers (not one wall)
- **Least privilege:** Give MINIMUM necessary permissions
- **Zero trust:** Never trust, always verify (every request authenticated)

**RBAC:**
- **Roles:** Set of permissions (pod-reader, deployer, viewer)
- **RoleBinding:** Assign Role to User (namespace-scoped)
- **ClusterRole:** Cluster-wide roles (cluster-admin, read-only-all)
- **Best practice:** One ServiceAccount per app (isolated blast radius)

**Secret management:**
- **Kubernetes Secrets:** Base64 encoded (NOT encrypted!)
- **External managers:** Vault, AWS Secrets Manager (encrypted, short-lived)
- **Sealed Secrets:** GitOps-friendly (encrypted in Git)
- **Secret rotation:** Automated (daily/weekly) to limit exposure window

**Network security:**
- **Network Policies:** Firewall for Pods (default deny + whitelist)
- **Service Mesh:** Mutual TLS, fine-grained authorization, observability
- **Trade-off:** Network Policies = simple, Service Mesh = powerful but complex

**Container security:**
- **Image scanning:** Trivy, Harbor (detect CVEs before production)
- **Minimal images:** Alpine, distroless (reduce attack surface)
- **Pod Security Standards:** Baseline (non-root), Restricted (drop capabilities)
- **Security contexts:** runAsNonRoot, readOnlyRootFilesystem

**Supply chain:**
- **Image signing:** Cosign (verify provenance)
- **SBOM:** Software Bill of Materials (track dependencies)

**Compliance:**
- **GDPR:** Encryption, access control, audit logs, data deletion
- **SOC 2:** Least privilege, change management, monitoring
- **PCI-DSS:** Network segmentation, encryption, logging

---

**DevOps Vaatenurk:**

Security is NOT a one-time task - it's continuous:
- [ ] Scan images EVERY build (CI/CD integration)
- [ ] Rotate secrets regularly (automated)
- [ ] Review RBAC quarterly (remove unused permissions)
- [ ] Audit logs reviewed weekly (detect anomalies)
- [ ] Vulnerability patching within 7 days (CRITICAL), 30 days (HIGH)

Security trade-offs:
- **Convenience vs Security:** Locked down system = harder to use (balance needed)
- **Cost vs Security:** Enterprise tools expensive (Vault, PagerDuty) - worth it?
- **Speed vs Security:** Manual approvals slow deployment (automate with gates)

---

**Järgmised Sammud:**
**Peatükk 23:** High Availability ja Scaling
**Peatükk 24:** Backup ja Disaster Recovery

📖 **Praktika:** Labor 6, Harjutus 5 - RBAC setup, Network Policies, Image scanning
