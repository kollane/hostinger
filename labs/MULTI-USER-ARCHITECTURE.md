# 🏗️ Multi-User Architecture

Visuaalne ülevaade multi-user setup'ist.

---

## 🌍 Ülevaade (High-Level)

```
VPS: kirjakast (Ubuntu 24.04, 7.8GB RAM, 2 CPU)
├── User: janek
│   ├── Docker: janek-* containers (ports 5433, 3001, 8081)
│   └── K8s: janek-k8s-lab cluster (API: 6444)
│
├── User: maria
│   ├── Docker: maria-* containers (ports 5434, 3002, 8082)
│   └── K8s: maria-k8s-lab cluster (API: 6445)
│
└── User: kalle
    ├── Docker: kalle-* containers (ports 5435, 3003, 8083)
    └── K8s: kalle-k8s-lab cluster (API: 6446)
```

---

## 🐳 Docker Architecture (Lab 1-2)

### Single Docker Daemon, Isolated Resources

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Daemon (Shared)                        │
│                                                                   │
│  ┌────────────────────┐  ┌────────────────────┐  ┌─────────────┐│
│  │  User: janek       │  │  User: maria       │  │  User: kalle││
│  │  UID: 1001         │  │  UID: 1002         │  │  UID: 1003  ││
│  │                    │  │                    │  │             ││
│  │  Containers:       │  │  Containers:       │  │  Containers:││
│  │  janek-postgres    │  │  maria-postgres    │  │  kalle-...  ││
│  │  janek-backend     │  │  maria-backend     │  │             ││
│  │  janek-frontend    │  │  maria-frontend    │  │             ││
│  │                    │  │                    │  │             ││
│  │  Network:          │  │  Network:          │  │  Network:   ││
│  │  janek_default     │  │  maria_default     │  │  kalle_...  ││
│  │                    │  │                    │  │             ││
│  │  Volumes:          │  │  Volumes:          │  │  Volumes:   ││
│  │  janek_pg-data     │  │  maria_pg-data     │  │  kalle_...  ││
│  └────────────────────┘  └────────────────────┘  └─────────────┘│
│                                                                   │
│  Ports:                  Ports:                  Ports:          │
│  5433, 3001, 8081        5434, 3002, 8082        5435, 3003, ... │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
                         Host: kirjakast
                         Ports: 5433-5435 (PostgreSQL)
                                3001-3003 (Backend)
                                8081-8083 (Frontend)
```

### Port Allocation Strategy

```
Base Ports:
├── PostgreSQL: 5432
├── Backend:    3000
└── Frontend:   8080

User-Specific Ports = Base Port + (UID % 1000)

Example:
├── janek (UID 1001):
│   ├── PostgreSQL: 5432 + 1 = 5433
│   ├── Backend:    3000 + 1 = 3001
│   └── Frontend:   8080 + 1 = 8081
│
├── maria (UID 1002):
│   ├── PostgreSQL: 5432 + 2 = 5434
│   ├── Backend:    3000 + 2 = 3002
│   └── Frontend:   8080 + 2 = 8082
│
└── kalle (UID 1003):
    ├── PostgreSQL: 5432 + 3 = 5435
    ├── Backend:    3000 + 3 = 3003
    └── Frontend:   8080 + 3 = 8083
