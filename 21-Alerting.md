# Peatükk 21: Alerting ja Notification Management

**Kestus:** 2 tundi
**Eeldused:** Peatükk 18-20 (Prometheus, Grafana, Logging)
**Eesmärk:** Mõista alerting filosoofiat ja vältige alert fatigue'i

---

## Õpieesmärgid

- Alert design principles (mida alertida, mida mitte)
- Alert routing strategies (kes saab, millal, kuidas)
- Alert fatigue vältimine
- SLI/SLO-based alerting
- Integration patterns (Slack, PagerDuty, email)
- On-call workflow

---

## 21.1 Miks Alerting on Oluline?

### Reactive vs Proactive Operations

**Reactive (❌ Aeglane):**

```
Kasutaja: "Rakendus ei tööta!"
  ↓
DevOps uurib: "Mis juhtus?"
  ↓
10 minutit debuggimist: "Ah, DB on täis"
  ↓
Fix: "Kustutame vanad logid"

Downtime: 30 minutit (kasutajad kannatavad!)
```

**Proactive (✅ Kiire):**

```
Disk 80% täis
  ↓
Alert: "Disk täis 2h jooksul!" (Slack notification)
  ↓
DevOps reageerib ENNE kriisi
  ↓
Fix: "Cleanup job käivitatud"

Downtime: 0 minutit (kasutajad ei märka!)
```

**Alerting eesmärk:** Tuvasta probleem ENNE, kui kasutaja märkab.

---

## 21.2 Alert Design Philosophy

### Good vs Bad Alerts

**❌ BAD ALERT:**

```
Alert: "CPU usage > 50%"

Probleem:
  - CPU 50% on NORMAALNE (mitte probleem!)
  - Alert fires 100x päevas (alert fatigue)
  - Keegi ei reageeri (liiga palju false positives)
```

**✅ GOOD ALERT:**

```
Alert: "HTTP error rate > 5% for 5 minutes"

Põhjendus:
  - Symptom-based (users can't access service)
  - Actionable (need to investigate)
  - Threshold realistic (5% errors = real problem)
  - Duration filter (5 min = not temporary spike)
```

---

### Alert Design Principles

**1. Alert on symptoms, not causes**

```
❌ BAD: "PostgreSQL connection pool 80% full"
  → WHY is this bad for users? Not clear.

✅ GOOD: "API response time > 1s (p95)"
  → CLEAR user impact: Slow experience
```

**Põhjendus:** Kasutajat ei huvita, et connection pool on täis. Kasutajat huvitab, et API on AEGLANE. Alert'i symptomile (slow API), siis uurige põhjust (connection pool).

---

**2. Make alerts actionable**

```
❌ BAD: "Disk usage high"
  → Mida teha? Unclear.

✅ GOOD: "Disk 90% full on node-1 (ETA full: 2h). Action: Run cleanup job or extend volume."
  → Selge ACTION: cleanup või extend
```

**Põhjendus:** Iga alert peab vastama küsimusele: "Mida ma PEAN tegema?"

---

**3. Avoid alert fatigue**

```
Scenario:
  Day 1: "CPU high" alert fires → investigate
  Day 2: "CPU high" alert fires → investigate
  Day 3: "CPU high" alert fires → ignore (false alarm)
  Day 10: "CPU high" alert fires → ignore
  Day 15: REAL OUTAGE (CPU high) → ignored!

Result: Alert fatigue = alerts become noise
```

**Lahendus:**
- ✅ Adjust thresholds (reduce false positives)
- ✅ Use "for: 5m" (wait 5 min before firing)
- ✅ Alert on trends, not spikes (rate increasing, not absolute value)

---

**4. Different severity levels**

```
CRITICAL (PagerDuty, wake up on-call):
  - User-facing service DOWN
  - Data loss in progress
  - Security breach

WARNING (Slack, business hours):
  - Disk will be full in 24h
  - Error rate elevated (not critical yet)
  - Performance degradation (not outage)

INFO (Email, daily digest):
  - Deployment succeeded
  - Backup completed
  - Usage stats
```

