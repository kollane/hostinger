# Peatükk 24: Backup ja Disaster Recovery

**Kestus:** 3 tundi
**Eeldused:** Peatükk 13 (Persistent Storage), Peatükk 23 (High Availability)
**Eesmärk:** Mõista backup strategies ja DR planning fundamentals

---

## Õpieesmärgid

- Backup vs High Availability (erinevus)
- RTO ja RPO concepts (recovery targets)
- Backup strategies (full, incremental, differential)
- State backup (database, volumes, configuration)
- Disaster recovery planning
- Testing backups (restoration validation)
- Cost vs protection trade-offs

---

## 24.1 Backup vs High Availability

### Miks HA EI asenda backups?

**HA protects against:** Infrastructure failures

```
Scenario 1: Node fails
  - HA solution: Pod reschedules to another node
  - Downtime: Seconds (automatic)
  - Data: Safe ✅

Scenario 2: AZ fails
  - HA solution: Traffic routes to other AZs
  - Downtime: None (multi-AZ deployment)
  - Data: Safe ✅
```

**Backups protect against:** Data loss, corruption, human error

```
Scenario 3: Developer accidentally deletes production database
  - HA solution: Replicas also deleted (replication is fast!)
  - Data: LOST ❌
  - Recovery: Restore from backup

Scenario 4: Ransomware encrypts database
  - HA solution: Replicas also encrypted
  - Data: Corrupted ❌
  - Recovery: Restore from backup (before encryption)

Scenario 5: Bug writes corrupted data
  - HA solution: Corruption replicated to all replicas
  - Data: Corrupted across all instances ❌
  - Recovery: Restore from backup (before bug deployed)
```

**Conclusion:** HA ≠ Backup. Both needed!

---

## 24.2 RTO ja RPO

### Recovery Time Objective (RTO)

**RTO = Maximum acceptable downtime**

```
Business question: "How long can we be offline?"

E-commerce:
  - RTO: 1 hour (revenue lost after 1h downtime)
  - Backup strategy: Fast restore (warm standby)

Internal tool:
  - RTO: 24 hours (employees can wait)
  - Backup strategy: Slow restore (cold backup)
```

**RTO impacts backup design:**

```
RTO 1 hour:
  - Need: Automated restore, warm standby
  - Cost: High (continuous replication)

RTO 24 hours:
  - Need: Manual restore acceptable
  - Cost: Low (nightly backups)
```

---

### Recovery Point Objective (RPO)

**RPO = Maximum acceptable data loss**

```
Business question: "How much data can we lose?"

Financial transactions:
  - RPO: 0 minutes (ZERO data loss acceptable!)
  - Backup strategy: Continuous replication, WAL archiving

Blog posts:
  - RPO: 24 hours (losing 1 day of posts acceptable)
  - Backup strategy: Daily backups
```

**RPO impacts backup frequency:**

```
RPO 0 (zero data loss):
  - Backup: Continuous (every transaction)
  - Cost: Very high (storage, bandwidth)

RPO 1 hour:
  - Backup: Hourly snapshots
  - Cost: Medium

RPO 24 hours:
  - Backup: Daily backups
  - Cost: Low
```

---

### RTO/RPO Cost Curve

```
RTO/RPO → 0 (instant recovery, zero loss)
  Cost: EXPONENTIAL ↑↑↑

Example:
  - RPO 24h: $10/month (daily backup)
  - RPO 1h: $50/month (hourly snapshots)
  - RPO 5min: $500/month (continuous replication)
  - RPO 0: $5,000/month (synchronous replication)
```

**Decision:** Balance cost vs risk

```
Critical system (payment processing):
  - RTO: 1h, RPO: 0 → Worth $5K/month (revenue protection)

Non-critical (internal wiki):
  - RTO: 24h, RPO: 24h → $10/month sufficient
```

---

## 24.3 Backup Strategies

### Full vs Incremental vs Differential

**Full Backup:**

```
Process: Copy ALL data

Pros:
  - ✅ Fast restore (single file)
  - ✅ Simple (no dependencies)

Cons:
  - ❌ Slow backup (copy everything)
  - ❌ Large storage (TB of data)

When to use: Small datasets, infrequent backups
```

---

**Incremental Backup:**

