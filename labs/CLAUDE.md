# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Repository Overview

This is a **DevOps hands-on training program** (Estonian language) with 10 progressive labs teaching DevOps administration skills through practical exercises. The focus is on infrastructure/deployment, NOT application development.

**Total:** 10 labs, 45 hours of hands-on practice
**Target audience:** DevOps administrators learning containerization, orchestration, CI/CD, security, and infrastructure-as-code

---

## Core Architecture

### Three Pre-Built Microservices

The labs use three ready-made microservices that students deploy/manage:

```
Frontend (Port 8080)
  ├─> User Service (Node.js + Express, Port 3000)
  │   └─> PostgreSQL users DB (Port 5432)
  └─> Todo Service (Java Spring Boot, Port 8081)
      └─> PostgreSQL todos DB (Port 5433)
```

**Applications (in `apps/`):**
- `backend-nodejs/` - User Service (JWT auth, RBAC, user management)
- `backend-java-spring/` - Todo Service (CRUD, statistics, JWT validation)
- `frontend/` - Web UI (HTML/CSS/Vanilla JS)

**Key Point:** Applications are complete and working. Students perform DevOps tasks (dockerizing, deploying, monitoring), NOT application development.

---

## Lab Structure (Progressive)

Each lab builds on previous ones:

1. **Docker Basics (4h)** - Containerize all 3 services, multi-stage builds, optimization
2. **Docker Compose (3h)** - Multi-container orchestration, environments (dev/prod)
3. **Kubernetes Basics (5h)** - Pods, Deployments, Services, ConfigMaps, Secrets, PVCs
4. **Kubernetes Advanced (5h)** - Ingress, HPA, Helm charts, rolling updates
5. **CI/CD Pipeline (4h)** - GitHub Actions, automated builds/deployments
6. **Monitoring & Logging (4h)** - Prometheus, Grafana, Loki, alerting
7. **Security & Secrets (5h)** - Vault, RBAC, Network Policies, Trivy, Sealed Secrets
8. **GitOps with ArgoCD (5h)** - ArgoCD, Kustomize, ApplicationSet, Canary deployments
9. **Backup & Disaster Recovery (5h)** - Velero, scheduled backups, DR drills
10. **Terraform IaC (5h)** - Kubernetes resources via Terraform, modules, state management

**Directory pattern:** `XX-name-lab/` contains:
- `README.md` - Lab overview and instructions
- `exercises/` - Step-by-step exercises (typically 5-6 per lab)
- `solutions/` - Reference solutions
- `reset.sh` - Cleanup script (removes Docker containers/images/networks/volumes or K8s resources)

---

## Common Commands

### Application Testing

```bash
# Start all services with Docker Compose
cd apps/
docker-compose up -d
docker-compose logs -f

# Health checks
curl http://localhost:3000/health  # User Service
curl http://localhost:8081/health  # Todo Service
curl http://localhost:8080          # Frontend

# API testing workflow
# 1. Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"test123"}'

# 2. Login (get JWT token)
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# 3. Use token
TOKEN="<jwt-from-login>"
curl http://localhost:3000/api/users -H "Authorization: Bearer $TOKEN"
```

### Lab Management

```bash
# Reset a lab (cleanup all resources)
cd 01-docker-lab/
./reset.sh

# Start a lab
cd 01-docker-lab/
cat README.md
cat exercises/01a-single-container-nodejs.md

# Build applications (Lab 1 examples)
cd apps/backend-nodejs/
docker build -t user-service:1.0 .

cd apps/backend-java-spring/
./gradlew build
docker build -t todo-service:1.0 .
```

### Docker Operations (Labs 1-2)

```bash
# Docker build
docker build -t <image-name>:<tag> .
docker build -f Dockerfile.optimized -t <image>:optimized .

# Run with networking
docker run -d --name user-service --network todo-network \
  -e DATABASE_URL=postgres://... -p 3000:3000 user-service:1.0

# Cleanup
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi user-service:*
docker network rm todo-network
docker volume rm postgres-user-data
```

### Kubernetes Operations (Labs 3-10)

```bash
# Apply manifests
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -k overlays/production/  # Kustomize

# Check resources
kubectl get pods -n production
kubectl get deployments -n production
kubectl logs <pod-name> -n production
kubectl describe pod <pod-name> -n production

# Port forwarding for testing
kubectl port-forward svc/user-service 3000:3000 -n production

# Cleanup
kubectl delete namespace production
kubectl delete -f deployment.yaml
```