**Põhjendus:** Mitte kõik alert'id on võrdselt kriitilised. CRITICAL = ärata kellaükskõik mis kellaajal. WARNING = check business hours. INFO = ülevaade.

---

## 21.3 SLI/SLO-Based Alerting

### SLI, SLO, SLA - Mis vahe?

**SLI (Service Level Indicator) = Mõõdik**

```
Näited:
  - API availability: 99.95%
  - API latency p95: 200ms
  - Error rate: 0.1%
```

**SLO (Service Level Objective) = Target**

```
Eesmärk:
  - API availability SLO: 99.9% (monthly)
  - API latency SLO: < 500ms (p95)
  - Error rate SLO: < 1%
```

**SLA (Service Level Agreement) = Leping klientiga**

```
Leping:
  - If availability < 99.9% → refund 10%
  - If availability < 99% → refund 25%
```

---

### Error Budget

**Concept:**

```
SLO: 99.9% availability (monthly)

Error budget: 100% - 99.9% = 0.1%
  = 43 minutes downtime per month

Alerting:
  - 50% error budget used (21 min downtime) → WARNING
  - 90% error budget used (38 min downtime) → CRITICAL
  - 100% error budget used → FREEZE deployments!
```

**Põhjendus:** Ei alerta absoluutsele väärtusele (99.9% down), vaid **error budget consumption**. See hoiab SLO sissevaimuesel plaanitud tasemel ja äikab, kui olete SLO ületanud.

---

### SLO-Based Alert Example

```
Traditional alert (symptom):
  "Error rate > 1% for 5 min" → fire alert

SLO-based alert (budget):
  "Error budget 90% consumed (3 days left in month)" → fire alert
```

**Benefit:** SLO-based alert'id on **business-aligned** (not arbitrary thresholds).

---

## 21.4 Alert Routing Strategy

### Who Gets What, When?

**Scenario:** Backend API error

```
Alert severity: CRITICAL
  → Route to: PagerDuty (on-call engineer)
  → Escalation: If no response in 15 min → escalate to manager

Alert severity: WARNING
  → Route to: Slack #backend-alerts (team channel)
  → Escalation: None (business hours only)

Alert severity: INFO
  → Route to: Email (daily digest)
  → Escalation: None
```

**Põhjendus:** Ei soovi äratada kogu tiimi kell 3 öösel WARNING alert'i jaoks. CRITICAL = ärata on-call. WARNING = Slack (business hours). INFO = email digest.

---

### Alert Grouping and Deduplication

**Problem: Alert storm**

```
Scenario: Database down

Alerts fire:
  - "Backend API down" (depends on DB)
  - "Frontend API down" (depends on backend)
  - "Cron job failed" (depends on DB)
  - "Monitoring job failed" (depends on DB)

Result: 50 alerts in 1 minute (SPAM!)
```

**Solution: AlertManager grouping**

```
Group alerts by:
  - Root cause (database=prod)
  - Time window (5 min)

Send ONE notification:
  "4 alerts firing related to database=prod:
   - Backend API down
   - Frontend API down
   - Cron job failed
   - Monitoring job failed"
```

**Benefit:** 1 notification vs 50 (reduced noise)

---

### Silencing and Maintenance Windows

**Use case:** Planned maintenance

```
Maintenance window: 2025-01-25 02:00-04:00

Silence alerts:
  - Matcher: service=backend
  - Duration: 2 hours
  - Comment: "Planned DB migration"

Result: No alerts during maintenance (expected downtime)
```

**Põhjendus:** Planned downtime ei vaja alert'i (me juba teame!). Silence'imine vältib false alerts.

---

## 21.5 Integration Patterns

### Prometheus → AlertManager → Notification Channels

**Architecture:**

