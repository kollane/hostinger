# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Repository Overview

This is an **Estonian-language full-stack DevOps training curriculum** for learning production-ready web application development, containerization, and orchestration on Ubuntu 24.04 LTS VPS.

**VPS Environment:**
- **Hostname:** your-vps-hostname (example: vpsserver)
- **OS:** Ubuntu 24.04.3 LTS
- **User:** your-username (example: student)
- **IP:** YOUR_VPS_IP (example: 203.0.113.42)
- **Resources:** 7.8 GB RAM, 2 CPU cores, 96 GB disk (adjust based on your VPS)

**Language:** Estonian (eesti keel) with English technical terms
**Structure:** 25 chapters of theory + 6 hands-on lab modules
**Focus:** Full-stack development (Node.js/Express/PostgreSQL) → Docker → Kubernetes → CI/CD

---

## Repository Structure

```
/
├── XX-Topic-Name.md          # 12 completed theory chapters (Estonian)
├── PROGRESS-STATUS.md        # Tracks which chapters are complete
├── 00-KOOLITUSKAVA-RAAMISTIK.md  # Master curriculum framework
└── labs/                     # Hands-on DevOps practice
    ├── apps/                 # Pre-built microservices for lab exercises
    │   ├── backend-nodejs/   # User Service (Node.js + Express + PostgreSQL)
    │   ├── backend-java-spring/  # Todo Service (Java Spring Boot + PostgreSQL)
    │   └── frontend/         # Web UI (HTML + Vanilla JS)
    ├── 01-docker-lab/        # Lab 1: Docker basics (✅ complete)
    ├── 02-docker-compose-lab/    # Lab 2: Multi-container apps
    ├── 03-kubernetes-basics-lab/ # Lab 3: K8s fundamentals
    ├── 04-kubernetes-advanced-lab/ # Lab 4: Advanced K8s
    ├── 05-cicd-lab/          # Lab 5: GitHub Actions CI/CD
    └── 06-monitoring-logging-lab/ # Lab 6: Prometheus/Grafana
```

---

## Key Architectural Patterns

### Dual PostgreSQL Approach

The curriculum teaches **two PostgreSQL deployment patterns** in parallel:

1. **PRIMARY: Containerized PostgreSQL** (Docker/Kubernetes)
   - StatefulSet in K8s with PersistentVolumes
   - Ideal for: Modern DevOps, microservices, cloud-native apps

2. **ALTERNATIVE: External PostgreSQL** (Traditional VPS)
   - ExternalName Service in K8s
   - Ideal for: Large production systems, dedicated DBA teams

Both approaches are covered in chapters 3, 6, 13, 16, 21, and 22.

### Microservices Architecture

The lab exercises use three pre-built services:

```
Frontend (Port 8080)
    │
    ├──> User Service (Node.js:3000) ──> PostgreSQL (5432)
    └──> Todo Service (Java:8081) ──> PostgreSQL (5433)
```

**IMPORTANT:** The applications in `labs/apps/` are **already built**. Labs focus on DevOps (containerization, orchestration, deployment), NOT application development.

---

## VPS Environment Setup

### Installed Software

**Already installed on VPS:**
- ✅ Docker 29.0.1
- ✅ Docker Compose v2.40.3
- ✅ vim 9.1 (preferred editor)
- ✅ yazi 25.5.31 (file manager)
- ✅ Git

**NOT YET installed (needed for labs):**
- ❌ kubectl (required for Lab 3-4: Kubernetes)
- ❌ Node.js (required for running backend-nodejs locally)
- ❌ PostgreSQL client (psql - for database management)

### Install Missing Software

#### Install Node.js 18
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
node --version  # Should show v18.x.x
```

#### Install PostgreSQL Client
```bash
sudo apt install -y postgresql-client
psql --version  # Should show psql 16.x
```

#### Install kubectl (for Kubernetes labs)
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### Editor Preferences

**Use vim instead of nano** in all instructions:
- Open file: `vim filename`
- Edit mode: Press `i`
- Save and exit: Press `Esc`, then type `:wq` and press Enter
- Exit without saving: Press `Esc`, then type `:q!` and press Enter

**File browsing:** Use `yazi` instead of `ls` for better file management

---

## Running the Applications

### User Service (Node.js Backend)

```bash
cd labs/apps/backend-nodejs

# Setup (requires Node.js - install if not present)
npm install
cp .env.example .env
vim .env  # Edit with database credentials

# Database setup
sudo -u postgres psql -f database-setup.sql

