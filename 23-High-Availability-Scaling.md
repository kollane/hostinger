# Peatükk 23: High Availability ja Scaling

**Kestus:** 4 tundi
**Eeldused:** Peatükk 9-14 (Kubernetes core + advanced)
**Eesmärk:** Mõista HA arhitektuuri ja scaling strategies trade-offs

---

## Õpieesmärgid

- HA fundamentals (miks downtime on kallis?)
- Redundancy patterns (no single point of failure)
- Vertical vs horizontal scaling (millal kasutada?)
- Auto-scaling decision making (HPA, VPA, Cluster Autoscaler)
- Load balancing strategies
- Multi-zone ja multi-region architectures
- Cost vs availability trade-offs

---

## 23.1 High Availability Fundamentals

### Miks HA on Oluline?

**Downtime cost calculation:**

```
E-commerce site:
  - Revenue: $1M/day
  - Downtime: 1 hour
  - Cost: $1M / 24h = $41,666 lost!

SaaS B2B:
  - Annual contracts: $100K/client
  - SLA: 99.9% uptime
  - Actual uptime: 99.0%
  - Penalty: 25% refund = $25K lost per client!

Reputation damage:
  - Downtime → users leave → competitors win
  - Cost: Immeasurable (long-term impact)
```

**HA goal:** Minimize downtime (maximize availability).

---

### Availability Metrics

**Uptime percentage:**

```
99% uptime:
  - Downtime per year: 3.65 days
  - Acceptable? NO (e-commerce loses $150K!)

99.9% ("three nines"):
  - Downtime per year: 8.76 hours
  - Acceptable? Maybe (small outages)

99.99% ("four nines"):
  - Downtime per year: 52.56 minutes
  - Acceptable? Yes (most SaaS targets)

99.999% ("five nines"):
  - Downtime per year: 5.26 minutes
  - Achievable? Difficult (expensive!)
```

**SLA vs SLO:**

```
SLA (Service Level Agreement): Contract with customer
  - "We guarantee 99.9% uptime, or 10% refund"

SLO (Service Level Objective): Internal target
  - "We target 99.95% uptime (buffer above SLA)"

Reason: SLO > SLA gives buffer (avoid SLA penalties)
```

---

### Single Point of Failure (SPOF)

**SPOF = Component failure → entire system down**

**Example 1: Single Pod**

```
Architecture:
  User → Backend Pod (1 replica)

Failure scenario:
  - Pod crashes → service DOWN
  - Node fails → service DOWN
  - Deployment update → service DOWN

Downtime: Until Pod restarts (1-2 min)

Fix: Multiple replicas (redundancy)
```

---

**Example 2: Single Database**

```
Architecture:
  App → Database (single instance)

Failure scenario:
  - Database crashes → App cannot read/write
  - Disk full → Database stops
  - Node failure → Database down

Downtime: Until DB restarts + data restored (10-60 min)

Fix: Database replication (primary + replicas)
```

---

**Example 3: Single Availability Zone**

```
Architecture:
  All nodes in one datacenter (AZ-1)

Failure scenario:
  - AZ-1 power outage → entire cluster DOWN
  - AZ-1 network issue → cluster unreachable

Downtime: Until AZ-1 recovers (hours!)

Fix: Multi-AZ deployment (nodes in AZ-1, AZ-2, AZ-3)
```

---

### Redundancy Patterns

**Active-Passive (failover):**

```
Architecture:
  - Primary database (active, serving traffic)
  - Replica database (passive, standby)

Normal operation:
  App → Primary DB (read/write)

Failure scenario:
  Primary DB fails → failover to Replica
  App → Replica DB (promoted to primary)

Downtime: Failover time (30-60 seconds)

Benefit: Cost-effective (1 active instance)
Drawback: Failover delay (brief downtime)
```

---

**Active-Active (load balancing):**

```
Architecture:
  - Backend Pod 1 (active)
  - Backend Pod 2 (active)
  - Backend Pod 3 (active)

Normal operation:
  Load Balancer → distributes traffic to all Pods

Failure scenario:
  Pod 1 fails → Load Balancer routes to Pod 2, Pod 3

Downtime: ZERO (other Pods handle traffic)

Benefit: Zero downtime (high availability)
Drawback: More expensive (N active instances)
```

**Kubernetes default:** Active-Active (Deployment with N replicas)

---

## 23.2 Scaling Strategies

### Vertical vs Horizontal Scaling

**Vertical Scaling (scale UP):**

```
Increase Pod resources:

Before:
  - 1 Pod: 1 CPU, 2GB RAM

After:
  - 1 Pod: 4 CPU, 8GB RAM (4x resources)

When to use:
  ✅ Application NOT horizontally scalable (e.g., single-thread)
  ✅ Stateful applications (database)
  ✅ Quick fix (increase resources temporarily)

Limits:
  ❌ Maximum node size (can't scale beyond largest node)
  ❌ Downtime required (restart Pod with new resources)
  ❌ SPOF (still 1 Pod, crash = downtime)
```