```
Prometheus:
  - Evaluates alert rules (every 15s)
  - Sends to AlertManager if condition true

AlertManager:
  - Receives alerts from Prometheus
  - Groups, deduplicates, routes
  - Sends to notification channels

Notification channels:
  - Slack (team chat)
  - PagerDuty (on-call escalation)
  - Email (low priority)
  - Webhook (custom integration)
```

---

### Slack Integration

**Why Slack?**
- ✅ Team visibility (everyone sees alerts)
- ✅ Discussion (thread responses)
- ✅ Fast acknowledgment ("I'm investigating")
- ❌ Not for critical alerts (might miss!)

**Channel strategy:**

```
#backend-alerts → Backend team (WARNING level)
#infra-alerts → Infra team (WARNING level)
#critical-alerts → All teams (CRITICAL level, also PagerDuty)
```

---

### PagerDuty Integration

**Why PagerDuty?**
- ✅ On-call rotation (automatic)
- ✅ Escalation policy (if no response → escalate)
- ✅ Multi-channel (SMS, phone call, push notification)
- ✅ Acknowledgment tracking (who responded, when)
- ❌ Expensive ($29/user/month)

**Escalation policy:**

```
CRITICAL alert fires:
  1. Notify on-call engineer (SMS + push)
  2. Wait 15 min
  3. If no ack → escalate to backup engineer
  4. Wait 15 min
  5. If no ack → escalate to manager
```

**Põhjendus:** Ensures SOMEONE responds (no ignored alerts).

---

### Email (Low Priority)

**Why email?**
- ✅ Daily digest (INFO level alerts)
- ✅ Audit trail (all alerts logged)
- ❌ Slow (not real-time)
- ❌ Ignored (email overload)

**Use case:** Daily summary

```
Subject: Daily Alert Summary (2025-01-23)

5 INFO alerts:
  - Backup completed successfully
  - Deployment to staging succeeded
  - Disk usage 70% (non-critical)
```

---

## 21.6 On-Call Workflow

### On-Call Best Practices

**1. Clear on-call schedule**

```
Week 1: Engineer A (primary) + Engineer B (backup)
Week 2: Engineer C (primary) + Engineer D (backup)
```

**Rotation:** 1-week shifts (avoid burnout)

---

**2. Runbooks for common alerts**

```
Alert: "Database replication lag > 10s"

Runbook (step-by-step):
  1. Check replication status: SELECT * FROM pg_stat_replication;
  2. Identify lagging replica
  3. Check network latency: ping replica
  4. If network issue → contact network team
  5. If query load → restart replication
  6. Escalate if unresolved in 30 min
```

**Põhjendus:** On-call engineer võib olla junior (vajab juhiseid). Runbook = step-by-step guide.

---

**3. Post-mortem after incidents**

```
Incident: 2025-01-23 03:15 - API down (45 min)

Post-mortem (blameless!):
  - Root cause: DB disk full
  - Detection: Alert fired at 03:10 (5 min before outage)
  - Response: On-call paged at 03:10, ack at 03:15
  - Resolution: Cleanup job run, service restored at 04:00
  - Action items:
    1. Add disk usage alert (80% threshold)
    2. Auto-cleanup job (daily cron)
    3. Increase disk size (prevent recurrence)
```

**Põhjendus:** Learn from incidents (improve alerts, automation).

---

## 21.7 Common Anti-Patterns

### 1. Alert on Everything

**Anti-pattern:**

```
Alert rules:
  - CPU > 50%
  - Memory > 60%
  - Disk > 70%
  - Network > 100MB/s
  - Pod restart count > 1
  ...100 more alerts...

Result: 500 alerts/day → ignored (alert fatigue)
```

**Fix:** Alert on USER IMPACT, not internal metrics.

---

### 2. No Actionable Next Step

**Anti-pattern:**

```
Alert: "High latency"

DevOps: "Ummm... okay... what do I do now?" 🤷
```

**Fix:** Add runbook link in alert annotation.

```
Alert: "High latency"
Runbook: https://wiki.company.com/runbooks/high-latency
```