# Run
npm start  # Port 3000
npm run dev  # Development mode with nodemon
```

**Required environment variables:**
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `JWT_SECRET`, `JWT_EXPIRES_IN`
- `PORT`, `NODE_ENV`

**API Endpoints:**
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - JWT authentication
- `GET /api/users` - List users (requires JWT)
- `GET /health` - Health check

### Testing

```bash
# Health check
curl http://localhost:3000/health

# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"test123"}'

# Login (returns JWT)
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

---

## Lab Workflow

Labs are **progressive** - each builds on the previous:

1. **Lab 1 (Docker):** Containerize backend-nodejs
   - Build Dockerfile and optimized multi-stage Dockerfile
   - Solutions in `labs/01-docker-lab/solutions/backend-nodejs/`

2. **Lab 2 (Docker Compose):** Multi-container orchestration
   - Compose PostgreSQL + backend + frontend
   - Two variants: containerized DB vs external DB

3. **Lab 3 (K8s Basics):** Deploy to Kubernetes
   - Pods, Deployments, Services
   - ConfigMaps, Secrets, PersistentVolumes

4. **Lab 4 (K8s Advanced):** Production features
   - Ingress, Helm, HorizontalPodAutoscaler
   - Rolling updates, health checks

5. **Lab 5 (CI/CD):** Automation
   - GitHub Actions for build/test/deploy
   - Multi-environment (dev/staging/prod)

6. **Lab 6 (Monitoring):** Observability
   - Prometheus + Grafana
   - Log aggregation (Loki)

---

## Important Commands

### Docker (Lab 1)

```bash
# Build images
docker build -t user-service:1.0 .
docker build -f Dockerfile.optimized -t user-service:1.0-opt .

# Run containers
docker run -d --name user-service -p 3000:3000 \
  -e DB_HOST=postgres -e JWT_SECRET=secret \
  user-service:1.0

# Networks and volumes
docker network create app-network
docker volume create postgres-data

# Debug
docker ps
docker logs <container>
docker exec -it <container> sh
```

### Docker Compose (Lab 2)

```bash
docker compose up -d
docker compose down
docker compose logs -f
docker compose ps
```

### Kubernetes (Labs 3-4)

```bash
# Apply manifests
kubectl apply -f deployment.yaml

# Check status
kubectl get pods
kubectl get services
kubectl logs <pod-name>
kubectl describe pod <pod-name>

# Debug
kubectl exec -it <pod-name> -- sh
```

### SSH Access

```bash
# Local machine (connecting to VPS)
ssh your-username@your-vps-hostname
# Or using IP:
ssh your-username@YOUR_VPS_IP

# VPS hostname
hostname  # Returns: your-vps-hostname
```

### PostgreSQL

```bash
# Connect to containerized PostgreSQL
docker exec -it postgres psql -U username -d database

# Connect to external PostgreSQL (if installed locally on VPS)
psql -h localhost -U username -d database

# Connect from local machine to VPS PostgreSQL
psql -h YOUR_VPS_IP -U username -d database

# Common commands
\l              # List databases
\c dbname       # Connect to database
\dt             # List tables
\d tablename    # Describe table
```

---

## Development Guidelines

### When Working on Theory Chapters (Root *.md Files)

1. **Language:** Write in Estonian with English technical terms in parentheses
2. **Structure:** Follow the pattern in existing chapters
3. **Duration:** Each chapter should be 3-5 hours of material
4. **Practical Focus:** Include code examples and exercises
5. **Editor:** Use vim (not nano) in all command examples
6. **Environment:** Use generic placeholders (hostname: your-vps-hostname, user: your-username)
7. **Reference:** Check `00-KOOLITUSKAVA-RAAMISTIK.md` for chapter outlines

### When Working on Lab Content (labs/)

1. **Language:** Estonian with English commands/code
2. **DevOps Focus:** Labs teach infrastructure, not application development
3. **Progressive:** Each lab assumes previous labs are complete
4. **Hands-On:** Provide step-by-step commands, not just theory
5. **Validation:** Include verification steps and troubleshooting
6. **Reference:** Check `labs/00-LAB-RAAMISTIK.md` for lab structure

### When Creating Lab Exercises

Each exercise should have:
- Title + duration (45-60 minutes) + objectives
- Prerequisites clearly stated
- Numbered steps with code blocks
- Validation checklist
- Troubleshooting section
- "What you learned" summary

---

## Progress Tracking

Check `PROGRESS-STATUS.md` to see which chapters are complete.