---

**Horizontal Scaling (scale OUT):**

```
Increase Pod count:

Before:
  - 1 Pod: 1 CPU, 2GB RAM

After:
  - 10 Pods: 1 CPU, 2GB RAM each (10x capacity)

When to use:
  ✅ Stateless applications (web servers, APIs)
  ✅ High availability (multiple Pods = redundancy)
  ✅ Load distribution (spread across nodes)

Limits:
  ❌ Application must support horizontal scaling
  ❌ State management complex (shared sessions)
  ❌ More Pods = more complexity (orchestration)
```

**Kubernetes default:** Horizontal scaling (Deployment replicas)

---

### When Scaling Helps vs Doesn't Help

**Scaling helps:**

```
Problem: High CPU usage (100%)
  - Backend Pod: 1 CPU, 100% usage
  - Request latency: 2s (slow!)

Solution: Horizontal scaling
  - 10 Pods: 1 CPU each, 10% usage
  - Load distributed → latency: 200ms ✅

Reason: More Pods = more CPU capacity
```

---

**Scaling DOESN'T help:**

```
Problem: Slow database query (5s)
  - Backend Pod calls DB → 5s response time
  - User experience: Slow!

Scaling backend to 100 Pods:
  - 100 Pods still wait 5s for DB response
  - User experience: STILL slow! ❌

Reason: Bottleneck is DATABASE (not backend Pods)

Fix: Optimize query, add index, scale DATABASE
```

**Lesson:** Scaling helps with CPU/memory-bound issues, NOT downstream dependencies.

---

## 23.3 Horizontal Pod Autoscaler (HPA)

### HPA Concept

**HPA = Automatically adjust Pod replicas based on metrics**

```
Architecture:
  1. HPA monitors metric (CPU usage, memory, custom)
  2. If metric > threshold → increase replicas
  3. If metric < threshold → decrease replicas

Example:
  Target: 50% CPU usage
  Current: 80% CPU usage → scale UP (add Pods)
  Current: 20% CPU usage → scale DOWN (remove Pods)
```

---

### When HPA is Useful

**Use case: Traffic spikes**

```
E-commerce site:
  - Normal traffic: 100 req/s (2 Pods enough)
  - Black Friday: 10,000 req/s (200 Pods needed!)

Without HPA:
  - 2 Pods → overloaded → slow/downtime

With HPA:
  - Detects high CPU → scales to 200 Pods
  - Black Friday handled ✅
  - After spike → scales down to 2 Pods (save cost)

Benefit: Automatic capacity adjustment
```

---

### When HPA is NOT Useful

**Use case: Steady, predictable load**

```
Internal tool:
  - Users: 50 employees (9am-5pm)
  - Traffic: Constant 10 req/s

With HPA:
  - Constantly adjusts replicas (2 → 3 → 2 → 3)
  - Unnecessary churn (Pod restarts)

Better: Static replicas (set 3 Pods, never changes)

Reason: HPA overhead not worth it for predictable load
```

---

### HPA Configuration Considerations

**Metric selection:**

```
CPU-based (default):
  - Simple, works for most apps
  - Limitation: Doesn't account for request queue length

Memory-based:
  - Use if app is memory-intensive (caching)
  - Limitation: Memory doesn't drop quickly (slow scale-down)

Custom metrics (advanced):
  - Example: Request queue length, Kafka lag
  - Benefit: More accurate scaling decisions
  - Cost: Complexity (need custom metrics)
```

---

**Scale-up vs scale-down timing:**

```
Problem: Rapid scaling causes instability

Example:
  - Traffic spike → scale to 100 Pods (fast!)
  - Traffic drops → scale to 2 Pods (fast!)
  - Traffic spike again → scale to 100 Pods
  - Result: Constant Pod churn (startup/shutdown overhead)

Solution: Asymmetric timing
  - Scale-up: Fast (30s delay - handle spike quickly)
  - Scale-down: Slow (5 min delay - avoid flapping)

Reason: Better to have extra capacity than insufficient capacity
```

---

## 23.4 Cluster Autoscaler

### Cluster Autoscaler vs HPA

**HPA:** Adjusts Pod count (within existing nodes)
**Cluster Autoscaler:** Adjusts Node count (adds/removes nodes)

```
Scenario: HPA scales Pods from 10 → 100

Problem:
  - Cluster has 5 nodes (20 Pods capacity)
  - HPA wants 100 Pods → 80 Pods pending (not enough nodes!)

Solution: Cluster Autoscaler
  - Detects pending Pods
  - Adds 4 nodes (now 9 nodes, 180 Pods capacity)
  - HPA scales to 100 Pods ✅
```