---

### 3. Alert Without Context

**Anti-pattern:**

```
Alert: "Pod down"

DevOps: "Which pod? Which namespace? Production or dev?"
```

**Fix:** Include labels in alert.

```
Alert: "Pod down: backend-abc123 in namespace=production"
```

---

### 4. Ignore Alerts (Crying Wolf)

**Anti-pattern:**

```
Day 1-30: "Disk 90% full" → ignored (false alarm)
Day 31: Disk ACTUALLY full → service down (ignored alert!)
```

**Fix:** Tune thresholds (reduce false positives).

---

## 21.8 Alert Metrics (Meta-Monitoring)

### Monitor Your Alerting System

**Why?**
- AlertManager down → no alerts sent → blind!
- Prometheus down → no metrics → no alerts!

**Solution:** External monitoring (outside Prometheus)

```
External monitor (e.g., UptimeRobot):
  - Check: https://alertmanager.example.com/-/healthy
  - Frequency: Every 5 min
  - If down → send email to team
```

**Põhjendus:** "Who watches the watchmen?" Monitoring system vajab ka monitoring'u!

---

### Alert Effectiveness Metrics

```
Metrics to track:
  - Alert frequency (alerts/day)
  - False positive rate (% of alerts ignored)
  - Time to acknowledge (median time)
  - Time to resolve (median time)

Goal:
  - Reduce false positives (< 10%)
  - Reduce time to ack (< 5 min)
  - Reduce time to resolve (< 30 min)
```

**Continuous improvement:** Review alerts quarterly, tune thresholds.

---

## Kokkuvõte

**Alerting philosophy:**
- **Alert on symptoms**, not causes (user impact, not internal metrics)
- **Make alerts actionable** (what to do next?)
- **Avoid alert fatigue** (tune thresholds, use "for" duration)
- **Different severity levels** (CRITICAL = page on-call, WARNING = Slack, INFO = email)

**SLI/SLO-based alerting:**
- **SLI = metric** (availability, latency, error rate)
- **SLO = target** (99.9% availability)
- **Error budget = 100% - SLO** (0.1% = 43 min/month)
- Alert on error budget consumption (not arbitrary thresholds)

**Alert routing:**
- **Grouping:** Reduce alert storms (group by root cause)
- **Deduplication:** Same alert fires once (not spam)
- **Silencing:** Planned maintenance (no false alerts)
- **Escalation:** CRITICAL → on-call → backup → manager

**Integration channels:**
- **Slack:** Team visibility (WARNING level)
- **PagerDuty:** On-call escalation (CRITICAL level)
- **Email:** Daily digest (INFO level)
- **Webhook:** Custom integrations

**On-call best practices:**
- 1-week rotation (avoid burnout)
- Runbooks for common alerts (step-by-step guides)
- Post-mortems after incidents (blameless, action items)

**Common anti-patterns:**
- ❌ Alert on everything (alert fatigue)
- ❌ No actionable next step (what to do?)
- ❌ Alert without context (which service?)
- ❌ Ignore alerts (crying wolf → real outage missed)

---

**DevOps Vaatenurk:**

Alert design checklist:
- [ ] Does this alert indicate USER IMPACT? (symptom-based)
- [ ] Is there a CLEAR action? (runbook exists)
- [ ] Is the threshold REALISTIC? (not too sensitive)
- [ ] Does it use "for: 5m"? (avoid temporary spikes)
- [ ] Is severity correct? (CRITICAL vs WARNING vs INFO)
- [ ] Is routing correct? (PagerDuty vs Slack vs email)
- [ ] Have I tested this alert? (simulate failure)

---

**Järgmised Sammud:**
**Peatükk 22:** Security Best Practices (RBAC, secrets, network policies)
**Peatükk 23:** High Availability ja Scaling

📖 **Praktika:** Labor 6, Harjutus 4 - Alert rules, AlertManager configuration, Slack integration
