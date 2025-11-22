# Harjutus 1: Terraform Basics & Kubernetes Provider

**Kestus:** 60 minutit
**Eesmärk:** Installi Terraform ja konfigureeri Kubernetes provider.

---

## 📋 Ülevaade

Selles harjutuses installime **Terraform** ja loome esimesed Kubernetes resources Terraform'i kaudu. Õpime Terraform põhikontseptsioone:

- **Provider:** Plugin Kubernetes API'ga suhtlemiseks
- **Resource:** Infrastructure component (namespace, deployment)
- **State:** Terraform jälgib, mis on loodud (terraform.tfstate)
- **Plan:** Preview changes enne apply'mist
- **Apply:** Create/update/delete resources

**Workflow:**
1. Write HCL code (main.tf)
2. `terraform init` (download provider)
3. `terraform plan` (preview changes)
4. `terraform apply` (create resources)
5. Check terraform.tfstate (state file)

---

## 🎯 Õpieesmärgid

✅ Install Terraform CLI
✅ Configure Kubernetes provider
✅ Create first resource (namespace)
✅ Understand plan/apply workflow
✅ Inspect Terraform state

---

## 📝 Sammud

### Samm 1: Install Terraform CLI

**Linux (Ubuntu):**

```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install
sudo apt update
sudo apt install terraform

# Verify
terraform version
```

**Expected output:**
```
Terraform v1.6.0 (or newer)
```

**Alternative: Manual install:**

```bash
# Download
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip

# Extract
unzip terraform_1.6.6_linux_amd64.zip

# Move to PATH
sudo mv terraform /usr/local/bin/

# Verify
terraform version
```

---

### Samm 2: Create Terraform Project Directory

```bash
# Create project structure
mkdir -p ~/terraform-kubernetes
cd ~/terraform-kubernetes

# Create files
touch main.tf
touch variables.tf
touch outputs.tf

# Check structure
ls -la
```

---

### Samm 3: Configure Kubernetes Provider

**Create main.tf:**

```bash
cat > main.tf << 'HCL'
# Terraform configuration
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
  }
}

# Kubernetes provider configuration
provider "kubernetes" {
  # Use current kubectl context
  config_path    = "~/.kube/config"
  config_context = "current-context"
}
HCL
```

**Verify kubectl context:**

```bash
# Check current context
kubectl config current-context

# List contexts
kubectl config get-contexts
```

---

### Samm 4: Initialize Terraform

```bash
# Initialize (downloads Kubernetes provider)
terraform init

# Expected output:
# Initializing provider plugins...
# - Finding hashicorp/kubernetes versions matching "~> 2.24.0"...
# - Installing hashicorp/kubernetes v2.24.0...
# Terraform has been successfully initialized!
```

**Check downloaded provider:**

```bash
# Provider plugins
ls -la .terraform/providers/

# Should see: registry.terraform.io/hashicorp/kubernetes/
```

---

### Samm 5: Create First Resource (Namespace)

**Add namespace to main.tf:**

```bash
cat >> main.tf << 'HCL'

# Create namespace
resource "kubernetes_namespace" "terraform_test" {
  metadata {
    name = "terraform-test"

    labels = {
      managed-by = "terraform"
      environment = "lab"
    }
  }
}
HCL
```

**Terraform HCL syntax:**
```hcl
resource "TYPE" "NAME" {
  # TYPE: kubernetes_namespace (provider resource)
  # NAME: terraform_test (local identifier)

  metadata {
    name = "terraform-test"  # Actual K8s resource name
  }
}
```

---

### Samm 6: Plan Changes (Preview)

```bash
# Plan (shows what Terraform will create)
terraform plan

# Expected output:
# Terraform will perform the following actions:
#
#   # kubernetes_namespace.terraform_test will be created
#   + resource "kubernetes_namespace" "terraform_test" {
#       + id = (known after apply)
#
#       + metadata {
#           + generation       = (known after apply)
#           + name             = "terraform-test"
#           + resource_version = (known after apply)
#           + uid              = (known after apply)
#
#           + labels = {
#               + environment = "lab"
#               + managed-by  = "terraform"
#             }
#         }
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.
```

**Understanding plan output:**
- `+` : Resource will be created
- `-` : Resource will be destroyed
- `~` : Resource will be modified
- `(known after apply)` : Value determined after creation

---

### Samm 7: Apply Changes (Create Resources)

```bash
# Apply (create resources)
terraform apply

# Terraform will prompt:
# Do you want to perform these actions?
# Enter a value: yes

# Or auto-approve:
terraform apply -auto-approve
```

**Expected output:**
```
kubernetes_namespace.terraform_test: Creating...
kubernetes_namespace.terraform_test: Creation complete after 1s [id=terraform-test]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

### Samm 8: Verify Resource Created

```bash
# Check namespace via kubectl
kubectl get namespace terraform-test