### Helm Operations (Lab 4+)

```bash
# Install chart
helm install user-service ./charts/user-service -n production

# Upgrade
helm upgrade user-service ./charts/user-service -n production

# Uninstall
helm uninstall user-service -n production
```

---

## Language & Terminology

**Primary language:** Estonian (exercises, documentation, comments)
**Technical terms:** English terms in parentheses after Estonian, e.g., "Docker pilt (image)"

**See `TERMINOLOOGIA.md` for the full terminology guide:**
- Estonian terms: "ehita" (build), "pilt" (image), "konteiner" (container), "andmehoidla" (volume), "võrk" (network)
- Commands stay in English: `docker build`, `kubectl apply`, etc.
- File names unchanged: `Dockerfile`, `package.json`, etc.

**When creating new content:**
- Use Estonian for explanations and instructions
- Keep technical terms in English with Estonian translation in parentheses
- Follow the pattern: "Loo Kubernetes deployment (deployment) kasutades kubectl apply käsku"

---

## File Structure

```
labs/
├── README.md                    # Main overview (10 labs, 45h)
├── CLAUDE.md                    # This file
│
├── apps/                        # Pre-built applications
│   ├── README.md
│   ├── ARHITEKTUUR.md          # Detailed architecture explanation
│   ├── docker-compose.yml      # Full stack setup
│   ├── backend-nodejs/         # User Service (Node.js)
│   ├── backend-java-spring/    # Todo Service (Java Spring Boot)
│   ├── frontend/               # Web UI
│   └── learning-materials/     # Auth tutorials, etc.
│
├── 01-docker-lab/              # 6 exercises, solutions/, reset.sh
├── 02-docker-compose-lab/      # 6 exercises, solutions/, reset.sh
├── 03-kubernetes-basics-lab/   # 6 exercises, reset.sh
├── 04-kubernetes-advanced-lab/ # 5 exercises, solutions/
├── 05-cicd-lab/                # 5 exercises, solutions/workflows/
├── 06-monitoring-logging-lab/  # 5 exercises, solutions/
├── 07-security-secrets-lab/    # 5 exercises, solutions/
├── 08-gitops-argocd-lab/       # 5 exercises, solutions/
├── 09-backup-disaster-recovery-lab/ # 5 exercises, solutions/
└── 10-terraform-iac-lab/       # 5 exercises, solutions/
```

---

## Key Architectural Patterns

### JWT Authentication Flow

1. User registers via User Service (`POST /api/auth/register`)
2. User logs in, receives JWT token (`POST /api/auth/login`)
3. Frontend stores JWT in localStorage
4. All requests to both services include `Authorization: Bearer <token>` header
5. Todo Service validates JWT using same `JWT_SECRET` as User Service
6. Services share JWT validation but maintain separate databases

### Microservices Communication

- **Frontend → User Service:** Direct REST API calls for auth and user management
- **Frontend → Todo Service:** Direct REST API calls for todo operations
- **User Service ↔ Todo Service:** No direct communication; JWT token carries user identity
- **Shared secret:** Both services use same `JWT_SECRET` for token validation
- **Database isolation:** Each service has dedicated PostgreSQL database

### Docker Multi-Stage Build (Java)

