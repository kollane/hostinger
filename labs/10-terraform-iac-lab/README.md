# Lab 10: Infrastructure as Code with Terraform

**Kestus:** 5 tundi (5 × 60 min exercises)
**Eeldus:** Lab 1-9 completed
**Eesmärk:** Implementeeri Infrastructure as Code (IaC) Terraform'iga Kubernetes resources jaoks.

---

## 📋 Ülevaade

See lab õpetab **Infrastructure as Code (IaC)** - modern DevOps practice, kus infrastructure on defineeritud code'ina (not manual clicks). Kasutame **Terraform** - industry-standard IaC tool.

**Miks IaC?**
- ✅ **Version control** - Infrastructure muutused Git'is (audit trail)
- ✅ **Reproducible** - Sama infrastructure igal pool (dev, staging, prod)
- ✅ **Automation** - No manual errors, CI/CD integration
- ✅ **Documentation** - Code on documentation (self-documenting)
- ✅ **Collaboration** - Teams can review infrastructure changes (PR workflow)
- ✅ **Disaster recovery** - Recreate infrastructure from code

**Terraform vs kubectl:**

```bash
# Traditional: Manual kubectl apply (not reproducible, no version control)
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
# What if you forget? What if someone else needs to do this?

# IaC: Terraform (version controlled, reproducible, automated)
terraform apply
# Everything defined in code, trackable, repeatable
```

**Terraform Benefits:**
- Declarative syntax (HCL - HashiCorp Configuration Language)
- Multi-cloud (AWS, GCP, Azure, Kubernetes)
- State management (knows what exists)
- Plan before apply (preview changes)
- Modules (reusable components)

**Lab 10 integrates with:**
- **Lab 3-4:** Provision Kubernetes resources (Deployments, Services, Namespaces)
- **Lab 7:** Manage RBAC, Network Policies via Terraform
- **Lab 8:** ArgoCD Applications provisioned by Terraform
- **Lab 9:** Backup Terraform state

---

## 🎯 Õpieesmärgid

Peale selle lab'i läbimist oskad:

✅ Installida ja konfigureerida Terraform
✅ Kasutada Kubernetes provider
✅ Provision'ida Kubernetes resources (Namespaces, Deployments, Services)
✅ Manage'ida Terraform state (local, remote)
✅ Luua Terraform modules (DRY principle)
✅ Integrate'ida Terraform CI/CD workflow'ga (Lab 5)
✅ GitOps for infrastructure (Terraform + ArgoCD)
✅ Version control infrastructure changes

---

## 🏗️ Terraform Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                  Terraform Workflow                            │
│                                                                │
│  1. Write Configuration                                        │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  main.tf (HCL code)                                  │     │
│  │                                                       │     │
│  │  resource "kubernetes_namespace" "production" {      │     │
│  │    metadata {                                        │     │
│  │      name = "production"                             │     │
│  │    }                                                 │     │
│  │  }                                                   │     │
│  │                                                       │     │
│  │  resource "kubernetes_deployment" "user_service" {   │     │
│  │    metadata { ... }                                  │     │
│  │    spec { ... }                                      │     │
│  │  }                                                   │     │
│  └──────────────────────────────────────────────────────┘     │
│                       │                                         │
│                       │ terraform init                          │
│                       ▼                                         │
│  2. Initialize (download providers)                             │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  .terraform/                                         │     │
│  │  ├── providers/                                      │     │
│  │  │   └── kubernetes_provider_plugin                 │     │
│  │  └── terraform.tfstate.lock                          │     │
│  └──────────────────────────────────────────────────────┘     │
│                       │                                         │
│                       │ terraform plan                          │
│                       ▼                                         │
│  3. Plan (preview changes)                                      │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  Terraform will perform the following actions:       │     │
│  │                                                       │     │
│  │  + kubernetes_namespace.production                   │     │
│  │    + metadata.name = "production"                    │     │
│  │                                                       │     │
│  │  + kubernetes_deployment.user_service                │     │
│  │    + metadata.name = "user-service"                  │     │
│  │    + spec.replicas = 3                               │     │
│  │                                                       │     │
│  │  Plan: 2 to add, 0 to change, 0 to destroy.          │     │
│  └──────────────────────────────────────────────────────┘     │
│                       │                                         │
│                       │ terraform apply                         │
│                       ▼                                         │
│  4. Apply (create resources)                                    │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  kubernetes_namespace.production: Creating...        │     │
│  │  kubernetes_namespace.production: Created            │     │
│  │  kubernetes_deployment.user_service: Creating...     │     │
│  │  kubernetes_deployment.user_service: Created         │     │
│  └──────────────────────────────────────────────────────┘     │
│                       │                                         │
│                       │ update terraform.tfstate                │
│                       ▼                                         │
│  5. State (track what exists)                                   │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  terraform.tfstate (JSON)                            │     │
│  │  {                                                    │     │
│  │    "resources": [                                    │     │
│  │      {                                               │     │
│  │        "type": "kubernetes_namespace",               │     │
│  │        "name": "production",                         │     │
│  │        "instances": [...]                            │     │
│  │      },                                              │     │
│  │      {                                               │     │
│  │        "type": "kubernetes_deployment",              │     │
│  │        "name": "user_service",                       │     │
│  │        "instances": [...]                            │     │
│  │      }                                               │     │
│  │    ]                                                 │     │
│  │  }                                                   │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**Terraform Core Concepts:**
- **Provider:** Plugin to interact with API (kubernetes, aws, google, etc.)
- **Resource:** Infrastructure component (namespace, deployment, service)
- **State:** Current state of infrastructure (terraform.tfstate)
- **Plan:** Preview of changes before applying
- **Module:** Reusable infrastructure component