**Completed (48%):**
- Chapters 1-12: VPS setup, PostgreSQL, Git, Node.js/Express, REST API, JWT auth, Frontend, Docker basics

**Next:**
- Chapter 13: Docker Compose
- Chapters 14-25: Docker Registry, Kubernetes, CI/CD, Monitoring, Security, Troubleshooting

---

## Key Technical Decisions

### VPS Infrastructure

**Production Environment:**
- Ubuntu 24.04.3 LTS
- Docker-first approach (Docker 29+ + Compose v2.40+)
- User: your-username (sudo access required)
- IP: YOUR_VPS_IP
- Preferred editor: vim
- File manager: yazi (optional)

**All labs run on a VPS where the curriculum is being taught**

### PostgreSQL Deployment

**Containerized (PRIMARY):**
- Use StatefulSet in Kubernetes
- PersistentVolumeClaim for data
- ConfigMap for postgresql.conf
- CronJob for backups

**External (ALTERNATIVE):**
- ExternalName Service or manual Endpoints
- SSL/TLS required
- External backup/HA solutions

### Application Stack

- **Backend:** Node.js 18 + Express 4.18
- **Database:** PostgreSQL 16 (pg library 8.11)
- **Auth:** JWT (jsonwebtoken 9.0) + bcrypt 5.1
- **Frontend:** Vanilla JavaScript (no frameworks)
- **Container Base:** `node:18-alpine` for smaller images
- **Process Manager:** PM2 (production) or nodemon (dev)

### Security Practices

- JWT tokens for authentication
- bcrypt for password hashing (10 rounds)
- RBAC with user/admin roles
- Parameterized queries (SQL injection prevention)
- Environment variables for secrets (never hardcoded)
- CORS configuration
- Rate limiting
- Security headers (Helmet)

---

## File Locations

**Theory:**
- Root directory: `XX-Topic-Name.md` (Estonian chapters)
- Framework: `00-KOOLITUSKAVA-RAAMISTIK.md`

**Applications:**
- User Service: `labs/apps/backend-nodejs/`
- Todo Service: `labs/apps/backend-java-spring/`
- Frontend: `labs/apps/frontend/`

**Lab Exercises:**
- `labs/XX-labname-lab/exercises/XX-topic.md`
- `labs/XX-labname-lab/solutions/`

**Documentation:**
- Lab overview: `labs/README.md`
- Lab framework: `labs/00-LAB-RAAMISTIK.md`
- App-specific: `labs/apps/*/README.md`

---

## Common Pitfalls

1. **Language mixing:** Theory chapters MUST be in Estonian, not English
2. **Application development:** Labs are for DevOps, not building new features
3. **Lab independence:** Each lab depends on previous labs - don't skip ahead
4. **PostgreSQL variants:** Always mention which variant (containerized vs external) when discussing database deployment
5. **Environment variables:** Never commit `.env` files with real credentials

---

## When Creating New Content

### New Theory Chapter

1. Check `00-KOOLITUSKAVA-RAAMISTIK.md` for outline
2. Follow structure of existing chapters (1-12)
3. Write in Estonian with English technical terms
4. Include practical examples and exercises
5. Update `PROGRESS-STATUS.md` when complete

### New Lab Exercise

1. Check `labs/00-LAB-RAAMISTIK.md` for structure
2. Place in appropriate lab directory
3. Use numbered markdown files (01-topic.md, 02-topic.md)
4. Provide working commands and code
5. Include solutions in `solutions/` directory
6. Test everything before committing

---

## Repository Goals

**Primary Audience:** Estonian-speaking developers learning DevOps and cloud-native development

**Learning Path:**
1. VPS and Linux basics
2. PostgreSQL (both deployment patterns)
3. Full-stack development (Node.js + Express + Vanilla JS)
4. Containerization (Docker)
5. Orchestration (Kubernetes)
6. Automation (CI/CD)
7. Production readiness (monitoring, security, troubleshooting)

**End Goal:** Deploy a production-ready, scalable, monitored full-stack application on Kubernetes with automated CI/CD pipeline.

---

**Repository Path:** `/home/your-username/hostinger` (adjust to your setup)
**Main References:**
- `00-KOOLITUSKAVA-RAAMISTIK.md` - Master curriculum
- `labs/00-LAB-RAAMISTIK.md` - Lab structure
- `PROGRESS-STATUS.md` - Progress tracking
- `UUS-DEVOPS-KOOLITUSKAVA.md` - New DevOps-focused curriculum (v2.0)
- `IMPLEMENTEERIMISE-PLAAN.md` - Implementation plan