```

---

## ☸️ Kubernetes Architecture (Lab 3-10)

### Multiple Kind Clusters (Full Isolation)

```
┌─────────────────────────────────────────────────────────────────┐
│                    Host: kirjakast                               │
│                    Docker (for Kind nodes)                       │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  janek-k8s-lab Cluster (Kind)                            │   │
│  │  ┌──────────────────┐    ┌──────────────────┐            │   │
│  │  │ Control Plane    │    │ Worker Node      │            │   │
│  │  │ (Docker container│    │ (Docker container│            │   │
│  │  │                  │    │                  │            │   │
│  │  │  Namespaces:     │    │  Pods:           │            │   │
│  │  │  janek-default   │    │  user-service    │            │   │
│  │  │  janek-prod      │    │  postgres        │            │   │
│  │  │  janek-staging   │    │  frontend        │            │   │
│  │  └──────────────────┘    └──────────────────┘            │   │
│  │  API Server: :6444                                        │   │
│  │  HTTP: :30081  HTTPS: :30444                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  maria-k8s-lab Cluster (Kind)                            │   │
│  │  ┌──────────────────┐    ┌──────────────────┐            │   │
│  │  │ Control Plane    │    │ Worker Node      │            │   │
│  │  │                  │    │                  │            │   │
│  │  │  Namespaces:     │    │  Pods:           │            │   │
│  │  │  maria-default   │    │  user-service    │            │   │
│  │  │  maria-prod      │    │  postgres        │            │   │
│  │  └──────────────────┘    └──────────────────┘            │   │
│  │  API Server: :6445                                        │   │
│  │  HTTP: :30082  HTTPS: :30445                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  kalle-k8s-lab Cluster (Kind)                            │   │
│  │  ...                                                      │   │
│  │  API Server: :6446                                        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Kubernetes Resource Isolation

```
janek-k8s-lab Cluster:
├── Namespaces:
│   ├── janek-default (auto-created)
│   ├── janek-production
│   ├── janek-staging
│   └── janek-dev
│
├── Pods:
│   ├── janek-production/user-service-xxxxx
│   ├── janek-production/postgres-0
│   └── janek-staging/user-service-yyyyy
│
├── Services:
│   ├── janek-production/user-service (ClusterIP)
│   ├── janek-production/user-service-external (NodePort :30081)
│   └── janek-production/postgres (ClusterIP)
│
├── PersistentVolumes:
│   ├── pvc-xxxxx (for postgres in production)
│   └── pvc-yyyyy (for postgres in staging)
│
└── ConfigMaps/Secrets:
    ├── janek-production/app-config
    └── janek-production/db-credentials

COMPLETELY ISOLATED FROM maria-k8s-lab and kalle-k8s-lab!
```

---

## 🔀 Workflow Comparison

### Docker (Lab 1-2)

```
User Action:                          System Action:

1. source multi-user-setup.sh   →    Generate ~/.env-lab with:
                                      - USER_PREFIX=janek
                                      - POSTGRES_PORT=5433
                                      - BACKEND_PORT=3001
                                      - FRONTEND_PORT=8081

2. dc-up                         →    docker compose -p janek up
                                      Creates:
                                      - janek-backend-1
                                      - janek-postgres-1
                                      - janek_default network
                                      - janek_postgres-data volume

3. curl localhost:3001/health    →    Routes to janek-backend-1

4. dc-down                       →    Stop janek-* containers only
```

### Kubernetes (Lab 3-10)

```
User Action:                          System Action:

1. bash k8s-multi-user-setup.sh  →    kind create cluster --name janek-k8s-lab
   create                             Creates:
                                      - janek-k8s-lab-control-plane (Docker)
                                      - janek-k8s-lab-worker (Docker)
                                      - kubeconfig at ~/.kube/config-janek
                                      - Namespace: janek-default

2. k apply -f deployment.yaml    →    kubectl --context kind-janek-k8s-lab apply
                                      Creates pods in janek-k8s-lab ONLY

3. k get pods                    →    Shows pods from janek-k8s-lab ONLY

4. bash k8s-multi-user-setup.sh  →    kind delete cluster --name janek-k8s-lab
   delete                             Removes entire cluster
```

---

## 📊 Resource Usage

### Per-User Resources (Estimate)

```
Docker (Lab 1-2):
├── RAM: ~500 MB
│   ├── PostgreSQL: ~200 MB
│   ├── Backend (Node.js): ~150 MB
│   └── Frontend (Nginx): ~50 MB
│
└── Disk: ~2 GB
    ├── Images: ~1.5 GB
    └── Volumes: ~500 MB

Kubernetes (Lab 3-10):
├── RAM: ~1.5 GB
│   ├── Kind control-plane: ~800 MB
│   ├── Kind worker: ~400 MB
│   └── Workload pods: ~300 MB
│
└── Disk: ~5 GB
    ├── Kind node images: ~3 GB
    └── Persistent volumes: ~2 GB
```

### VPS Capacity (kirjakast: 7.8GB RAM, 96GB disk)

```
Theoretical Maximum:
├── Docker only: ~12 concurrent users (500MB each)
├── Kubernetes only: ~4 concurrent users (1.5GB each)
└── Mixed (recommended): 6-8 users

Recommended Load:
├── Active Docker users: 6-8
├── Active K8s users: 3-4
└── Total: 6-8 concurrent users (safe buffer)
```

---

## 🔐 Isolation Matrix

| Resource Type | Docker Isolation | Kubernetes Isolation |
|---------------|------------------|----------------------|
| **Processes** | ✅ Per-container | ✅ Per-pod |
| **Filesystem** | ✅ Per-container | ✅ Per-pod |
| **Network** | ⚠️ Shared Docker network | ✅ Per-cluster CNI |
| **Port space** | ⚠️ Shared (user-offset) | ✅ Per-cluster |
| **Storage** | ✅ Per-volume (prefixed) | ✅ Per-cluster PV |
| **Namespaces** | N/A | ✅ Per-cluster |
| **API access** | N/A | ✅ Per-cluster API server |
| **etcd** | N/A | ✅ Per-cluster etcd |

**Legend:**
- ✅ Fully isolated
- ⚠️ Partially isolated (requires naming convention)
- ❌ Not isolated

---

## 🎯 Decision Tree: Which Isolation?

```
Start
  │
  ├─ Lab 1-2 (Docker)?
  │   └─> Use Docker Compose with user prefixes
  │       ├─ Pros: Lightweight, fast setup
  │       ├─ Cons: Shared Docker daemon, manual port management
  │       └─ Command: source multi-user-setup.sh
  │
  └─ Lab 3-10 (Kubernetes)?
      └─> Use Kind cluster per user
          ├─ Pros: Full isolation, realistic K8s environment
          ├─ Cons: Higher resource usage (~1.5GB RAM)
          └─ Command: bash k8s-multi-user-setup.sh create
```

---

## 🔄 Migration Path

```
Single User → Multi User

Before:
├── docker run -p 3000:3000 backend           # ❌ Conflicts
├── kubectl create namespace production       # ❌ Conflicts
└── docker compose up                         # ❌ Conflicts

After (Docker):
├── source multi-user-setup.sh               # Setup once
├── dc-up                                    # Uses janek- prefix
└── curl localhost:$BACKEND_PORT             # User-specific port

After (Kubernetes):
├── bash k8s-multi-user-setup.sh create      # Own cluster
├── k apply -f deployment.yaml               # Own cluster
└── k get pods                               # Own cluster
```

---

## 📝 Summary

### Docker (Lab 1-2)
- **Isolation level:** Medium (shared daemon, isolated containers)
- **Setup complexity:** Low
- **Resource usage:** Low (~500MB per user)
- **Best for:** Docker basics, Compose fundamentals

### Kubernetes (Lab 3-10)
- **Isolation level:** High (separate clusters)
- **Setup complexity:** Medium
- **Resource usage:** Medium (~1.5GB per user)
- **Best for:** K8s learning, production-like environments

### VPS kirjakast
- **Capacity:** 6-8 concurrent users (mixed workload)
- **Recommendation:** Monitor resources with `docker stats` and `free -h`
- **Cleanup:** Users should run cleanup after each lab session
