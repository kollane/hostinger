# Harjutus 4: Terraform State Management

**Kestus:** 60 minutit
**Eesmärk:** Configure remote state ja state locking.

---

## 📋 Ülevaade

Terraform state management on production-critical. State file tracks infrastructure.

---

## 🎯 Õpieesmärgid

- ✅ Understand local state
- ✅ Configure remote state (S3/MinIO)
- ✅ State locking
- ✅ Import existing resources
- ✅ State manipulation

---

## 📝 Sammud

### Samm 1: Inspect Local State

```bash
# View state
cat terraform.tfstate

# List resources
terraform state list

# Show resource
terraform state show kubernetes_namespace.apps
```

---

### Samm 2: Configure Remote State (MinIO from Lab 9)

```bash
cat > backend.tf << 'HCL'
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "kubernetes/terraform.tfstate"
    region = "us-east-1"

    endpoint                    = "http://minio.minio.svc:9000"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true

    access_key = "minio"
    secret_key = "minio123"
  }
}
HCL
```

---

### Samm 3: Create S3 Bucket (MinIO)

```bash
# Exec into MinIO pod
kubectl exec -n minio deployment/minio -- sh -c '
  mc alias set local http://localhost:9000 minio minio123
  mc mb local/terraform-state
  mc ls local
'
```

---

### Samm 4: Migrate State to Remote

```bash
# Initialize backend
terraform init -migrate-state

# Confirm migration
# State is now in MinIO (S3)
```

---

### Samm 5: Verify Remote State

```bash
# Check MinIO bucket
kubectl exec -n minio deployment/minio -- sh -c '
  mc ls local/terraform-state/kubernetes/
'

# Should see: terraform.tfstate
```

---

### Samm 6: Import Existing Resource

```bash
# Create namespace manually
kubectl create namespace manual-namespace

# Import into Terraform state
terraform import kubernetes_namespace.manual kubernetes_namespace/manual-namespace

# Add to Terraform code
cat >> main.tf << 'HCL'
resource "kubernetes_namespace" "manual" {
  metadata {
    name = "manual-namespace"
  }
}
HCL

# Now managed by Terraform
terraform plan  # Should show no changes
```

---

### Samm 7: State Commands

```bash
# List all resources
terraform state list

# Move resource (rename)
terraform state mv kubernetes_namespace.manual kubernetes_namespace.imported

# Remove from state (don't delete resource)
terraform state rm kubernetes_namespace.imported

# Pull state
terraform state pull > state.json
cat state.json | jq '.resources'
```

---

## ✅ Kontrolli Oma Edusamme

- [ ] Local state inspected
- [ ] Remote backend configured (MinIO)
- [ ] State migrated to remote
- [ ] Existing resource imported
- [ ] State commands used

---

## 📚 Mida Sa Õppisid?

✅ Local vs remote state
✅ S3 backend configuration
✅ State migration
✅ Resource import
✅ State manipulation

---

**Järgmine:** Exercise 5 - GitOps for Infrastructure
