# Harjutus 2: Provision Kubernetes Resources

**Kestus:** 60 minutit
**Eesmärk:** Loo täielik application stack Terraform'iga (Deployment, Service, ConfigMap).

---

## 📋 Ülevaade

Selles harjutuses provision'ime **user-service** application Terraform'i kaudu. Loome kõik vajalikud Kubernetes resources:

- Namespace
- Deployment (user-service)
- Service (ClusterIP)
- ConfigMap (application config)
- Variables (environment-specific)
- Outputs (endpoint info)

---

## 🎯 Õpieesmärgid

✅ Create Deployment resource
✅ Create Service resource
✅ Create ConfigMap
✅ Use Terraform variables
✅ Use Terraform outputs
✅ Test application

---

## 📝 Sammud

### Samm 1: Project Setup

```bash
mkdir -p ~/terraform-k8s-app
cd ~/terraform-k8s-app

touch main.tf
touch variables.tf
touch outputs.tf
touch terraform.tfvars
```

---

### Samm 2: Define Variables

```bash
cat > variables.tf << 'HCL'
variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "terraform-app"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "user-service"
}

variable "app_image" {
  description = "Docker image"
  type        = string
  default     = "nginx:latest"  # Replace with your image
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3000
}
HCL
```

---

### Samm 3: Create Provider Config

```bash
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
HCL
```

---

### Samm 4: Create Namespace

```bash
cat >> main.tf << 'HCL'

# Namespace
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace

    labels = {
      managed-by = "terraform"
      app        = var.app_name
    }
  }
}
HCL
```

---

### Samm 5: Create ConfigMap

```bash
cat >> main.tf << 'HCL'

# ConfigMap
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    NODE_ENV    = "production"
    LOG_LEVEL   = "info"
    APP_VERSION = "1.0.0"
  }
}
HCL
```

---

### Samm 6: Create Deployment

```bash
cat >> main.tf << 'HCL'

# Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      app = var.app_name
    }
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
          image = var.app_image

          port {
            container_port = var.app_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}
HCL
```

---

### Samm 7: Create Service

```bash
cat >> main.tf << 'HCL'

# Service
resource "kubernetes_service" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = var.app_port
      target_port = var.app_port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
HCL
```

---

### Samm 8: Create Outputs

```bash
cat > outputs.tf << 'HCL'
output "namespace" {
  description = "Application namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "service_name" {
  description = "Service name"
  value       = kubernetes_service.app.metadata[0].name
}

output "service_cluster_ip" {
  description = "Service ClusterIP"
  value       = kubernetes_service.app.spec[0].cluster_ip
}

output "deployment_name" {
  description = "Deployment name"
  value       = kubernetes_deployment.app.metadata[0].name
}
HCL
```

---

### Samm 9: Initialize and Apply

```bash
# Initialize
terraform init

# Plan
terraform plan

# Should show:
# Plan: 4 to add (namespace, configmap, deployment, service)

# Apply
terraform apply -auto-approve

# Outputs:
# namespace = "terraform-app"
# service_name = "user-service"
# service_cluster_ip = "10.96.x.x"
# deployment_name = "user-service"
```

---

### Samm 10: Verify Resources

```bash
# Check namespace
kubectl get namespace terraform-app

# Check all resources
kubectl get all -n terraform-app

# Check ConfigMap
kubectl get configmap -n terraform-app user-service-config -o yaml

# Check pods
kubectl get pods -n terraform-app

# Wait for ready
kubectl wait --for=condition=Ready pod -l app=user-service -n terraform-app --timeout=2m
```

---

### Samm 11: Test Application (if using nginx)

```bash
# Port-forward
kubectl port-forward -n terraform-app svc/user-service 8080:3000 &

# Test
curl http://localhost:8080

# Should return nginx default page (or your app response)
```

---

### Samm 12: Update Variables (Environment Override)

```bash
# Create terraform.tfvars (environment-specific)
cat > terraform.tfvars << 'TFVARS'
namespace = "terraform-prod"
app_name  = "user-service"
replicas  = 5
TFVARS

# Apply with new values
terraform apply -auto-approve

# Terraform will:
# - Destroy old namespace (terraform-app)
# - Create new namespace (terraform-prod)
# - Update replicas to 5
```

---

## ✅ Kontrolli Oma Edusamme

- [ ] Variables defined
- [ ] Provider configured
- [ ] Namespace created
- [ ] ConfigMap created
- [ ] Deployment created (2 replicas)
- [ ] Service created
- [ ] Outputs displayed
- [ ] Resources verified in Kubernetes
- [ ] Application tested

---

## 📚 Mida Sa Õppisid?

✅ Terraform variables
✅ Kubernetes Deployment resource
✅ Kubernetes Service resource
✅ ConfigMap integration
✅ Resource dependencies (namespace → deployment)
✅ Terraform outputs

---

**Järgmine:** Exercise 3 - Terraform Modules