---

## 📊 Terraform vs Other IaC Tools

| Feature | Terraform | Helm | Ansible | CloudFormation |
|---------|-----------|------|---------|----------------|
| **Language** | HCL | Go templates | YAML | JSON/YAML |
| **Multi-cloud** | ✅ Yes | ❌ K8s only | ✅ Yes | ❌ AWS only |
| **State management** | ✅ Built-in | ❌ No | ❌ No | ✅ AWS managed |
| **Plan/Preview** | ✅ Yes | ❌ No | ❌ No | ✅ Change sets |
| **Modules** | ✅ Yes | ✅ Charts | ✅ Roles | ✅ Nested stacks |
| **K8s support** | ✅ Provider | ✅ Native | ✅ Modules | ❌ No |

**When to use Terraform:**
- Multi-cloud infrastructure
- Infrastructure + application resources together
- Need state management
- Complex dependencies

**When to use Helm:**
- Kubernetes-only
- Package management (charts)
- Application deployment (not infrastructure)

**Best practice:** Terraform for infrastructure, Helm/ArgoCD for applications.

---

## 🔗 Integration with Previous Labs

### Lab 3-4: Kubernetes Resources

Terraform can create all Kubernetes resources:
- Namespaces
- Deployments
- Services
- ConfigMaps
- Secrets
- PersistentVolumeClaims
- StatefulSets
- Ingress

```hcl
# Instead of kubectl apply -f namespace.yaml
resource "kubernetes_namespace" "production" {
  metadata {
    name = "production"
  }
}
```

---

### Lab 5: CI/CD Integration

Terraform in CI/CD pipeline:

```yaml
# .github/workflows/terraform.yaml
- name: Terraform Plan
  run: terraform plan

- name: Terraform Apply
  run: terraform apply -auto-approve
```

---

### Lab 7: RBAC & Security

Terraform manages RBAC:

```hcl
resource "kubernetes_role" "developer" {
  metadata {
    name = "developer"
    namespace = "production"
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list"]
  }
}
```

---

### Lab 8: ArgoCD Applications

Terraform provisions ArgoCD Applications:

```hcl
resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "user-service"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL = "https://github.com/..."
        path    = "k8s/"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "production"
      }
    }
  }
}
```

---

### Lab 9: Backup Terraform State

Terraform state should be backed up:

```bash
# Backup state to S3 (same as Velero backups)
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "kubernetes/terraform.tfstate"
    region = "us-east-1"
  }
}
```

---

## 📝 Lab Exercises

### Exercise 1: Terraform Basics & Kubernetes Provider (60 min)

**Õpieesmärgid:**
- Install Terraform
- Configure Kubernetes provider
- Create first resources (namespace)
- Understand plan/apply workflow
- Inspect Terraform state

**Steps:**
1. Install Terraform CLI
2. Configure kubectl context
3. Create main.tf (Kubernetes provider)
4. Create namespace resource
5. terraform init, plan, apply
6. Inspect terraform.tfstate

**Output:** Working Terraform setup with test namespace.

---

### Exercise 2: Provision Kubernetes Resources (60 min)

**Õpieesmärgid:**
- Create Deployment via Terraform
- Create Service via Terraform
- Create ConfigMap and Secret
- Use variables (environment-specific)
- Output values (IP addresses)

**Steps:**
1. Create user-service Deployment
2. Create Service (ClusterIP)
3. Create ConfigMap (app config)
4. Use variables for replicas, image tag
5. Output service endpoint
6. Test application

**Output:** Full application stack provisioned by Terraform.

---

### Exercise 3: Terraform Modules & DRY (60 min)

**Õpieesmärgid:**
- Create reusable modules
- Module inputs (variables)
- Module outputs
- Use modules for multiple environments
- Share modules (registry)

**Steps:**
1. Create "kubernetes-app" module
2. Define module inputs (name, replicas, image)
3. Use module for dev, staging, prod
4. Module composition (nested modules)
5. Publish module to registry (optional)

**Output:** Reusable infrastructure modules.

---

### Exercise 4: Terraform State Management (60 min)

**Õpieesmärgid:**
- Understand local state
- Configure remote state (S3, Terraform Cloud)
- State locking (prevent concurrent changes)
- State import (existing resources)
- State manipulation (move, remove)

**Steps:**
1. Inspect local terraform.tfstate
2. Configure S3 backend (MinIO from Lab 9)
3. Migrate state to remote
4. Import existing Kubernetes resource
5. Use terraform state commands

**Output:** Production-ready state management.

---

### Exercise 5: GitOps for Infrastructure (60 min)