---

### When Cluster Autoscaler is Needed

**Use case: Unpredictable workload**

```
ML training jobs:
  - Job 1: 5 GPUs needed (normal day)
  - Job 2: 50 GPUs needed (large model)

Without Cluster Autoscaler:
  - Cluster: 10 GPU nodes (always running)
  - Cost: $1,000/day (even when idle!)

With Cluster Autoscaler:
  - Normal: 5 GPU nodes ($500/day)
  - Large job: Scales to 50 GPU nodes ($5,000/day, temporary)
  - After job: Scales down to 5 nodes ($500/day)

Benefit: Pay for what you use (cost savings)
```

---

### Cluster Autoscaler Limitations

**Scale-up delay:**

```
Timeline:
  1. HPA requests 100 Pods (t=0)
  2. 80 Pods pending (no capacity)
  3. Cluster Autoscaler adds 4 nodes (t=2min - cloud API)
  4. Nodes boot, join cluster (t=5min - node startup)
  5. Pods scheduled (t=6min)

Total delay: 6 minutes (traffic spike missed!)

Mitigation: Over-provision (keep spare capacity)
```

---

**Scale-down safety:**

```
Problem: Cluster Autoscaler removes node → Pods evicted

Risk:
  - Node runs critical Pod (single replica)
  - Node removed → Pod down → service DOWN

Mitigation:
  - Pod Disruption Budget (prevent unsafe evictions)
  - Pod anti-affinity (spread replicas across nodes)
```

---

## 23.5 Multi-Zone and Multi-Region

### Availability Zone (AZ) Failures

**Single-AZ deployment:**

```
Architecture:
  - All nodes in AZ-1 (one datacenter)

Risk:
  - AZ-1 power outage → entire cluster DOWN
  - Probability: ~0.1% per year (rare, but happens!)

Cost of failure:
  - E-commerce: $1M revenue lost (24h downtime)
```

---

**Multi-AZ deployment:**

```
Architecture:
  - Nodes in AZ-1, AZ-2, AZ-3 (3 datacenters)
  - Pods spread across AZs (Pod anti-affinity)

Normal operation:
  - AZ-1: 10 Pods
  - AZ-2: 10 Pods
  - AZ-3: 10 Pods

Failure scenario:
  - AZ-1 fails → 10 Pods down
  - AZ-2, AZ-3 handle traffic (20 Pods remaining)
  - Downtime: ZERO ✅

Cost:
  - Network latency (cross-AZ traffic slower)
  - Data transfer fees (cross-AZ traffic costs)

Trade-off: Higher availability vs higher cost
```

---

### Multi-Region Deployment

**When to use multi-region?**

```
Use cases:
  1. Disaster recovery (AZ failure is regional outage)
  2. Global user base (latency reduction)
  3. Compliance (data residency requirements)

Example:
  - Primary region: US-East (serves US users)
  - Secondary region: EU-West (serves EU users)

Failure scenario:
  - US-East region fails → failover to EU-West
  - US users routed to EU-West (higher latency, but available!)
```

---

**Multi-region challenges:**

```
Challenge 1: Data synchronization
  - Database in US-East
  - How to keep EU-West database in sync?
  - Options: Async replication (eventual consistency)

Challenge 2: Routing
  - How to route users to nearest region?
  - Options: GeoDNS, CDN

Challenge 3: Cost
  - 2 regions = 2x infrastructure cost
  - Cross-region data transfer (expensive!)

Recommendation: Start single-region → add multi-region if needed
```

---

## 23.6 Load Balancing

### Load Balancer Types

**Layer 4 (TCP/UDP):**

```
Decision: Based on IP address + port

Example:
  - Request to 10.0.0.1:80 → Backend Pod 1
  - Request to 10.0.0.1:80 → Backend Pod 2 (round-robin)

Benefit: Fast (no packet inspection)
Drawback: No content-based routing (can't route based on URL)
```

---

**Layer 7 (HTTP/HTTPS):**

```
Decision: Based on URL, headers, cookies

Example:
  - Request to /api → Backend Pod
  - Request to /images → CDN
  - Request with header "Beta: true" → Canary Pod

Benefit: Intelligent routing (content-aware)
Drawback: Slower (packet inspection overhead)
```

**Kubernetes:** Service (Layer 4), Ingress (Layer 7)

---

### Load Balancing Algorithms

**Round-robin (default):**

```
Requests distributed evenly:
  - Request 1 → Pod 1
  - Request 2 → Pod 2
  - Request 3 → Pod 3
  - Request 4 → Pod 1 (cycle repeats)

When to use: All Pods equal capacity

Limitation: Doesn't account for Pod load (slow Pod gets same traffic)
```

