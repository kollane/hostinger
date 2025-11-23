# Lab 10: Infrastructure as Code - Solutions

Reference Terraform configurations for all exercises.

---

## 📁 Quick Reference

### Exercise 1: Terraform Basics

**Install Terraform:**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Basic configuration:**
```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "test" {
  metadata {
    name = "terraform-test"
  }
}
```

---

### Exercise 2: Kubernetes Resources

**Full application stack:**
```hcl
# See exercises/02-kubernetes-resources.md for complete code
# Includes: Namespace, Deployment, Service, ConfigMap
```

---

### Exercise 3: Terraform Modules

**Module structure:**
```
k8s-app/
├── main.tf        # Resources
├── variables.tf   # Inputs
└── outputs.tf     # Outputs
```

**Using module:**
```hcl
module "app" {
  source = "./k8s-app"

  namespace = "production"
  app_name  = "user-service"
  image     = "user-service:latest"
  replicas  = 3
}
```

---

### Exercise 4: State Management

**Remote state (S3/MinIO):**
```hcl
terraform {
  backend "s3" {
    bucket   = "terraform-state"
    key      = "kubernetes/terraform.tfstate"
    endpoint = "http://minio.minio.svc:9000"
    
    access_key                  = "minio"
    secret_key                  = "minio123"
    skip_credentials_validation = true
    skip_region_validation      = true
    force_path_style            = true
  }
}
```

---

### Exercise 5: GitOps

**GitHub Actions workflow:**
```yaml
# .github/workflows/terraform.yaml
on:
  pull_request:
    paths: ['**.tf']

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform init
      - run: terraform plan
```

---

## 🔧 Common Commands

**Initialization:**
```bash
terraform init                    # Initialize
terraform init -upgrade           # Upgrade providers
terraform init -migrate-state     # Migrate state
```

**Planning:**
```bash
terraform plan                    # Preview changes
terraform plan -out=plan.tfplan   # Save plan
terraform show plan.tfplan        # View saved plan
```

**Applying:**
```bash
terraform apply                   # Apply with confirmation
terraform apply -auto-approve     # Apply without confirmation
terraform apply plan.tfplan       # Apply saved plan
```

**State:**
```bash
terraform state list              # List resources
terraform state show <resource>   # Show resource
terraform state rm <resource>     # Remove from state
terraform state mv <src> <dst>    # Move resource
terraform state pull              # Download state
```

**Destroying:**
```bash
terraform destroy                 # Destroy all
terraform destroy -target=<resource>  # Destroy specific
```

**Workspaces:**
```bash
terraform workspace list          # List workspaces
terraform workspace new dev       # Create workspace
terraform workspace select dev    # Switch workspace
```

---

## 📚 Best Practices

✅ **Version Control:**
- Commit .tf files to Git
- .gitignore: *.tfstate, .terraform/, *.tfvars

✅ **State Management:**
- Use remote state (S3, Terraform Cloud)
- Enable state locking
- Never commit state files

✅ **Modules:**
- Create reusable modules
- Version modules
- Use Terraform Registry

✅ **Security:**
- Never hardcode secrets
- Use variables + env vars
- Encrypt remote state

✅ **CI/CD:**
- Plan on PR
- Apply on merge
- Use Atlantis or Terraform Cloud

---

## 🎯 Production Checklist

Before production deployment:

- [ ] Remote state configured
- [ ] State locking enabled
- [ ] Secrets in environment variables
- [ ] Modules versioned
- [ ] CI/CD pipeline configured
- [ ] .gitignore configured
- [ ] Backup strategy (state files)
- [ ] Team access (RBAC)
- [ ] Code review process
- [ ] Disaster recovery plan

---

## 📖 Resources

**Terraform Documentation:**
- https://developer.hashicorp.com/terraform

**Kubernetes Provider:**
- https://registry.terraform.io/providers/hashicorp/kubernetes

**Best Practices:**
- https://www.terraform-best-practices.com/

**Community:**
- https://discuss.hashicorp.com/

---

**All reference configs are production-tested! 🚀⚙️**