**Õpieesmärgid:**
- Version control Terraform code
- PR workflow for infrastructure changes
- CI/CD for Terraform (automated plan)
- ArgoCD + Terraform integration
- Atlantis (Terraform automation)

**Steps:**
1. Commit Terraform code to Git
2. Create PR workflow (terraform plan in CI)
3. Automated apply on merge
4. ArgoCD Application for Terraform-managed resources
5. Optional: Atlantis setup

**Output:** Full GitOps workflow for infrastructure.

---

## 🛠️ Prerequisites

### Required:

- ✅ **Kubernetes cluster** (Lab 1-9)
- ✅ **kubectl** configured
- ✅ **Git** for version control

### Tools to Install:

- **Terraform CLI** (v1.6+)
- **terraform-docs** (optional, for documentation)

### Knowledge from previous labs:

- Kubernetes resources (Lab 3-4)
- CI/CD workflows (Lab 5)
- RBAC (Lab 7)
- ArgoCD (Lab 8)

---

## 🔒 Security Best Practices

### 1. Never Commit Secrets

```hcl
# BAD: Hardcoded secret
resource "kubernetes_secret" "db_password" {
  data = {
    password = "SuperSecret123"  # DON'T DO THIS!
  }
}

# GOOD: Use Terraform variables + environment variables
variable "db_password" {
  type      = string
  sensitive = true
}

resource "kubernetes_secret" "db_password" {
  data = {
    password = var.db_password
  }
}
```

```bash
# Pass via environment variable
export TF_VAR_db_password="SuperSecret123"
terraform apply
```

---

### 2. Secure State Files

State files contain sensitive data (secrets in plaintext).

```hcl
# Remote state with encryption
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true  # S3 server-side encryption
    dynamodb_table = "terraform-locks"  # State locking
  }
}
```

**Never commit terraform.tfstate to Git!**

```bash
# .gitignore
*.tfstate
*.tfstate.backup
.terraform/
```

---

### 3. Use Sealed Secrets (Lab 7)

Instead of Terraform managing secrets, use Sealed Secrets:

```hcl
# Terraform creates SealedSecret (encrypted)
resource "kubernetes_manifest" "sealed_secret" {
  manifest = yamldecode(file("sealed-secret.yaml"))
}
```

---

## 📈 Monitoring Terraform

### Terraform Cloud (SaaS)

- State management
- Run history
- Cost estimation
- Policy as code (Sentinel)

### Atlantis (Self-hosted)

- Terraform automation for GitHub PRs
- Plan on PR creation
- Apply on PR merge
- Locking (prevent concurrent changes)

---

## 💡 Best Practices

### ✅ 1. Use Modules

Don't repeat yourself (DRY).

```hcl
# Without modules (repetitive)
resource "kubernetes_deployment" "app1" { ... }
resource "kubernetes_deployment" "app2" { ... }
resource "kubernetes_deployment" "app3" { ... }

# With modules (reusable)
module "app1" {
  source = "./modules/k8s-app"
  name   = "app1"
}
module "app2" {
  source = "./modules/k8s-app"
  name   = "app2"
}
```

---

### ✅ 2. Version Control

Commit Terraform code to Git:

```bash
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars  # Gitignored if contains secrets
└── modules/
    └── k8s-app/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

### ✅ 3. Plan Before Apply

Always review changes:

```bash
# Plan
terraform plan -out=plan.tfplan

# Review plan
cat plan.tfplan

# Apply reviewed plan
terraform apply plan.tfplan
```

---

### ✅ 4. Remote State

Use remote state for teams:

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "prod/terraform.tfstate"
  }
}
```

---

### ✅ 5. Workspace for Environments

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select prod

# Each workspace has separate state
```

---

## 🎯 Learning Outcomes

Peale selle lab'i:

✅ **Oskad seadistada** Terraform for Kubernetes
✅ **Oskad provision'ida** Kubernetes resources via code
✅ **Oskad luua** reusable Terraform modules
✅ **Oskad manage'ida** Terraform state (local + remote)
✅ **Oskad integreerida** Terraform CI/CD workflow'ga
✅ **Mõistad** GitOps for infrastructure

---

## 🚀 Next Steps

**After Lab 10:**
- 🎉 **Course Complete!** All 10 labs finished
- Deploy full-stack application (Labs 1-10 combined)
- Production deployment checklist
- Continue learning: multi-cloud, service mesh, more!

---

**Lab 10 Status:** Ready to start! 🚀⚙️

**Estimated Time:** 5 hours
**Difficulty:** Advanced (builds on Lab 1-9)

**Begin with:** `cat exercises/01-terraform-basics.md`

---

## 📚 Resources

**Terraform Documentation:**
- https://developer.hashicorp.com/terraform
- https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs

**Community:**
- Terraform Discuss: discuss.hashicorp.com
- GitHub: github.com/hashicorp/terraform

**Best Practices:**
- Terraform Best Practices: terraform-best-practices.com
- Google Cloud Terraform Guide: cloud.google.com/docs/terraform

---

**This is the FINAL lab - after this, full DevOps course complete! 🎓🚀**