---

**Least connections:**

```
Requests sent to Pod with fewest active connections:
  - Pod 1: 10 connections
  - Pod 2: 5 connections
  - Pod 3: 2 connections
  → New request → Pod 3 (least loaded)

When to use: Long-lived connections (WebSocket, gRPC)

Benefit: Avoid overloading slow Pods
```

---

**Weighted:**

```
Assign weights to Pods:
  - Pod 1: weight 3 (receives 60% traffic)
  - Pod 2: weight 2 (receives 40% traffic)

When to use: Canary deployments (gradual rollout)

Example:
  - Stable version: 90% traffic
  - Canary version: 10% traffic (test new version)
```

---

## 23.7 Cost vs Availability Trade-offs

### Over-Provisioning

**Under-provisioned (❌ Risky):**

```
Normal load: 10 Pods (100% capacity)
Spike: 15 Pods needed → 10 Pods available
Result: Overloaded → slow/downtime

Cost: Low (minimal resources)
Risk: High (no buffer for spikes)
```

---

**Over-provisioned (✅ Safe):**

```
Normal load: 10 Pods needed
Provisioned: 15 Pods (150% capacity)
Spike: 15 Pods needed → 15 Pods available
Result: No slowdown ✅

Cost: High (50% unused resources)
Risk: Low (buffer for spikes)
```

---

**Right-sized (⚖️ Balanced):**

```
Normal load: 10 Pods
Provisioned: 12 Pods (120% capacity)
Spike: 15 Pods → HPA scales to 15 (2 min delay)

Cost: Medium (20% buffer)
Risk: Medium (brief slowdown during scale-up)
```

**Recommendation:** 20-30% over-provisioning (balance cost vs availability)

---

### Multi-AZ Cost Analysis

**Single-AZ:**

```
Nodes: 3 nodes × $100/month = $300/month
Availability: 99% (AZ failure = downtime)
```

**Multi-AZ (3 AZs):**

```
Nodes: 9 nodes × $100/month = $900/month (3x cost!)
Cross-AZ traffic: $50/month
Total: $950/month

Availability: 99.99% (survives single AZ failure)

Trade-off: 3x cost for 0.99% availability improvement
```

**Decision:** Worth it if downtime cost > 3x infrastructure cost

---

## Kokkuvõte

**High Availability:**
- **Goal:** Minimize downtime (99.9% = 8.76h/year, 99.99% = 52 min/year)
- **SPOF:** Eliminate single points of failure (redundancy)
- **Patterns:** Active-Passive (failover), Active-Active (load balancing)

**Scaling:**
- **Vertical:** Increase Pod resources (CPU, RAM) - limited by node size
- **Horizontal:** Increase Pod count - preferred for stateless apps
- **When scaling helps:** CPU/memory bottlenecks
- **When scaling doesn't help:** Downstream dependencies (slow DB)

**Autoscaling:**
- **HPA:** Adjusts Pod count based on metrics (CPU, memory, custom)
- **Cluster Autoscaler:** Adjusts Node count (adds/removes nodes)
- **Use case:** Unpredictable traffic (cost savings)
- **Limitation:** Scale-up delay (minutes), not instant

**Multi-AZ/Region:**
- **Multi-AZ:** Survive datacenter failure (higher cost, lower latency)
- **Multi-region:** Global availability, DR, compliance (expensive, complex)
- **Trade-off:** Availability vs cost (2-3x infrastructure cost)

**Load Balancing:**
- **Layer 4:** TCP/UDP (fast, no content inspection)
- **Layer 7:** HTTP (slow, intelligent routing)
- **Algorithms:** Round-robin (default), least connections, weighted

**Cost vs Availability:**
- **Under-provisioned:** Low cost, high risk (no buffer)
- **Over-provisioned:** High cost, low risk (large buffer)
- **Right-sized:** 20-30% buffer (balanced)

---

**DevOps Vaatenurk:**

HA decisions are BUSINESS decisions:
- What is cost of 1 hour downtime? ($10K? $100K? $1M?)
- Is 99.9% enough, or need 99.99%? (SLA requirement)
- Multi-AZ worth 3x cost? (calculate break-even)
- Auto-scaling worth complexity? (predictable vs unpredictable load)

No one-size-fits-all:
- Startup MVP: Single-AZ, manual scaling (cost-conscious)
- Enterprise SaaS: Multi-AZ, autoscaling (availability-focused)
- E-commerce: Multi-region, over-provisioned (revenue protection)

---

**Järgmised Sammud:**
**Peatükk 24:** Backup ja Disaster Recovery
**Peatükk 25:** Troubleshooting ja Debugging

📖 **Praktika:** Labor 4, Harjutus 3 - HPA setup, multi-replica Deployments, Pod anti-affinity
