# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 📋 Repository Overview

This is a **DevOps training lab repository** for learning hands-on infrastructure management. The focus is on DevOps/infrastructure, NOT application development.

**Primary language:** Estonian (eesti keel)
**Target audience:** DevOps administrators learning containerization, orchestration, CI/CD, and monitoring

---

## 🏗️ Architecture

The repository contains a **progressive 6-lab series** that builds upon itself:

```
apps/ (pre-built applications)
  └── Used as subjects for containerization in all labs

Lab 1 (Docker) → builds images
  ↓
Lab 2 (Docker Compose) → uses Lab 1 images
  ↓
Lab 3 (Kubernetes Basics) → deploys Lab 1 images to K8s
  ↓
Lab 4 (Kubernetes Advanced) → enhances Lab 3 deployments
  ↓
Lab 5 (CI/CD) → automates Labs 1-4
  ↓
Lab 6 (Monitoring) → monitors Labs 1-5
```

### Pre-built Applications (apps/)

Three microservices that serve as training subjects:

1. **User Service** (backend-nodejs/)
   - Node.js 18 + Express + PostgreSQL
   - Port 3000
   - JWT auth + RBAC (user/admin roles)
   - Full CRUD with pagination, search, filtering
   - Endpoints: `/api/auth/*`, `/api/users/*`, `/health`

2. **Todo Service** (backend-java-spring/)
   - Java 17 + Spring Boot 3
   - Port 8081
   - JWT auth + Spring Security
   - Endpoints: `/api/todos/*`, `/health`

3. **Frontend** (frontend/)
   - HTML5 + CSS3 + Vanilla JavaScript
   - Port 8080
   - Connects to User/Todo services

---

## 🚀 Running Applications

### User Service (Node.js)

```bash
cd apps/backend-nodejs

# Setup
npm install
cp .env.example .env
# Edit .env with DB credentials and JWT_SECRET

# Database setup
sudo -u postgres psql -f database-setup.sql

# Run
npm start  # Listens on port 3000
```

**Environment variables required:**
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `JWT_SECRET`, `JWT_EXPIRES_IN`
- `PORT`, `NODE_ENV`

### Testing User Service

```bash
# Health check
curl http://localhost:3000/health

# Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"test123"}'

# Login (get JWT token)
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Use token
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer <token>"
```

---

## 📚 Lab Structure

Each lab follows this pattern:

```
XX-labname-lab/
├── README.md              # Lab overview, objectives, structure
├── exercises/             # Step-by-step exercises (5 exercises per lab)
│   ├── 01-topic1.md
│   ├── 02-topic2.md
│   └── ...
└── solutions/             # Reference solutions
    └── README.md
```

### Lab Progression

**Lab 1: Docker Basics** (01-docker-lab/) ✅ COMPLETED
- Exercises: Single container, Multi-container, Networking, Volumes, Optimization
- Solutions: Dockerfile, Dockerfile.optimized, .dockerignore for backend-nodejs

**Lab 2: Docker Compose** (02-docker-compose-lab/) ✅ COMPLETED
- Exercises: Basic compose, Full-stack, Dev/Prod envs, Scaling
- Solutions: docker-compose.yml files

**Lab 3: Kubernetes Basics** (03-kubernetes-basics-lab/) ✅ COMPLETED
- Exercises: Pods, Deployments, Services, ConfigMaps/Secrets, PersistentVolumes
- Solutions: K8s manifests/

**Lab 4: Kubernetes Advanced** (04-kubernetes-advanced-lab/) ✅ COMPLETED
- Exercises: Ingress, Helm, Autoscaling, Rolling updates, Monitoring
- Solutions: K8s manifests/, Helm charts

**Lab 5: CI/CD** (05-cicd-lab/) ✅ COMPLETED
- Exercises: GitHub Actions basics, Docker build/push, K8s deploy, Testing, Rollback
- Solutions: .github/workflows/

**Lab 6: Monitoring & Logging** (06-monitoring-logging-lab/) ✅ COMPLETED
- Exercises: Prometheus, Grafana, Log aggregation, Alerting, Troubleshooting
- Solutions: configs/

---

## 📝 Creating New Lab Content

### When creating exercises:

1. **Language:** Write in Estonian
2. **Structure:** Use consistent markdown format:
   - Title + duration + objective
   - Overview
   - Learning objectives (✅ checkboxes)
   - Steps (numbered with code blocks)
   - Validation checklist
   - Learned concepts
   - Next steps link

3. **Tone:** Educational, hands-on, practical
4. **Code examples:** Always provide working examples
5. **Duration:** Each exercise should be 45-60 minutes

### When creating solutions:

1. Place in `solutions/` directory
2. Include README.md explaining usage
3. Provide both basic and optimized versions where applicable
4. Add comments explaining key concepts

---

## 🎯 Key Principles

1. **DevOps Focus:** These are infrastructure labs, not application development tutorials
2. **Progressive Learning:** Each lab builds on previous ones
3. **Hands-on Practice:** Learners should type commands, not copy-paste
4. **Real-world Scenarios:** Use production-like setups (RBAC, health checks, multi-stage builds)
5. **Estonian Language:** All content must be in Estonian with English technical terms in parentheses

---

## 📂 File Locations

**Applications:**
- `apps/backend-nodejs/` - User Service (ready to use)
- `apps/backend-java-spring/` - Todo Service (ready to use)
- `apps/frontend/` - Web UI (ready to use)
- `apps/learning-materials/` - Supplementary tutorials (auth, etc)

**Labs:**
- `01-docker-lab/` - ✅ Complete with 5 exercises + solutions
- `02-docker-compose-lab/` - ✅ Complete with 4 exercises + solutions
- `03-kubernetes-basics-lab/` - ✅ Complete with 5 exercises + solutions
- `04-kubernetes-advanced-lab/` - ✅ Complete with 5 exercises + solutions
- `05-cicd-lab/` - ✅ Complete with 5 exercises + solutions
- `06-monitoring-logging-lab/` - ✅ Complete with 5 exercises + solutions

**Documentation:**
- `00-LAB-RAAMISTIK.md` - Master framework document
- `README.md` - Repository introduction
- Each app/lab has own README.md

---

## 🔧 Docker Commands (Lab 1)

```bash
# Build image
docker build -t user-service:1.0 .
docker build -f Dockerfile.optimized -t user-service:1.0-opt .

# Run container
docker run -d --name user-service -p 3000:3000 \
  -e DB_HOST=postgres -e JWT_SECRET=secret \
  user-service:1.0

# Network
docker network create app-network
docker run --network app-network ...

# Volume
docker volume create postgres-data
docker run -v postgres-data:/var/lib/postgresql/data ...

# Debug
docker ps
docker logs <container>
docker exec -it <container> sh
docker inspect <container>
```

---

## 🎓 Current State

**Completed:**
- ✅ Repository structure
- ✅ apps/ with working User Service, Todo Service, and Frontend
- ✅ Lab 1 (Docker) with 5 exercises and solutions
- ✅ Lab 2 (Docker Compose) with 4 exercises and solutions
- ✅ Lab 3 (Kubernetes Basics) with 5 exercises and solutions
- ✅ Lab 4 (Kubernetes Advanced) with 5 exercises and solutions
- ✅ Lab 5 (CI/CD) with 5 exercises and solutions
- ✅ Lab 6 (Monitoring & Logging) with 5 exercises and solutions
- ✅ Master framework (00-LAB-RAAMISTIK.md)

**Status:** ✅ All 6 labs are 100% complete!

**Optional Future Enhancements:**
- Testing all labs in real environments
- Adding screenshots to exercises
- Lab 7 (Security & Best Practices)
- Lab 8 (Advanced Topics: Service Mesh, GitOps)

---

## 💡 When Working on This Repository

1. **Read 00-LAB-RAAMISTIK.md first** - it's the master plan
2. **Maintain consistency** - follow existing exercise structure
3. **Test everything** - all commands must work
4. **Think progressive** - each lab builds on previous
5. **Write in Estonian** - with English technical terms when needed
6. **Focus on DevOps** - not application development

---

**Repository Path:** `/home/janek/Documents/Meie pere/õppematerjal/hostinger/labs/`

**Main Reference:** `00-LAB-RAAMISTIK.md` - Always consult this for lab structure and progression
- jäta meelde