```
Process:
  - Day 1: Full backup (100GB)
  - Day 2: Incremental (only changes since Day 1, 5GB)
  - Day 3: Incremental (only changes since Day 2, 5GB)

Pros:
  - ✅ Fast backup (small deltas)
  - ✅ Minimal storage (only changes)

Cons:
  - ❌ Slow restore (need Day 1 + Day 2 + Day 3)
  - ❌ Fragile (if Day 2 corrupted → can't restore Day 3)

When to use: Large datasets, frequent backups
```

---

**Differential Backup:**

```
Process:
  - Day 1: Full backup (100GB)
  - Day 2: Differential (changes since Day 1, 5GB)
  - Day 3: Differential (changes since Day 1, 10GB)

Pros:
  - ✅ Faster restore than incremental (Day 1 + Day 3)
  - ✅ Less fragile (only depends on last full backup)

Cons:
  - ❌ Larger backups than incremental (Day 3 = 10GB vs 5GB)

When to use: Balance between full and incremental
```

---

### 3-2-1 Backup Rule

**Rule:** 3 copies, 2 different media, 1 offsite

```
3 copies:
  - Original data (production)
  - Backup copy 1 (local disk)
  - Backup copy 2 (cloud storage)

2 different media:
  - Disk (fast restore)
  - Cloud (disaster recovery)

1 offsite:
  - Cloud storage in different region
  - Protection: Datacenter fire → offsite backup survives

Reason: Redundancy (protects against multiple failure modes)
```

---

## 24.4 What to Backup?

### Database Backups

**Why database backups are critical:**

```
Database = Most valuable asset:
  - User data
  - Transactions
  - Business logic state

Loss consequence:
  - Users lost → business destroyed
  - Compliance violation (GDPR - must protect user data)
```

---

**PostgreSQL backup methods:**

**1. Logical dump (pg_dump):**

```
Method: Export SQL statements

Pros:
  - ✅ Portable (restore to different PostgreSQL version)
  - ✅ Selective backup (specific tables)

Cons:
  - ❌ Slow (large databases take hours)
  - ❌ Database locked during dump (performance impact)

When to use: Small databases (< 10GB), migrations
```

---

**2. Physical backup (pg_basebackup):**

```
Method: Copy database files (binary)

Pros:
  - ✅ Fast (file copy)
  - ✅ Consistent snapshot

Cons:
  - ❌ Must restore to same PostgreSQL version
  - ❌ Cannot restore specific tables

When to use: Large databases (> 10GB), production
```

---

**3. Continuous archiving (WAL):**

```
Method: Archive Write-Ahead Logs (transaction logs)

Process:
  - Base backup: pg_basebackup (weekly)
  - WAL archiving: Continuous (every transaction)

Restore:
  - Apply base backup + WAL logs → point-in-time recovery

Benefit: RPO near-zero (replay transactions up to failure moment)

When to use: Critical systems (RPO < 1 hour)
```

---

### Kubernetes State Backups

**What needs backup in Kubernetes?**

```
1. ETCD (cluster state):
   - All Kubernetes resources (Pods, Services, Deployments)
   - Loss: Cluster unusable (cannot schedule Pods)

2. PersistentVolumes (application data):
   - Database data, file uploads
   - Loss: Data unrecoverable

3. Configuration (GitOps approach):
   - Deployment YAMLs in Git
   - Loss: Can redeploy from Git (IaC)
```

---

**ETCD backup:**

```
Why backup ETCD?
  - ETCD = Kubernetes brain (all cluster state)
  - Loss: Cannot recover Deployments, Services, Secrets

Backup frequency:
  - Daily (minimum)
  - Before major changes (cluster upgrades)

Restore scenario:
  - Cluster corruption → restore ETCD → cluster state recovered

Note: ETCD backup does NOT include PersistentVolume data!
```

---

**PersistentVolume backup:**

```
Options:
  1. Volume snapshots (cloud provider)
     - AWS EBS snapshots, Azure Disk snapshots
     - Fast, automated

  2. Velero (CNCF project)
     - Kubernetes-native backup tool
     - Backs up PVs + Kubernetes resources

  3. Application-level backups
     - Database dumps (pg_dump)
     - More control, application-aware
```

---