Lab 1 teaches multi-stage builds for Java to reduce image size:
```dockerfile
# Stage 1: Build (Gradle + JDK)
FROM gradle:8-jdk17 AS build
COPY . .
RUN gradle bootJar

# Stage 2: Runtime (JRE only)
FROM eclipse-temurin:17-jre
COPY --from=build /app/build/libs/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

Result: ~600MB → ~250MB image size

### Kubernetes Deployment Progression

- **Lab 3:** Basic Deployments with 1-3 replicas, manual scaling
- **Lab 4:** HPA (Horizontal Pod Autoscaler), Ingress routing, Helm templating
- **Lab 5:** Automated deployments via GitHub Actions
- **Lab 7:** RBAC policies, Network Policies, Sealed Secrets
- **Lab 8:** ArgoCD manages all deployments, Git as source of truth
- **Lab 9:** Velero backs up everything (manifests + PVs)
- **Lab 10:** Terraform provisions infrastructure, ArgoCD deploys apps

---

## Working with This Repository

### When creating new lab content:

1. **Follow existing patterns:**
   - Lab README structure: Overview → Learning Objectives → Prerequisites → Exercises → Solutions
   - Exercise files: Step-by-step instructions with verification steps
   - Solutions: Working examples with comments

2. **Use Estonian consistently:**
   - Main text in Estonian
   - Technical terms in English (in parentheses)
   - Code/commands unchanged
   - See TERMINOLOOGIA.md for standard translations

3. **Test before committing:**
   - Run exercises start-to-finish
   - Verify reset.sh cleans everything
   - Test on fresh Minikube/K3s cluster
   - Document prerequisites clearly

### When helping users:

1. **Identify lab context:** Which lab (1-10) is the user working on?
2. **Check prerequisites:** Previous labs completed? Required tools installed?
3. **Use reset.sh liberally:** If something's broken, suggest cleanup and restart
4. **Reference architecture:** Point to apps/ARHITEKTUUR.md for microservices questions
5. **Follow progression:** Don't skip labs - each builds on previous

### When updating documentation:

1. **Main README.md:** Overall program description, all 10 labs table
2. **Lab-specific READMEs:** Detailed per-lab instructions
3. **Keep synchronized:** Lab descriptions should match across README.md and individual lab READMEs
4. **Update timestamps:** Add "Viimane uuendus: YYYY-MM-DD" at bottom of modified files

---

## Important Notes

### Applications are NOT for development

- Apps are complete, tested, and frozen
- Students do NOT modify application code
- Focus is 100% on DevOps tasks: containerization, deployment, monitoring, security
- If app bugs are found, document them but don't fix during labs

### Reset scripts are critical

- Each lab's `reset.sh` must clean ALL resources created in that lab
- Test reset scripts thoroughly - students rely on them when stuck
- Reset should be idempotent (safe to run multiple times)
- Should prompt before destructive operations

### Lab dependencies

Labs must be done in order (1→2→3...→10):
- Lab 2 needs Docker images from Lab 1
- Lab 3 needs Docker knowledge from Labs 1-2
- Lab 5 needs Kubernetes from Labs 3-4
- Lab 7-10 build on entire stack from Labs 1-6

### Environment requirements

**Labs 1-2 (Docker):**
- Docker Engine, Docker Compose
- 4GB RAM, 20GB disk

**Labs 3-6 (Kubernetes):**
- Minikube or K3s (local cluster)
- kubectl
- 8GB RAM, 40GB disk

**Labs 7-10 (Advanced):**
- All above plus Helm 3
- GitHub account (for Lab 5, 8)
- 16GB RAM recommended

---

## Common Issues & Solutions

### Docker build fails (Lab 1)

```bash
# Check Docker running
docker info

# Clear build cache
docker builder prune -a

# Use fresh clone
git clean -fdx apps/backend-nodejs/
```

### Kubernetes pod crashes (Labs 3-4)

```bash
# Check logs
kubectl logs <pod-name> -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'

# Verify ConfigMaps/Secrets exist
kubectl get configmaps -n production
kubectl get secrets -n production
```

### Database connection issues

Common environment variables needed:
```bash
# User Service
DATABASE_URL=postgresql://user:password@postgres-user:5432/user_service_db

# Todo Service
DATABASE_URL=postgresql://user:password@postgres-todo:5433/todo_service_db
JWT_SECRET=<must-match-user-service>
```

### Lab seems stuck

```bash
# Use reset script
cd XX-name-lab/
./reset.sh

# Re-read README
cat README.md

# Start from exercise 1
cat exercises/01-*.md
```

---

## Success Criteria

After completing all 10 labs, students should be able to:

1. **Containerize any application** (Node.js, Java, Python, etc.)
2. **Deploy to Kubernetes** with proper resource management
3. **Set up CI/CD pipeline** with automated testing and deployment
4. **Monitor production systems** with Prometheus/Grafana
5. **Secure infrastructure** with Vault, RBAC, Network Policies
6. **Implement GitOps** with ArgoCD for declarative deployments
7. **Handle disasters** with backup/restore using Velero
8. **Manage infrastructure as code** with Terraform

This represents a complete DevOps administrator skillset for modern cloud-native applications.