# Should show:
# NAME             STATUS   AGE
# terraform-test   Active   1m

# Check labels
kubectl get namespace terraform-test -o yaml | grep -A5 labels
```

**Compare:**
- **kubectl:** Manual resource creation
- **Terraform:** Reproducible, version-controlled

---

### Samm 9: Inspect Terraform State

Terraform tracks created resources in `terraform.tfstate`.

```bash
# View state file
cat terraform.tfstate

# JSON format showing:
# - Resource type
# - Resource name
# - Current attributes

# Pretty print (with jq)
cat terraform.tfstate | jq '.resources'
```

**State file structure:**
```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "resources": [
    {
      "type": "kubernetes_namespace",
      "name": "terraform_test",
      "provider": "provider[\"registry.terraform.io/hashicorp/kubernetes\"]",
      "instances": [
        {
          "attributes": {
            "id": "terraform-test",
            "metadata": {
              "name": "terraform-test",
              "labels": {
                "environment": "lab",
                "managed-by": "terraform"
              }
            }
          }
        }
      ]
    }
  ]
}
```

**Important:** State file contains sensitive data. Never commit to Git!

```bash
# Add to .gitignore
echo "*.tfstate" >> .gitignore
echo "*.tfstate.backup" >> .gitignore
echo ".terraform/" >> .gitignore
```

---

### Samm 10: Terraform State Commands

```bash
# List resources in state
terraform state list

# Output:
# kubernetes_namespace.terraform_test

# Show resource details
terraform state show kubernetes_namespace.terraform_test

# Output: Full resource attributes
```

---

### Samm 11: Modify Resource (Test Update)

**Update namespace label:**

```bash
# Edit main.tf
# Change labels:
cat > main.tf << 'HCL'
terraform {
  required_version = ">= 1.6.0"
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

resource "kubernetes_namespace" "terraform_test" {
  metadata {
    name = "terraform-test"

    labels = {
      managed-by  = "terraform"
      environment = "lab"
      version     = "v2"  # NEW LABEL
    }
  }
}
HCL
```

**Plan the change:**

```bash
terraform plan

# Output shows:
#   ~ resource "kubernetes_namespace" "terraform_test" {
#       ~ metadata {
#           ~ labels = {
#               + version     = "v2"
#               # (2 unchanged attributes)
#             }
#         }
#     }
#
# Plan: 0 to add, 1 to change, 0 to destroy.
```

**Apply:**

```bash
terraform apply -auto-approve

# Verify
kubectl get namespace terraform-test -o yaml | grep -A5 labels
# Should show version: v2
```

---

### Samm 12: Destroy Resources (Cleanup)

```bash
# Destroy all resources managed by Terraform
terraform destroy

# Terraform will show:
# Plan: 0 to add, 0 to change, 1 to destroy.
# Do you really want to destroy all resources?
# Enter a value: yes

# Or auto-approve:
terraform destroy -auto-approve
```

**Verify:**

```bash
# Namespace should be gone
kubectl get namespace terraform-test
# Error: namespace "terraform-test" not found
```

**State after destroy:**

```bash
cat terraform.tfstate

# Resources array is empty: "resources": []
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Terraform CLI installed (`terraform version`)
- [ ] Project directory created
- [ ] main.tf created with provider config
- [ ] `terraform init` successful
- [ ] Namespace resource defined
- [ ] `terraform plan` shows 1 resource to create
- [ ] `terraform apply` created namespace
- [ ] Namespace verified in Kubernetes
- [ ] terraform.tfstate exists and inspected
- [ ] Resource modified and applied
- [ ] `terraform destroy` removed namespace

### Verifitseerimine

```bash
# 1. Terraform version
terraform version

# 2. Provider downloaded
ls .terraform/providers/

# 3. Recreate namespace
terraform apply -auto-approve

# 4. Verify
kubectl get namespace terraform-test

# 5. State
terraform state list
```

---

## 🔍 Troubleshooting

### Probleem: "Error acquiring the state lock"

**Lahendus:**
```bash
# Force unlock (if previous run crashed)
terraform force-unlock <LOCK_ID>
```

### Probleem: "Error: Kubernetes cluster unreachable"

**Lahendus:**
```bash
# Check kubectl context
kubectl cluster-info

# Fix provider config in main.tf
provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

---

## 📚 Mida Sa Õppisid?

✅ Terraform installation
✅ HCL syntax basics
✅ Kubernetes provider
✅ Resource definition
✅ Plan/apply workflow
✅ State management
✅ Resource lifecycle (create, update, destroy)

---

## 🚀 Järgmised Sammud

**Exercise 2: Provision Kubernetes Resources** - Create full application:
- Deployment
- Service
- ConfigMap
- Variables
- Outputs

```bash
cat exercises/02-kubernetes-resources.md
```

---

**Kestus:** 60 minutit
**Järgmine:** Exercise 2 - Kubernetes Resources
