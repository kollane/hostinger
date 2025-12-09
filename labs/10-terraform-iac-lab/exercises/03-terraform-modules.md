# Harjutus 3: Terraform Modules & DRY

**Kestus:** 60 minutit
**Eesmärk:** Loo reusable Terraform modules.

---

## 📋 Ülevaade

Modules võimaldavad korduvkasutada Terraform koodi (DRY - Don't Repeat Yourself).

---

## 🎯 Õpieesmärgid

- ✅ Create reusable module
- ✅ Module inputs (variables)
- ✅ Module outputs
- ✅ Use module multiple times
- ✅ Nested modules

---

## 📝 Sammud

### Samm 1: Create Module Structure

```bash
mkdir -p ~/terraform-modules/k8s-app
cd ~/terraform-modules

# Module structure
k8s-app/
├── main.tf
├── variables.tf
└── outputs.tf
```

---

### Samm 2: Create Module (k8s-app)

```bash
cat > k8s-app/variables.tf << 'HCL'
variable "namespace" {
  type = string
}

variable "app_name" {
  type = string
}

variable "image" {
  type = string
}

variable "replicas" {
  type    = number
  default = 2
}

variable "port" {
  type    = number
  default = 3000
}
HCL

cat > k8s-app/main.tf << 'HCL'
resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.image

          port {
            container_port = var.port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = var.port
      target_port = var.port
    }

    type = "ClusterIP"
  }
}
HCL

cat > k8s-app/outputs.tf << 'HCL'
output "deployment_name" {
  value = kubernetes_deployment.app.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.app.metadata[0].name
}
HCL
```

---

### Samm 3: Use Module (Root Configuration)

```bash
cat > main.tf << 'HCL'
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

# Create namespace
resource "kubernetes_namespace" "apps" {
  metadata {
    name = "terraform-modules"
  }
}

# Use module for app1
module "app1" {
  source = "./k8s-app"

  namespace = kubernetes_namespace.apps.metadata[0].name
  app_name  = "frontend"
  image     = "nginx:latest"
  replicas  = 2
  port      = 80
}

# Use module for app2
module "app2" {
  source = "./k8s-app"

  namespace = kubernetes_namespace.apps.metadata[0].name
  app_name  = "backend"
  image     = "nginx:latest"
  replicas  = 3
  port      = 3000
}
HCL
```

---

### Samm 4: Apply Module

```bash
terraform init
terraform apply -auto-approve

# Verify
kubectl get all -n terraform-modules

# Should see:
# - frontend deployment (2 replicas)
# - backend deployment (3 replicas)
# - 2 services
```

---

### Samm 5: Module Outputs

```bash
cat > outputs.tf << 'HCL'
output "frontend_service" {
  value = module.app1.service_name
}

output "backend_service" {
  value = module.app2.service_name
}
HCL

terraform apply -auto-approve

# Outputs:
# frontend_service = "frontend"
# backend_service = "backend"
```

---

## ✅ Kontrolli Oma Edusamme

- [ ] Module created
- [ ] Module used multiple times
- [ ] Different inputs per module
- [ ] Outputs from modules

---

## 📚 Mida Sa Õppisid?

✅ Terraform modules
✅ Module reusability
✅ DRY principle
✅ Module composition

---

**Järgmine:** Exercise 4 - State Management