## 24.5 Disaster Recovery Planning

### DR Scenarios

**Scenario 1: Deleted resource (human error)**

```
Event: kubectl delete namespace production

Impact: All production resources deleted

Recovery:
  1. Restore from ETCD backup (recovers Deployments, Services)
  2. Restore PVs from snapshots (recovers data)
  3. Verify application (smoke tests)

RTO: 1-2 hours (manual steps)
RPO: Last ETCD backup (e.g., 24 hours ago)

Prevention: RBAC (restrict delete permissions), GitOps (redeploy from Git)
```

---

**Scenario 2: Database corruption**

```
Event: Bug writes corrupted data to database

Impact: Production data corrupted

Recovery:
  1. Identify corruption point (when did bug deploy?)
  2. Restore database from backup BEFORE corruption
  3. Replay WAL logs up to corruption point (point-in-time recovery)
  4. Verify data integrity

RTO: 2-4 hours (depends on database size)
RPO: Seconds (if WAL archiving enabled)

Prevention: Staging environment (test before production), rollback automation
```

---

**Scenario 3: Datacenter failure**

```
Event: AWS US-East-1 region down (entire region outage)

Impact: Entire production cluster unreachable

Recovery:
  1. Failover to DR region (US-West-2)
  2. Restore ETCD backup to DR cluster
  3. Restore database from backup (replicated to DR region)
  4. Update DNS (point users to DR region)

RTO: 4-8 hours (manual failover, DNS propagation)
RPO: Last backup replication (e.g., hourly)

Prevention: Multi-region deployment (active-active or active-passive)
```

---

### Runbook for DR

**DR runbook template:**

```
Disaster: [Database corruption]

Detection:
  - Alert: High error rate in app
  - Investigation: Check database logs → corrupt data found

Assessment:
  - Severity: Critical (production data corrupted)
  - Impact: All users affected

Recovery Steps:
  1. Stop application (prevent further corruption)
  2. Identify last known good backup (timestamp)
  3. Restore database: pg_restore -d production backup.sql
  4. Verify data integrity: SELECT COUNT(*) FROM users;
  5. Restart application
  6. Smoke test: curl /health

Validation:
  - Users can login ✅
  - Data looks correct ✅
  - No errors in logs ✅

Post-mortem:
  - Root cause: Bug in v1.2.3 deployment
  - Action items: Add integration tests, rollback automation
```

**Runbook benefit:** Step-by-step guide (junior engineer can execute under pressure)

---

## 24.6 Testing Backups

### Why Test Backups?

**Untested backup = No backup**

```
Scenario:
  - Backups running daily for 2 years ✅
  - Disaster strikes → restore backup
  - Restore fails: Backup corrupted ❌
  - Result: Data LOST (backups useless!)

Lesson: "Backup" is only valid if RESTORE works
```

---

### Backup Testing Strategies

**1. Periodic restore test (monthly):**

```
Process:
  1. Restore backup to SEPARATE environment (not production!)
  2. Verify data integrity (row counts, checksums)
  3. Run smoke tests (app starts, API works)

Frequency: Monthly (minimum)

Benefit: Catch backup corruption early
```

---

**2. DR drill (quarterly):**

```
Process:
  1. Simulate disaster (e.g., "production cluster deleted")
  2. Execute DR runbook (step-by-step)
  3. Measure RTO (how long did restore take?)
  4. Measure RPO (how much data lost?)

Frequency: Quarterly

Benefit: Validate RTO/RPO targets, train team
```

---

**3. Chaos engineering (advanced):**

```
Process:
  - Randomly delete resources (Pods, PVs)
  - Verify auto-recovery (backups, replication)

Tools: Chaos Monkey, Litmus Chaos

Benefit: Continuous validation (not just quarterly)

When to use: Mature teams, production-ready systems
```

---

## 24.7 Backup Retention

### Retention Policies

**How long to keep backups?**

```
Factors:
  - Compliance (GDPR: 7 years for financial data)
  - Business needs (restore 6-month-old data?)
  - Cost (storage fees increase with retention)

Example policy:
  - Daily backups: Keep 30 days
  - Weekly backups: Keep 12 weeks (3 months)
  - Monthly backups: Keep 12 months (1 year)
  - Yearly backups: Keep 7 years (compliance)

Result: Balance between recoverability and cost
```

