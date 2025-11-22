# Lisa Peatükk: Cloud Providers ja Teenuste Mudelid

**Kestus:** 3-4 tundi
**Eesmärk:** Mõista cloud computing mudeleid (IaaS, PaaS, SaaS) ja peamisi cloud provider'eid DevOps administraatori vaatenurgast

---

## 📋 Ülevaade

DevOps administraator töötab sageli **hybrid cloud** keskkonnas:
- On-premise VPS (nagu meie kirjakast)
- Public cloud (AWS, Azure, GCP)
- Private cloud (OpenStack, VMware)
- Multi-cloud strateegia

See peatükk annab **võrdleva ülevaate** erinevatest cloud provider'itest ja teenuste mudelitest, et teha **teadlikke otsuseid** infrastruktuuri valikul.

---

## ☁️ I. CLOUD COMPUTING MUDELID

### 1.1 IaaS (Infrastructure as a Service)

**Definitsioon:**
Pilvepakkuja pakub **virtualiseeritud** infrastruktuuri ressursse:
- Virtual Machines (VM'id)
- Storage (block, object)
- Networking (VPC, load balancers)
- Firewalls

**Analoogia:**
```
IaaS = Tühi korter üürile
- Saad 4 seina, põranda, lae (VM)
- Mööbli, dekoratsiooni, koristamise teed ise (install OS, software, manage)
```

**Näited:**
- AWS: EC2 (VM), S3 (storage), VPC (networking)
- Azure: Virtual Machines, Blob Storage, Virtual Network
- Google Cloud: Compute Engine, Cloud Storage
- DigitalOcean: Droplets
- **Hostinger VPS** (meie kirjakast) - IaaS!

**DevOps administraator VASTUTAB:**
- ✅ OS install ja update (apt update, apt upgrade)
- ✅ Security patching
- ✅ Software install (Docker, K8s, PostgreSQL)
- ✅ Firewall rules (UFW, Security Groups)
- ✅ Backup automation
- ✅ Monitoring setup

**Pilvepakkuja VASTUTAB:**
- ✅ Datacenter (füüsiline turvalisus)
- ✅ Hardware (serverid, network switches)
- ✅ Virtualization layer (hypervisor)
- ✅ Power ja cooling

**Plussid:**
- ✅ Täielik kontroll OS ja software üle
- ✅ Paindlikkus (kasuta mis tahes tarkvara)
- ✅ Kuluefektiivne (maksad ainult VM eest)

**Miinused:**
- ❌ Rohkem haldamist (OS, security patches, backups)
- ❌ Skaleerimine käsitsi (create new VMs)
- ❌ Turvalisus sinu vastutus (firewall, SSH hardening)

**Kasutusjuhud:**
- Legacy applications (ei saa PaaS'i migreerida)
- Custom software stack
- Full control vajadus
- Cost optimization (shared resources)

**Hinnad (näited):**
```
AWS EC2 t3.medium (2 vCPU, 4GB RAM):
- On-Demand: $0.0416/h = ~$30/month
- Reserved (1 year): ~$20/month
- Spot: ~$12/month (variable)

Hostinger VPS KVM 2 (2 vCPU, 8GB RAM):
- $11.99/month (fixed)
```

---

### 1.2 PaaS (Platform as a Service)

**Definitsioon:**
Pilvepakkuja pakub **platvormi** rakenduste deploy'miseks:
- Runtime environment (Node.js, Java, Python)
- Database (managed)
- Auto-scaling
- Load balancing

**Analoogia:**
```
PaaS = Täismööbliga hotellituba
- Mööbel olemas (runtime, DB)
- Koristus kaasas (patching, scaling)
- Tood ainult oma riided (application code)
```

**Näited:**
- AWS: Elastic Beanstalk, RDS (database), Lambda (serverless)
- Azure: App Service, Azure SQL Database, Functions
- Google Cloud: App Engine, Cloud SQL, Cloud Run
- Heroku (populaarne PaaS startups'ile)
- Render.com, Railway.app (modern PaaS)

**DevOps administraator VASTUTAB:**
- ✅ Application deployment (git push, docker push)
- ✅ Environment variables konfigureerimine
- ✅ Scaling policies (auto-scaling rules)
- ✅ Monitoring ja alerting

**Pilvepakkuja VASTUTAB:**
- ✅ OS patching (automatic)
- ✅ Runtime updates (Node.js, Java versions)
- ✅ Database backup (automated)
- ✅ High availability (multi-AZ)
- ✅ Load balancing
- ✅ SSL certificates (managed)

**Plussid:**
- ✅ Vähem haldamist (no OS, no DB admin)
- ✅ Auto-scaling (traffic spike → add instances)
- ✅ Managed databases (backups, HA, replication)
- ✅ Kiire deployment (git push → production)

**Miinused:**
- ❌ Vendor lock-in (AWS RDS → raske migreerida)
- ❌ Vähem kontrolli (ei saa OS'i customizeda)
- ❌ Kallim (convenience maksab)
- ❌ Limiteeritud valiku (toetatud runtime'id)

**Kasutusjuhud:**
- Rapid prototyping (startup MVP)
- Standard web apps (Node.js, Python, Ruby)
- Focus on code, mitte infrastruktuuril
- Small teams (no dedicated ops)

**Hinnad (näited):**
```
AWS RDS PostgreSQL db.t3.medium (2 vCPU, 4GB RAM):
- $60-80/month (Multi-AZ $120-160/month)
VS
Self-managed PostgreSQL Docker container EC2'l:
- EC2: $30/month + $10 storage = $40/month
- Aga: sina vastutad backup, HA, patching!
```

---

### 1.3 SaaS (Software as a Service)

**Definitsioon:**
Pilvepakkuja pakub **valmis tarkvara** kasutamiseks (veebis):
- No installation
- No maintenance
- Pay per user/month

**Analoogia:**
```
SaaS = Hotell + restoraniga
- Ei pea kodus süüa tegema (no software install)
- Ei pea nõusid pesema (no maintenance)
- Lihtsalt kasutad (web browser)
```

**Näited:**
- **DevOps Tools:**
  - GitHub (Git hosting, CI/CD)
  - GitLab (Git, CI/CD, Container Registry)
  - Jira (project management)
  - Confluence (documentation)
  - Slack (communication)
  - PagerDuty (incident management)
  - Datadog (monitoring - SaaS alternatiiv Prometheus'ele)

- **Business Tools:**
  - Gmail, Outlook (email)
  - Google Workspace, Microsoft 365 (productivity)
  - Salesforce (CRM)
  - Zoom (video conferencing)

**DevOps administraator VASTUTAB:**
- ✅ User management (add/remove users)
- ✅ Permissions (RBAC)
- ✅ Integration (API, webhooks)
- ✅ Data export (backups kui võimalik)

**Pilvepakkuja VASTUTAB:**
- ✅ Kõik! (application, DB, infrastructure, security, uptime)

**Plussid:**
- ✅ Zero maintenance (kõik SaaS provider vastutab)
- ✅ Kiire setup (signup → kasuta kohe)
- ✅ Always up-to-date (automatic updates)
- ✅ Accessible anywhere (web browser)

**Miinused:**
- ❌ Vendor lock-in (andmed SaaS'is)
- ❌ Vähem customization
- ❌ Subscription costs (kasutaja kohta)
- ❌ Internet sõltuv (no offline)

**Kasutusjuhud:**
- Standard tööriistad (email, project management)
- No dedicated IT team
- Focus on business, mitte tech ops'il

**Hinnad (näited):**
```
GitHub Teams: $4/user/month
GitLab Premium: $19/user/month
Datadog Pro: $15/host/month
Jira: $7.75/user/month

VS Self-hosted:
GitLab self-hosted: Free (Community Edition) + EC2 $30/month
Prometheus + Grafana: Free + EC2 $30/month
```

---

### 1.4 CaaS (Containers as a Service)

**Definitsioon:**
Pilvepakkuja pakub **managed container orchestration**:
- Kubernetes managed (EKS, AKS, GKE)
- Container runtime (Docker)
- Auto-scaling
- Load balancing

**Analoogia:**
```
CaaS = Konteinerite parkla (container park)
- Tood oma konteinerid (Docker images)
- Pakkuja haldab orkestreerimist (Kubernetes)
- Sina ei pea master node'e haldama
```

**Näited:**
- **AWS:** EKS (Elastic Kubernetes Service)
- **Azure:** AKS (Azure Kubernetes Service)
- **Google Cloud:** GKE (Google Kubernetes Engine)
- **DigitalOcean:** Kubernetes
- **Linode:** LKE (Linode Kubernetes Engine)

**DevOps administraator VASTUTAB:**
- ✅ Docker image'ite build
- ✅ Kubernetes manifest'ide kirjutamine
- ✅ Application deployment (kubectl apply)
- ✅ Monitoring ja logging setup

**Pilvepakkuja VASTUTAB:**
- ✅ Kubernetes control plane (master nodes)
- ✅ etcd backup
- ✅ Kubernetes version updates
- ✅ Node auto-scaling
- ✅ Load balancer provision

**Plussid:**
- ✅ No Kubernetes master node management
- ✅ Auto-scaling (pod + node level)
- ✅ Integrated monitoring (CloudWatch, Azure Monitor)
- ✅ Managed upgrades (Kubernetes versions)

**Miinused:**
- ❌ Kallim kui self-managed K8s (control plane $0.10/h = $73/month EKS'is)
- ❌ Vendor-specific features (lock-in)
- ❌ Learning curve (Kubernetes + cloud provider)

**Kasutusjuhud:**
- Production Kubernetes (enterprise)
- No Kubernetes admin (focus on apps)
- Multi-region deployments
- High availability critical

**Hinnad (näited):**
```
AWS EKS:
- Control plane: $0.10/h = $73/month
- Worker nodes: EC2 pricing (nt 3x t3.medium = $90/month)
- TOTAL: ~$163/month

VS Self-managed K3s VPS'is:
- VPS 4 vCPU, 8GB RAM: $25/month (DigitalOcean, Linode)
- TOTAL: $25/month
- Aga: sina vastutab K3s haldamise eest!
```

---

### 1.5 FaaS (Function as a Service / Serverless)

**Definitsioon:**
Pilvepakkuja käivitab **funktsioonid** demand'i peale:
- No servers (abstracted away)
- Pay per execution (mitte per hour)
- Auto-scaling (0 → 1000 requests instant)

**Analoogia:**
```
FaaS = Uber/Bolt
- Ei pea autot omama (no server)
- Kasutad ainult kui vajad (per request)
- Maksad ainult sõitude eest (per execution)
```

**Näited:**
- **AWS:** Lambda
- **Azure:** Functions
- **Google Cloud:** Cloud Functions
- **Cloudflare:** Workers
- **Vercel:** Serverless Functions

**DevOps administraator VASTUTAB:**
- ✅ Function code kirjutamine (Node.js, Python, Go)
- ✅ Trigger'ite seadistamine (HTTP, schedule, event)
- ✅ Environment variables

**Pilvepakkuja VASTUTAB:**
- ✅ Kõik infrastruktuur (servers, scaling, patching)

**Plussid:**
- ✅ Zero server management
- ✅ Auto-scaling (instant)
- ✅ Pay per execution (odav low traffic'ile)
- ✅ Fast deployment (upload function → live)

**Miinused:**
- ❌ Cold start (esimene request aeglane)
- ❌ Execution time limit (AWS Lambda 15 min max)
- ❌ Vendor lock-in (Lambda API ≠ Azure Functions API)
- ❌ Debugging keeruline (no server access)

**Kasutusjuhud:**
- Event-driven (S3 upload → Lambda resize image)
- Cron jobs (scheduled functions)
- API endpoints (low traffic)
- Webhooks

**Hinnad (näited):**
```
AWS Lambda:
- First 1M requests/month: FREE
- After: $0.20 per 1M requests
- Compute: $0.0000166667/GB-second

Näide: 100K requests/month, 512MB, 1s average
- Requests: FREE (under 1M)
- Compute: 100,000 × 0.5GB × 1s × $0.0000166667 = $0.83
- TOTAL: ~$1/month

VS EC2 t3.micro (always on):
- $7.50/month (even if no traffic!)
```

---

## 🌍 II. PEAMISED CLOUD PROVIDERS

### 2.1 AWS (Amazon Web Services)

**Ülevaade:**
- Suurim cloud provider (32% market share)
- Founded: 2006
- Headquarters: Seattle, USA
- Regions: 32 (105 Availability Zones)

**Põhiteenused DevOps'ile:**

| Kategooria | Teenus | Kirjeldus |
|------------|--------|-----------|
| **Compute** | EC2 | Virtual machines |
| | Lambda | Serverless functions |
| | ECS/EKS | Container orchestration |
| **Storage** | S3 | Object storage (images, backups) |
| | EBS | Block storage (VM disks) |
| **Database** | RDS | Managed PostgreSQL, MySQL |
| | DynamoDB | NoSQL (serverless) |
| **Networking** | VPC | Virtual Private Cloud |
| | ELB | Load Balancer |
| | Route 53 | DNS |
| **DevOps** | CodePipeline | CI/CD |
| | CloudFormation | Infrastructure as Code |
| | CloudWatch | Monitoring ja logging |

**Plussid:**
- ✅ **Suurim valik teenuseid** (200+ services)
- ✅ **Global reach** (32 regions)
- ✅ **Mature ecosystem** (palju integratsioone)
- ✅ **Documentatsioon** (extensive)
- ✅ **Free tier** (12 months: EC2 t2.micro, RDS db.t2.micro, 5GB S3)

**Miinused:**
- ❌ **Complexity** (200+ services, raske navigeerida)
- ❌ **Pricing** (keeruline kalkuleerida, hidden costs)
- ❌ **Vendor lock-in** (proprietary services like DynamoDB)
- ❌ **Steep learning curve** (palju kontseptsioone)

**Pricing näited:**
```
EC2 t3.medium (2 vCPU, 4GB RAM):
- On-Demand: $0.0416/h = $30.36/month
- Reserved (1 year): $18.25/month
- Spot (variable): ~$12/month

RDS PostgreSQL db.t3.medium (2 vCPU, 4GB RAM):
- Single-AZ: $60/month
- Multi-AZ (HA): $120/month

S3 Storage:
- $0.023/GB/month (first 50TB)
```

**Millal kasutada AWS:**
- Enterprise (Fortune 500 companies)
- Global applications (multi-region)
- Need AWS-specific services (DynamoDB, Redshift)
- Budget on (enterprise pricing)

---

### 2.2 Microsoft Azure

**Ülevaade:**
- Teine suurim (23% market share)
- Founded: 2010
- Headquarters: Redmond, USA
- Regions: 60+

**Põhiteenused DevOps'ile:**

| Kategooria | Teenus | AWS Equivalent |
|------------|--------|----------------|
| **Compute** | Virtual Machines | EC2 |
| | Azure Functions | Lambda |
| | AKS (Kubernetes) | EKS |
| **Storage** | Blob Storage | S3 |
| | Managed Disks | EBS |
| **Database** | Azure SQL Database | RDS |
| | Cosmos DB | DynamoDB |
| **Networking** | Virtual Network | VPC |
| | Load Balancer | ELB |
| **DevOps** | Azure DevOps | CodePipeline |
| | Azure Resource Manager (ARM) | CloudFormation |
| | Azure Monitor | CloudWatch |

**Plussid:**
- ✅ **Microsoft integration** (Active Directory, Office 365, Windows Server)
- ✅ **Hybrid cloud** (Azure Arc, Azure Stack - on-premise integration)
- ✅ **Enterprise-friendly** (licensing deals Microsoft'iga)
- ✅ **Good Windows support** (best for .NET apps)

**Miinused:**
- ❌ **Smaller than AWS** (vähem teenuseid)
- ❌ **Portal UI** (sometimes confusing)
- ❌ **Less mature** (kui AWS, aga kiiresti kasvab)

**Pricing näited:**
```
Azure VM B2s (2 vCPU, 4GB RAM):
- Pay-as-you-go: $60/month
- Reserved (1 year): $36/month

Azure Database for PostgreSQL (2 vCPU, 4GB RAM):
- $80/month (Basic tier)
- $120/month (General Purpose)
```

**Millal kasutada Azure:**
- Microsoft shop (Windows, .NET, Active Directory)
- Hybrid cloud (on-premise + cloud)
- Enterprise agreements Microsoft'iga
- Azure-specific services (Cosmos DB, Azure DevOps)

---

### 2.3 Google Cloud Platform (GCP)

**Ülevaade:**
- Kolmas suurim (10% market share)
- Founded: 2008
- Headquarters: Mountain View, USA
- Regions: 37

**Põhiteenused DevOps'ile:**

| Kategooria | Teenus | AWS Equivalent |
|------------|--------|----------------|
| **Compute** | Compute Engine | EC2 |
| | Cloud Functions | Lambda |
| | GKE (Kubernetes) | EKS |
| **Storage** | Cloud Storage | S3 |
| | Persistent Disk | EBS |
| **Database** | Cloud SQL | RDS |
| | Firestore | DynamoDB |
| **Networking** | VPC | VPC |
| | Cloud Load Balancing | ELB |
| **DevOps** | Cloud Build | CodePipeline |
| | Deployment Manager | CloudFormation |
| | Cloud Logging (Stackdriver) | CloudWatch |

**Plussid:**
- ✅ **Kubernetes** (GKE on parim managed K8s - Google created K8s!)
- ✅ **Data analytics** (BigQuery, Dataflow - Google expertise)
- ✅ **Machine Learning** (Vertex AI, TensorFlow)
- ✅ **Pricing** (sustained use discounts, simpler than AWS)
- ✅ **Live migration** (VMs migreeruvad ilma downtime'ita)

**Miinused:**
- ❌ **Smaller ecosystem** (kui AWS)
- ❌ **Fewer regions** (37 vs AWS 32, Azure 60+)
- ❌ **Enterprise adoption** (väiksem kui AWS/Azure)
- ❌ **Google factor** (mõned kardavad Google cancelling products)

**Pricing näited:**
```
GCE n1-standard-2 (2 vCPU, 7.5GB RAM):
- On-Demand: $48.55/month
- Sustained use (automatic): $34.51/month
- Committed (1 year): $30.22/month

Cloud SQL PostgreSQL (2 vCPU, 7.5GB RAM):
- $90/month
```

**Millal kasutada GCP:**
- Kubernetes-heavy (GKE on parim)
- Data analytics (BigQuery, Dataflow)
- Machine Learning projects
- Google Workspace integration (Gmail, Drive)
- Prefer simple pricing (vs AWS complexity)

---

### 2.4 Oracle Cloud Infrastructure (OCI)

**Ülevaade:**
- Founded: 2016 (uus cloud provider)
- Headquarters: Austin, USA
- Regions: 44
- Focus: Enterprise, databases

**Põhiteenused DevOps'ile:**

| Kategooria | Teenus | AWS Equivalent |
|------------|--------|----------------|
| **Compute** | Compute Instances | EC2 |
| | Container Engine (OKE) | EKS |
| **Storage** | Object Storage | S3 |
| | Block Volume | EBS |
| **Database** | **Autonomous Database** | RDS (aga parem!) |
| | MySQL | RDS MySQL |
| **Networking** | Virtual Cloud Network | VPC |

**Plussid:**
- ✅ **Always Free tier** (permanent, mitte 12 kuud!):
  - 2x VM.Standard.E2.1.Micro (1 vCPU, 1GB RAM each) - ALWAYS FREE!
  - 4x Arm-based Ampere A1 cores + 24GB RAM (flex) - ALWAYS FREE!
  - 200GB Block Storage - ALWAYS FREE!
  - 10GB Object Storage - ALWAYS FREE!

- ✅ **Autonomous Database** (self-tuning, self-patching, self-securing)
- ✅ **Price/performance** (odavam kui AWS/Azure mõnedes kategooriates)
- ✅ **Oracle DB** (best option kui Oracle Database vajad)

**Miinused:**
- ❌ **Väiksem ecosystem** (kui AWS/Azure/GCP)
- ❌ **Less mature** (uuem platform)
- ❌ **Enterprise-focused** (vähem startup-friendly)
- ❌ **Marketing** (vähem tuntud)

**Pricing näited:**
```
VM.Standard.E4.Flex (2 vCPU, 16GB RAM):
- $0.03/h = $21.90/month

Autonomous Database (2 OCPU, 1TB storage):
- $540/month (aga includes patching, tuning, backup!)

ALWAYS FREE (permanent!):
- 2x VM.Standard.E2.1.Micro
- 4x Ampere A1 cores + 24GB RAM (kombineeritav)
- 200GB Block Storage
```

**Millal kasutada Oracle Cloud:**
- Oracle Database workloads (license optimization)
- Testing/development (ALWAYS FREE tier!)
- Cost-conscious (good price/performance)
- Enterprise Oracle customers

---

### 2.5 DigitalOcean

**Ülevaade:**
- Founded: 2011
- Headquarters: New York, USA
- Regions: 15
- Focus: Developers, startups, SMBs

**Põhiteenused DevOps'ile:**

| Kategooria | Teenus | Kirjeldus |
|------------|--------|-----------|
| **Compute** | Droplets | Simple VMs ($4-640/month) |
| | App Platform | PaaS (like Heroku) |
| | Kubernetes | Managed K8s (free control plane!) |
| **Storage** | Spaces | Object storage (S3-compatible) |
| | Volumes | Block storage |
| **Database** | Managed Databases | PostgreSQL, MySQL, Redis, MongoDB |
| **Networking** | Load Balancers | $12/month (fixed!) |
| | Floating IPs | Free |

**Plussid:**
- ✅ **Simplicity** (lihtne UI, beginner-friendly)
- ✅ **Predictable pricing** (flat rates, no hidden costs)
- ✅ **Free K8s control plane** (AWS EKS $73/month!)
- ✅ **Good docs** (tutorials, community)
- ✅ **Developer-focused** (API-first)

**Miinused:**
- ❌ **Fewer features** (kui AWS/Azure/GCP)
- ❌ **Fewer regions** (15 vs AWS 32)
- ❌ **No enterprise features** (limited compliance certifications)
- ❌ **Support** (community-focused, paid support limited)

**Pricing näited:**
```
Droplets:
- Basic: $4/month (1 vCPU, 512MB RAM, 10GB SSD)
- Regular: $12/month (2 vCPU, 2GB RAM, 50GB SSD)
- Premium: $24/month (2 vCPU, 4GB RAM, 80GB SSD)

Managed Kubernetes:
- Control plane: FREE
- Worker nodes: Droplet pricing ($12/month per node)
- 3-node cluster: $36/month (vs EKS $163/month!)

Managed PostgreSQL:
- Basic: $15/month (1 vCPU, 1GB RAM, 10GB storage)
- $60/month (2 vCPU, 4GB RAM, 38GB storage)
```

**Millal kasutada DigitalOcean:**
- Startups (simple, affordable)
- Developers (learning, side projects)
- Kubernetes on budget (free control plane!)
- Prefer simplicity over features

---

### 2.6 Linode (Akamai)

**Ülevaade:**
- Founded: 2003 (üks vanimaid!)
- Acquired by: Akamai (2022)
- Regions: 11
- Focus: Developers, indie hackers

**Põhiteenused DevOps'ile:**

| Kategooria | Teenus | Kirjeldus |
|------------|--------|-----------|
| **Compute** | Linodes | VMs ($5-960/month) |
| | LKE | Managed Kubernetes |
| **Storage** | Object Storage | S3-compatible |
| | Block Storage | $0.10/GB/month |
| **Database** | Managed Databases | PostgreSQL, MySQL |

**Plussid:**
- ✅ **Price/performance** (hea value for money)
- ✅ **Simplicity** (lihtne, nagu DigitalOcean)
- ✅ **Free K8s control plane**
- ✅ **Long track record** (20+ years)
- ✅ **Good support** (24/7)

**Miinused:**
- ❌ **Fewer features** (basic IaaS)
- ❌ **Fewer regions** (11)
- ❌ **Less known** (kui DigitalOcean)

**Pricing näited:**
```
Linodes (Shared):
- Nanode: $5/month (1 vCPU, 1GB RAM, 25GB SSD)
- $10/month (1 vCPU, 2GB RAM, 50GB SSD)
- $20/month (2 vCPU, 4GB RAM, 80GB SSD)

Managed Kubernetes (LKE):
- Control plane: FREE
- Worker nodes: Linode pricing

Managed PostgreSQL:
- $60/month (2 vCPU, 4GB RAM, 80GB storage)
```

**Millal kasutada Linode:**
- Similar to DigitalOcean (simple, affordable)
- Good support needed (24/7)
- Price-conscious

---

### 2.7 Hetzner

**Ülevaade:**
- Founded: 1997 (German company)
- Headquarters: Germany
- Regions: 3 (Germany, Finland, USA)
- Focus: Price/performance champion

**Põhiteenused:**

| Kategooria | Teenus | Kirjeldus |
|------------|--------|-----------|
| **Compute** | Cloud Servers | VMs (€3.79-€290/month) |
| **Storage** | Volumes | Block storage (€0.04/GB) |
| | Object Storage | Coming soon |
| **Networking** | Load Balancers | €5.46/month |

**Plussid:**
- ✅ **HIND!** (odavaim suurtest provider'itest)
  - €4.51/month (2 vCPU, 4GB RAM, 40GB SSD)
  - vs DigitalOcean $24/month (2 vCPU, 4GB RAM, 80GB SSD)
  - vs AWS EC2 $30/month (2 vCPU, 4GB RAM)

- ✅ **Performance** (good hardware, AMD EPYC)
- ✅ **Network** (20TB bandwidth included!)
- ✅ **Green energy** (100% renewable energy)

**Miinused:**
- ❌ **Fewer regions** (3: Germany, Finland, USA)
- ❌ **No managed services** (ei ole RDS, ei ole managed K8s)
- ❌ **Support** (slower kui enterprise providers)
- ❌ **GDPR focus** (Europe-focused, USA region uus)

**Pricing näited:**
```
Cloud Servers (VMs):
- CX21: €4.51/month (2 vCPU, 4GB RAM, 40GB SSD, 20TB traffic)
- CX31: €8.21/month (2 vCPU, 8GB RAM, 80GB SSD, 20TB traffic)
- CX41: €15.30/month (4 vCPU, 16GB RAM, 160GB SSD, 20TB traffic)

Load Balancer:
- €5.46/month (vs AWS ELB $16-22/month)

Block Storage:
- €0.04/GB/month (vs AWS EBS €0.10/GB/month)
```

**Millal kasutada Hetzner:**
- Budget-conscious (best price/performance)
- Europe (GDPR compliance)
- Self-managed (no need managed services)
- High bandwidth needs (20TB included!)

---

## 📊 III. CLOUD PROVIDERS VÕRDLUS

### 3.1 Võrdlustabel (Peamised Providers)

| Aspekt | AWS | Azure | GCP | Oracle | DigitalOcean | Linode | Hetzner |
|--------|-----|-------|-----|--------|--------------|--------|---------|
| **Market Share** | 32% | 23% | 10% | 2% | <1% | <1% | <1% |
| **Founded** | 2006 | 2010 | 2008 | 2016 | 2011 | 2003 | 1997 |
| **Regions** | 32 | 60+ | 37 | 44 | 15 | 11 | 3 |
| **Complexity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐ |
| **Pricing** | $$$ | $$$ | $$ | $$ | $ | $ | $ |
| **Free Tier** | 12 months | 12 months | $300 credit | Always Free! | $200 credit | $100 credit | € - |
| **Managed K8s** | EKS ($73/mo) | AKS ($73/mo) | GKE ($73/mo) | OKE | FREE | FREE | No |
| **Best For** | Enterprise | Microsoft shops | K8s, ML, Data | Oracle DB | Startups | Devs | Budget |

**Hind võrdlus: 2 vCPU, 4GB RAM VM**

| Provider | Service | Price/Month | Notes |
|----------|---------|-------------|-------|
| **AWS** | EC2 t3.medium | $30 | On-Demand |
| **Azure** | B2s | $36 | Pay-as-you-go |
| **GCP** | n1-standard-2 | $34 | Sustained use discount |
| **Oracle** | VM.Standard.E4.Flex | $22 | Flex pricing |
| **DigitalOcean** | Droplet Regular | $24 | 80GB SSD |
| **Linode** | Shared | $20 | 80GB SSD |
| **Hetzner** | CX21 | **$5** | 40GB SSD, 20TB traffic |

**Võitja: Hetzner** (4-6x odavam!)

---

### 3.2 Kasutusjuhud Provider'ite Kaupa

#### Millal AWS:
- ✅ Enterprise (Fortune 500)
- ✅ Global scale (multi-region)
- ✅ Comprehensive features (200+ services)
- ✅ AWS-specific (DynamoDB, Redshift, SageMaker)
- ❌ Budget on (expensive)

#### Millal Azure:
- ✅ Microsoft shops (.NET, Windows, Active Directory)
- ✅ Hybrid cloud (on-premise + cloud)
- ✅ Enterprise Microsoft agreements
- ❌ Linux-centric workloads (AWS/GCP parem)

#### Millal GCP:
- ✅ Kubernetes-heavy (GKE on parim)
- ✅ Data analytics (BigQuery)
- ✅ Machine Learning (TensorFlow, Vertex AI)
- ✅ Google integration (Workspace)
- ❌ Windows workloads (Azure parem)

#### Millal Oracle Cloud:
- ✅ Oracle Database (license optimization)
- ✅ Testing/dev (ALWAYS FREE tier!)
- ✅ Enterprise Oracle customers
- ❌ Startup (vähem startup-friendly)

#### Millal DigitalOcean:
- ✅ Startups (simple, affordable)
- ✅ Developers (learning, side projects)
- ✅ Kubernetes budget (free control plane!)
- ❌ Enterprise compliance needs

#### Millal Linode:
- ✅ Similar to DigitalOcean (simple, affordable)
- ✅ Good support needed (24/7)
- ❌ Advanced features

#### Millal Hetzner:
- ✅ Budget-first (best price/performance)
- ✅ Europe/GDPR
- ✅ Self-managed (no managed services)
- ❌ Global reach (ainult 3 regions)

---

### 3.3 VPS (kirjakast) vs Cloud

**Meie kirjakast VPS (Hostinger):**
```
Specs: 2 vCPU, 7.8GB RAM, 96GB SSD
Price: $11.99/month
Location: Fixed (üks datacenter)
Management: Self-managed (me haldame kõike)
```

**Cloud equivalent:**

| Provider | Specs | Price/Month | Erinevus |
|----------|-------|-------------|----------|
| **AWS EC2** | 2 vCPU, 4GB RAM | $30 | 2.5x kallim, vähem RAM |
| **Hetzner** | 2 vCPU, 8GB RAM | $5 | **2x odavam!** |
| **DigitalOcean** | 2 vCPU, 4GB RAM | $24 | 2x kallim, vähem RAM |

**VPS Plussid:**
- ✅ Odavam fixed price
- ✅ Predictable billing (no surprises)
- ✅ Full root access
- ✅ No vendor lock-in

**VPS Miinused:**
- ❌ No auto-scaling
- ❌ No managed services (RDS, managed K8s)
- ❌ Fixed location (ei saa multi-region)
- ❌ Manual failover

**Cloud Plussid:**
- ✅ Auto-scaling (traffic spike → auto add instances)
- ✅ Managed services (RDS, S3, managed K8s)
- ✅ Multi-region (global reach)
- ✅ Snapshots, backups (automated)

**Cloud Miinused:**
- ❌ Kallim
- ❌ Keeruline pricing (hidden costs!)
- ❌ Vendor lock-in (proprietary APIs)

---

## 🎯 IV. SOOVITUSED DEVOPS ADMINISTRAATORILE

### 4.1 Learning Path

**1. Alusta VPS'iga** (nagu meie kirjakast):
- Learn Linux, Docker, Kubernetes basics
- Full control, no complexity
- Cheap ($12/month)

**2. Lisa Cloud Skills:**
- AWS/Azure/GCP free tier
- Learn cloud-specific tools (S3, RDS, IAM)
- Understand pricing models

**3. Spetsialiseeру:**
- Choose 1-2 providers (nt AWS + DigitalOcean)
- Deep dive (certifications: AWS SAA, CKA)
- Multi-cloud strategy (avoid lock-in)

---

### 4.2 Certification Path

**Entry Level:**
- ✅ AWS Certified Cloud Practitioner (CLF-C02)
- ✅ Azure Fundamentals (AZ-900)
- ✅ Google Cloud Digital Leader

**Intermediate (DevOps):**
- ✅ AWS Certified Solutions Architect - Associate (SAA-C03)
- ✅ Azure Administrator (AZ-104)
- ✅ Google Cloud Associate Cloud Engineer

**Advanced (Kubernetes):**
- ✅ CKA (Certified Kubernetes Administrator)
- ✅ CKAD (Certified Kubernetes Application Developer)
- ✅ CKS (Certified Kubernetes Security Specialist)

---

### 4.3 Cost Optimization Tips

**1. Reserved Instances (AWS, Azure):**
- Save 30-70% (1-3 year commitment)
- Use for predictable workloads (databases, baseline compute)

**2. Spot Instances (AWS, Azure, GCP):**
- Save up to 90%!
- Use for fault-tolerant workloads (batch processing, CI/CD runners)

**3. Auto-scaling:**
- Scale down nights/weekends
- Dev environments → turn off when not used

**4. Right-sizing:**
- Monitor utilization (CPU, RAM)
- Downsize underutilized instances
- Use burstable instances (t3, t4g)

**5. Storage optimization:**
- Lifecycle policies (S3 → Glacier after 90 days)
- Delete old snapshots
- Use cheaper storage classes

**6. Multi-cloud pricing arbitrage:**
- Compare providers for each service
- Hetzner compute + AWS S3 (if Hetzner cheaper for compute)

---

## 📚 V. VIITED JA RESSURSID

**Official Docs:**
- AWS: https://docs.aws.amazon.com/
- Azure: https://learn.microsoft.com/azure/
- GCP: https://cloud.google.com/docs
- Oracle Cloud: https://docs.oracle.com/cloud/
- DigitalOcean: https://docs.digitalocean.com/
- Linode: https://www.linode.com/docs/
- Hetzner: https://docs.hetzner.com/

**Pricing Calculators:**
- AWS: https://calculator.aws/
- Azure: https://azure.microsoft.com/pricing/calculator/
- GCP: https://cloud.google.com/products/calculator
- DigitalOcean: https://www.digitalocean.com/pricing/calculator

**Free Tiers:**
- AWS Free Tier: https://aws.amazon.com/free/
- Azure Free: https://azure.microsoft.com/free/
- GCP Free Tier: https://cloud.google.com/free
- Oracle Always Free: https://www.oracle.com/cloud/free/

**Learning Platforms:**
- AWS Skill Builder: https://skillbuilder.aws/
- Microsoft Learn: https://learn.microsoft.com/training/
- Google Cloud Skills Boost: https://www.cloudskillsboost.google/
- A Cloud Guru: https://acloudguru.com/

---

## ✅ KOKKUVÕTE

### Põhiteadmised DevOps Administraatorile:

**Cloud Models:**
- ✅ **IaaS:** VM'id, full control (VPS, EC2, Azure VM)
- ✅ **PaaS:** Managed platform (Heroku, App Engine, RDS)
- ✅ **SaaS:** Ready software (GitHub, Jira, Gmail)
- ✅ **CaaS:** Managed containers (EKS, AKS, GKE)
- ✅ **FaaS:** Serverless functions (Lambda, Cloud Functions)

**Top Providers:**
- ✅ **AWS:** Enterprise, comprehensive (32% market share)
- ✅ **Azure:** Microsoft shops (23% market share)
- ✅ **GCP:** Kubernetes, data, ML (10% market share)
- ✅ **Oracle:** Database, always free tier
- ✅ **DigitalOcean:** Startups, simplicity
- ✅ **Linode:** Developers, good support
- ✅ **Hetzner:** Budget champion, Europe

**Soovitus:**
- 🎓 **Learn:** Start VPS (kirjakast) → add cloud skills (AWS free tier)
- 🎯 **Specialize:** Choose 1-2 providers (AWS + DigitalOcean popular combo)
- 📜 **Certify:** AWS SAA + CKA (Kubernetes)
- 💰 **Optimize:** Right-size, auto-scale, reserved instances, multi-cloud arbitrage

---

**Edu cloud learning'ul! ☁️**

*Cloud on tulevik, aga VPS on suurepärane õppimise algus!*
