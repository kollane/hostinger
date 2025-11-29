# Harjutus 5: GitOps for Infrastructure (Terraform + ArgoCD)

**Kestus:** 60 minutit
**Eesmärk:** Automate Terraform via CI/CD ja integrate ArgoCD.

---

## 📋 Ülevaade

GitOps for infrastructure: Infrastructure as Code + Git + CI/CD.

---

## 🎯 Õpieesmärgid

- ✅ Version control Terraform code
- ✅ PR workflow for infra changes
- ✅ CI/CD automation (plan on PR)
- ✅ ArgoCD + Terraform integration
- ✅ Automated apply on merge

---

## 📝 Sammud

### Samm 1: Version Control Setup

```bash
cd ~/terraform-k8s-app

# Initialize Git
git init

# Create .gitignore
cat > .gitignore << 'GITIGNORE'
# Terraform
*.tfstate
*.tfstate.backup
.terraform/
*.tfplan

# Secrets
*.tfvars
.env

# OS
.DS_Store
GITIGNORE

# Commit
git add .
git commit -m "Initial Terraform configuration"
```

---

### Samm 2: GitHub Actions Workflow (CI)

```bash
mkdir -p .github/workflows

cat > .github/workflows/terraform.yaml << 'YAML'
name: Terraform CI/CD

on:
  pull_request:
    paths:
      - '**.tf'
  push:
    branches:
      - main

jobs:
  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'

    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -no-color
        env:
          KUBE_CONFIG_DATA: ${{ secrets.KUBE_CONFIG }}

      - name: Comment Plan on PR
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Terraform plan output:\n```\n' + process.env.PLAN_OUTPUT + '\n```'
            })

  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -auto-approve
        env:
          KUBE_CONFIG_DATA: ${{ secrets.KUBE_CONFIG }}
YAML
```

---

### Samm 3: Create Pull Request Workflow

```bash
# Create feature branch
git checkout -b add-new-app

# Add new resource
cat >> main.tf << 'HCL'
module "app3" {
  source = "./k8s-app"

  namespace = kubernetes_namespace.apps.metadata[0].name
  app_name  = "api"
  image     = "nginx:latest"
  replicas  = 2
}
HCL

# Commit
git add main.tf
git commit -m "Add API application"

# Push
git push origin add-new-app

# Open PR in GitHub
# CI runs terraform plan
# Review plan in PR comments
# Merge PR → terraform apply runs
```

---

### Samm 4: ArgoCD + Terraform Integration

**Scenario:** Terraform creates namespaces, ArgoCD deploys applications.

```bash
cat > argocd-app.tf << 'HCL'
# Terraform creates ArgoCD Application
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
        repoURL        = "https://github.com/YOUR_USERNAME/hostinger.git"
        targetRevision = "HEAD"
        path           = "k8s/user-service/overlays/production"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.apps.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}
HCL

terraform apply -auto-approve

# Terraform created ArgoCD Application
# ArgoCD syncs from Git
# Terraform manages infra, ArgoCD manages apps
```

---

### Samm 5: Atlantis (Optional - Advanced)

**Atlantis:** Terraform automation for GitHub PRs.

```yaml
# atlantis.yaml
version: 3
projects:
  - name: kubernetes
    dir: .
    workspace: default
    terraform_version: v1.6.0
    autoplan:
      when_modified: ["**.tf"]
      enabled: true
```

**Atlantis workflow:**
1. Open PR
2. Atlantis comments with `terraform plan`
3. Comment `atlantis apply` to apply
4. Merge PR

---

## ✅ Kontrolli Oma Edusamme

- [ ] Terraform code in Git
- [ ] .gitignore configured
- [ ] GitHub Actions workflow created
- [ ] PR workflow tested (plan on PR)
- [ ] Automated apply on merge
- [ ] ArgoCD Application created by Terraform

---

## 📚 Mida Sa Õppisid?

✅ GitOps for infrastructure
✅ CI/CD for Terraform
✅ PR-based workflow
✅ Terraform + ArgoCD integration
✅ Automated plan/apply

---

## 🎉 Lab 10 Complete!

**Õnnitleme! Sa läbisid Lab 10: Infrastructure as Code! 🎓**

**KURSUS 100% VALMIS! 🚀🎉**

All 10 labs complete:
- Module 1: Docker, Compose, K8s Basics ✅
- Module 2: K8s Advanced, CI/CD, Monitoring ✅
- Module 3: Security, GitOps, Backup ✅
- Module 4: Infrastructure as Code ✅

**Next:** Deploy full production application using all labs!

---

**Kestus:** 60 minutit
**Status:** ✅ COURSE COMPLETE!