---

### Retention Cost Analysis

**Example: 100GB database, daily backups**

```
Strategy 1: Keep all backups (forever)
  - Day 1: 100GB
  - Day 30: 3,000GB (30 backups × 100GB)
  - Day 365: 36,500GB (36TB!)
  - Cost: $1,000/month (S3 storage)

Strategy 2: 30-day retention
  - Day 30: 3,000GB (30 backups)
  - Day 365: 3,000GB (rolling window)
  - Cost: $75/month

Savings: $925/month (92% cost reduction)
```

---

## 24.8 Backup Automation

### Why Automate?

**Manual backups fail:**

```
Reasons:
  - Forgotten (DevOps on vacation)
  - Inconsistent (different process each time)
  - Error-prone (typos, wrong commands)

Result: Gaps in backup coverage (disaster during gap = data lost)
```

---

**Automated backups succeed:**

```
Setup:
  - CronJob runs daily (Kubernetes scheduler)
  - Uploads to S3 (automatic)
  - Alerts on failure (Slack notification)

Result:
  - Consistent (same process every day)
  - Reliable (no human intervention)
  - Auditable (logs of every backup)
```

---

### Backup Monitoring

**Monitor backup health:**

```
Metrics to track:
  - Backup success rate (99% = 3-4 failures/year)
  - Backup size trend (growing? shrinking?)
  - Backup duration (too slow = problem)
  - Last successful backup (gap > 24h = alert!)

Alerts:
  - Backup failed → PagerDuty (CRITICAL)
  - Backup size dropped 50% → investigate (corruption?)
  - No backup in 48h → CRITICAL (automation broken)
```

---

## Kokkuvõte

**Backup vs HA:**
- **HA:** Infrastructure failures (node down, AZ down)
- **Backup:** Data loss, corruption, human error (accidental delete)
- **Both needed:** HA ≠ Backup

**RTO/RPO:**
- **RTO:** Maximum acceptable downtime (how long offline?)
- **RPO:** Maximum acceptable data loss (how much data lost?)
- **Cost curve:** RTO/RPO → 0 = exponential cost increase

**Backup strategies:**
- **Full:** Copy all data (simple, large, slow)
- **Incremental:** Only changes since last backup (fast, fragile)
- **Differential:** Changes since last full (balanced)
- **3-2-1 rule:** 3 copies, 2 media, 1 offsite

**What to backup:**
- **Database:** pg_dump (logical), pg_basebackup (physical), WAL (PITR)
- **Kubernetes state:** ETCD (cluster state), PVs (application data)
- **Configuration:** Git (Infrastructure as Code)

**DR planning:**
- **Scenarios:** Deleted resource, corruption, datacenter failure
- **Runbook:** Step-by-step recovery guide
- **Testing:** Monthly restore, quarterly DR drill

**Backup testing:**
- **Why:** Untested backup = no backup
- **How:** Restore to separate environment, verify data, smoke tests
- **Frequency:** Monthly (minimum)

**Retention:**
- **Policy:** Daily (30d), weekly (3mo), monthly (1yr), yearly (7yr)
- **Cost:** Balance recoverability vs storage fees

**Automation:**
- **Why:** Manual backups fail (forgotten, inconsistent)
- **How:** CronJob, S3 upload, failure alerts
- **Monitoring:** Success rate, size trend, duration, last backup timestamp

---

**DevOps Vaatenurk:**

Backup is INSURANCE:
- Hope you never need it
- But when disaster strikes → priceless

Common mistakes:
- ❌ "HA is our backup" (NO - HA ≠ backup)
- ❌ "We have backups" (untested = useless)
- ❌ "Daily backups enough" (depends on RPO target!)

Best practices:
- ✅ Test restores monthly (validate backups work)
- ✅ Automate everything (CronJob, alerts)
- ✅ 3-2-1 rule (redundancy, offsite)
- ✅ DR drills quarterly (train team, measure RTO/RPO)

---

**Järgmised Sammud:**
**Peatükk 25:** Troubleshooting ja Debugging (viimane peatükk!)

📖 **Praktika:** Labor 6, Harjutus 6 - Database backup automation, ETCD snapshot, restore testing
