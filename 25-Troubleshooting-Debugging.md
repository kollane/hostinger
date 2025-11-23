# Peatükk 25: Troubleshooting ja Debugging

**Kestus:** 4 tundi
**Eeldused:** Kõik eelnevad peatükid (kogu koolituskava)
**Eesmärk:** Arendada systematic troubleshooting mindset ja debug workflow

---

## Õpieesmärgid

- Troubleshooting methodology (scientific method vs random guessing)
- Common failure patterns (Pod crashes, network issues, resource exhaustion)
- Debugging workflow (divide and conquer, eliminate variables)
- Essential kubectl commands for troubleshooting
- Log analysis strategies
- Root cause analysis (RCA)
- Learning from failures (post-mortems)

---

## 25.1 Troubleshooting Mindset

### Scientific Method vs Random Guessing

**❌ Random Guessing (junior approach):**

```
Problem: "Service down!"

Actions:
  1. Restart Pod (didn't help)
  2. Restart node (didn't help)
  3. Redeploy app (didn't help)
  4. Increase CPU (didn't help)
  5. Ask senior engineer (fixes in 2 minutes)

Time wasted: 2 hours
Lesson learned: None (don't know what actually fixed it)
```

---

**✅ Scientific Method (senior approach):**

```
Problem: "Service down!"

Process:
  1. Observe: What are symptoms? (500 errors, slow response)
  2. Hypothesize: What could cause this? (DB down? Network issue?)
  3. Test: Verify hypothesis (check DB connection)
  4. Eliminate: Not DB (DB is up) → next hypothesis
  5. Repeat until found

Result: Root cause identified (network policy blocking traffic)
Time: 10 minutes
Lesson: Network policy misconfiguration → documented for future
```

**Principle:** Systematic elimination beats random trial-and-error.

---

### Divide and Conquer

**Problem: "App not working"**

```
Too broad! Divide into layers:

Layer 1: Network
  - Can user reach app? (curl fails → network issue)
  - Can app reach DB? (connection timeout → DB unreachable)

Layer 2: Application
  - App crashed? (Pod status: CrashLoopBackOff)
  - App slow? (High CPU usage)

Layer 3: Data
  - DB down? (postgres Pod not running)
  - DB corrupted? (SQL errors in logs)

Result: Narrow problem to specific layer → faster fix
```

---

### Eliminate Variables

**Problem: "Deployment fails in production, works in staging"**

```
What's different between staging and production?

Variables to check:
  - Environment variables? (DB_HOST different)
  - Resources? (Prod has less memory)
  - Network policies? (Prod has stricter rules)
  - Data volume? (Prod has 10x more data)

Method: Eliminate variables one-by-one
  1. Test with staging environment variables → still fails
  2. Test with staging resources → WORKS!

Root cause: Production memory limit too low (app OOMKilled)

Lesson: Isolate variables systematically
```

---

## 25.2 Common Failure Patterns

### Pattern 1: CrashLoopBackOff

**Symptom:**

```
kubectl get pods
NAME                     READY   STATUS             RESTARTS
backend-abc123           0/1     CrashLoopBackOff   5
```

**What it means:**
- Pod started
- Container crashed
- Kubernetes restarted Pod
- Container crashed again
- Repeat (backoff delay increases: 10s, 20s, 40s, 80s, 160s...)

---

**Common causes:**

**1. Application startup error:**

```
Cause: Missing environment variable (DB_HOST undefined)
Log: "Error: Cannot connect to undefined:5432"

Fix: Add DB_HOST to ConfigMap
```

**2. Insufficient resources:**

```
Cause: Memory limit 128MB, app needs 256MB
Log: "OOMKilled" (Out Of Memory)

Fix: Increase memory limit to 512MB
```

**3. Liveness probe too aggressive:**

```
Cause: App starts in 30s, liveness probe fails after 10s
Result: Kubernetes kills Pod before app fully starts

Fix: Increase initialDelaySeconds to 60s
```

---

### Pattern 2: ImagePullBackOff

**Symptom:**

```
kubectl get pods
NAME                     READY   STATUS              RESTARTS
backend-abc123           0/1     ImagePullBackOff    0
```

**What it means:** Kubernetes cannot pull Docker image

---

**Common causes:**

**1. Image doesn't exist:**

```
Image: myorg/backend:1.0

Cause: Image never pushed to registry (typo in tag)

Fix: Push image or fix tag
```

**2. Private registry authentication:**

```
Image: registry.company.com/backend:1.0

Cause: No imagePullSecrets configured

Fix: Create Secret + add to Pod spec
```

**3. Network issue:**

```
Cause: Cluster cannot reach Docker Hub (firewall blocks)

Fix: Whitelist Docker Hub in firewall
```

---

### Pattern 3: Pending Pods

**Symptom:**

```
kubectl get pods
NAME                     READY   STATUS     RESTARTS
backend-abc123           0/1     Pending    0
```

**What it means:** Kubernetes cannot schedule Pod (no suitable node)

---

**Common causes:**

**1. Insufficient resources:**

```
Pod requests: 4 CPU, 8GB RAM
Available nodes: All have < 4 CPU free

Cause: Cluster under-provisioned

Fix: Add nodes OR scale down other Pods
```

**2. Node selector mismatch:**

```
Pod spec: nodeSelector: disktype=ssd
Nodes: All labeled disktype=hdd

Cause: No SSD nodes available

Fix: Add SSD nodes OR remove nodeSelector
```

**3. Pod affinity/anti-affinity:**

```
Pod anti-affinity: Don't schedule on same node as other Pods
Result: All nodes already have conflicting Pods

Fix: Add nodes OR relax anti-affinity rules
```

---

### Pattern 4: Service Unreachable

**Symptom:**

```
curl http://backend-service:3000
→ Connection timeout
```

**What it means:** Service exists, but traffic not reaching Pods

---

**Troubleshooting steps:**

**Step 1: Check Service endpoints:**

```
kubectl get endpoints backend-service

# If NO endpoints → no Pods match Service selector
# If endpoints exist → problem is routing
```

**Step 2: Check Pod selector:**

```
Service selector: app=backend
Pods labels: app=api  (MISMATCH!)

Fix: Update Service selector or Pod labels
```

**Step 3: Check Network Policies:**

```
NetworkPolicy: Deny all traffic by default

Cause: Forgot to allow traffic to backend Pods

Fix: Add Network Policy allowing traffic
```

---

## 25.3 Debugging Workflow

### Step-by-Step Debugging Process

**Problem: "API returning 500 errors"**

**Step 1: Check Pod status**

```
Goal: Is Pod running?

Command: kubectl get pods

Outcomes:
  - CrashLoopBackOff → app crashing (check logs)
  - Running → app running but buggy (check logs)
  - Pending → scheduling issue (check events)
```

---

**Step 2: Check logs**

```
Goal: What error is app reporting?

Command: kubectl logs backend-abc123

Look for:
  - Stack traces (code bugs)
  - Connection errors (DB unreachable)
  - Out of memory (resource exhaustion)

Example log:
  "Error: ECONNREFUSED postgres:5432"
  → Cannot connect to database

Next: Why can't app connect to DB?
```

---

**Step 3: Check events**

```
Goal: Did Kubernetes encounter issues?

Command: kubectl describe pod backend-abc123

Look for:
  - Warning events (FailedScheduling, Unhealthy)
  - Reason: "Liveness probe failed" → app not responding to health check

Example event:
  "Liveness probe failed: HTTP probe failed with statuscode: 500"
  → App /health endpoint returning errors

Next: Why is /health endpoint failing?
```

---

**Step 4: Exec into Pod**

```
Goal: Interactive debugging inside Pod

Command: kubectl exec -it backend-abc123 -- /bin/sh

Test inside Pod:
  # Can app reach DB?
  nc -zv postgres 5432  → Connection refused

  # Check environment variables
  env | grep DB_HOST  → DB_HOST not set!

Root cause: Missing DB_HOST environment variable

Fix: Add DB_HOST to Deployment spec
```

---

**Step 5: Check resource usage**

```
Goal: Is Pod resource-constrained?

Command: kubectl top pod backend-abc123

Output:
  NAME             CPU    MEMORY
  backend-abc123   990m   500Mi

Limits:
  CPU: 1000m (at 99% - throttling!)
  Memory: 512Mi (close to limit)

Hypothesis: CPU throttling → slow responses → timeout

Fix: Increase CPU limit to 2000m
```

---

## 25.4 Essential kubectl Commands

### Observability Commands

**Get resource status:**

```
kubectl get pods
kubectl get pods -o wide  (shows node, IP)
kubectl get pods -w  (watch mode, live updates)
kubectl get pods --all-namespaces  (all namespaces)
kubectl get pods -l app=backend  (filter by label)
```

---

**Describe resource (detailed info):**

```
kubectl describe pod backend-abc123

Shows:
  - Status, conditions, events
  - Container statuses, restarts
  - Resource requests/limits
  - Volume mounts

Key section: Events (Warnings, Errors)
```

---

**Logs:**

```
kubectl logs backend-abc123  (current logs)
kubectl logs backend-abc123 -f  (follow, tail -f mode)
kubectl logs backend-abc123 --previous  (previous crashed container)
kubectl logs backend-abc123 -c container-name  (multi-container Pod)
kubectl logs backend-abc123 --since=1h  (last hour)
kubectl logs backend-abc123 --tail=100  (last 100 lines)
```

---

**Exec into Pod:**

```
kubectl exec -it backend-abc123 -- /bin/sh
kubectl exec backend-abc123 -- curl localhost:3000/health
kubectl exec backend-abc123 -- env  (check environment variables)
```

---

**Port-forward (local debugging):**

```
kubectl port-forward backend-abc123 3000:3000

# Now access Pod from localhost:
curl http://localhost:3000/health

Use case: Debug Pod directly (bypass Service, Ingress)
```

---

**Resource usage:**

```
kubectl top pods  (CPU, memory usage)
kubectl top nodes  (node resource usage)

Example:
  NAME             CPU     MEMORY
  backend-abc123   500m    1024Mi
```

---

### Debugging Commands

**Get events (cluster-wide):**

```
kubectl get events --sort-by='.metadata.creationTimestamp'

Shows recent events:
  - Pod started, Pod killed
  - FailedScheduling, Unhealthy
  - Image pulled, Volume mounted

Filter:
  kubectl get events --field-selector involvedObject.name=backend-abc123
```

---

**Check API connectivity:**

```
kubectl get --raw /healthz
kubectl get --raw /readyz

Use case: Is API server responsive?
```

---

**Force delete stuck resources:**

```
kubectl delete pod backend-abc123 --grace-period=0 --force

Use case: Pod stuck in Terminating state (finalizers blocking)

Warning: Data loss risk (use as last resort)
```

---

## 25.5 Common Pitfalls and Solutions

### Pitfall 1: Didn't Check Logs First

**Mistake:**

```
Problem: "Pod crashing"

Action: Redeploy 10 times (same crash)

Missing step: Check logs!
  kubectl logs backend-abc123
  → "Error: PORT environment variable undefined"

Fix: Add PORT to ConfigMap (5 second fix)

Lesson: ALWAYS check logs first (saves hours)
```

---

### Pitfall 2: Assumed Network is Fine

**Mistake:**

```
Problem: "App can't connect to DB"

Assumption: Network is fine (worked yesterday!)

Reality: Network Policy added yesterday (blocks DB traffic)

Debugging:
  kubectl exec -it backend-abc123 -- nc -zv postgres 5432
  → Connection timeout

Fix: Update Network Policy

Lesson: Don't assume (verify network connectivity)
```

---

### Pitfall 3: Didn't Read Events

**Mistake:**

```
Problem: "Pod pending forever"

Checked: kubectl get pods (Pending)

Missed: kubectl describe pod (events section!)

Events:
  "FailedScheduling: 0/3 nodes available: insufficient memory"

Root cause: All nodes full (need to add nodes)

Lesson: Events tell you WHY (always check describe)
```

---

### Pitfall 4: Debugged Wrong Pod

**Mistake:**

```
Problem: "Users see errors"

Debug: kubectl logs backend-abc123 (no errors!)

Reality: Load Balancer sends traffic to ALL Pods
  - backend-abc123: Healthy
  - backend-def456: Crashing (THIS is the problem Pod!)

Fix: Check ALL Pod replicas
  kubectl logs -l app=backend --all-containers

Lesson: Load balancers hide individual Pod failures
```

---

## 25.6 Root Cause Analysis

### 5 Whys Technique

**Incident: API down (30 min)**

```
1. Why was API down?
   → Pod crashed

2. Why did Pod crash?
   → Out of memory (OOMKilled)

3. Why out of memory?
   → Memory leak in v1.2.3 deployment

4. Why wasn't memory leak caught?
   → No load testing in staging

5. Why no load testing?
   → No process for load testing before production

Root cause: Missing load testing process
Action item: Add load testing to CI/CD pipeline
```

**Lesson:** Keep asking "why" until you reach root cause (not surface symptom)

---

### Blameless Post-Mortems

**Incident: Database deleted (production)**

**Bad post-mortem (blaming):**

```
Root cause: John ran wrong command

Action: Fire John

Result: Team afraid to admit mistakes → hide problems → worse incidents
```

---

**Good post-mortem (blameless):**

```
Incident: Production database deleted

Timeline:
  - 10:00: John runs kubectl delete namespace staging
  - 10:00: Command targets PRODUCTION namespace (wrong context!)
  - 10:05: Users report errors
  - 10:10: Restore from backup initiated
  - 10:30: Service restored

Root causes:
  1. Easy to target wrong namespace (context switching)
  2. No confirmation prompt (dangerous commands)
  3. No backup automation (manual restore slow)

Action items:
  1. Add kubectl plugin: confirm dangerous commands
  2. Color-code prompt (production = RED)
  3. Automate backup restore (1-click recovery)

Blameless: John made mistake, but SYSTEM allowed it
Fix SYSTEM (not punish John)
```

**Result:** Team learns, system improves, mistakes prevented (not hidden)

---

## 25.7 Prevention Strategies

### Shift-Left (Catch Problems Earlier)

**Traditional (catch in production):**

```
Dev → Staging → Production → USERS REPORT BUG

Cost of bug:
  - User impact (reputation damage)
  - Emergency fix (late night, stressful)
  - Rollback (revenue loss)
```

---

**Shift-left (catch in dev/staging):**

```
Dev → CI/CD tests → Staging tests → Production

Catches:
  - Unit tests (dev)
  - Integration tests (CI)
  - Load tests (staging)
  - Smoke tests (production)

Cost of bug:
  - NO user impact (caught before production)
  - Fix during business hours (calm, planned)
  - No rollback needed
```

**Principle:** Earlier detection = cheaper fix

---

### Observability Investment

**Without observability:**

```
Problem: Users complain "slow app"

Debug process:
  - Check logs (nothing obvious)
  - Guess: DB slow? Network slow? App slow?
  - Try random fixes (didn't help)
  - Call senior engineer (fixes in 10 min with metrics)

Time: 2 hours (guessing)
```

---

**With observability:**

```
Problem: Users complain "slow app"

Check Grafana:
  - API latency p95: 5s (normal: 200ms)
  - Database query time: 4.8s (SLOW!)
  - Specific query: SELECT * FROM users WHERE email LIKE '%@%'

Root cause: Unindexed query (full table scan)

Fix: Add index on email column

Time: 5 minutes (data-driven)
```

**ROI:** Observability investment (Prometheus, Grafana, Loki) pays for itself in first incident.

---

## Kokkuvõte

**Troubleshooting mindset:**
- **Scientific method:** Observe → hypothesize → test → eliminate
- **Divide and conquer:** Break problem into layers (network, app, data)
- **Eliminate variables:** Isolate what's different (staging vs production)

**Common failure patterns:**
- **CrashLoopBackOff:** App crashes on startup (missing env var, OOMKilled, liveness probe too aggressive)
- **ImagePullBackOff:** Cannot pull image (doesn't exist, auth missing, network issue)
- **Pending:** Cannot schedule (insufficient resources, node selector mismatch)
- **Service unreachable:** Traffic not reaching Pods (selector mismatch, Network Policy)

**Debugging workflow:**
1. Check Pod status (kubectl get pods)
2. Check logs (kubectl logs)
3. Check events (kubectl describe)
4. Exec into Pod (kubectl exec)
5. Check resources (kubectl top)

**Essential commands:**
- **Observability:** get, describe, logs, top
- **Debugging:** exec, port-forward, get events
- **Cleanup:** delete --force (last resort)

**Common pitfalls:**
- ❌ Didn't check logs first (ALWAYS check logs!)
- ❌ Assumed network is fine (verify connectivity)
- ❌ Didn't read events (events explain WHY)
- ❌ Debugged wrong Pod (check ALL replicas)

**Root cause analysis:**
- **5 Whys:** Keep asking "why" until root cause found
- **Blameless post-mortems:** Fix system, not blame person
- **Action items:** Prevent recurrence (not just fix symptom)

**Prevention:**
- **Shift-left:** Catch problems in dev/staging (not production)
- **Observability:** Invest in metrics, logs, traces (ROI in first incident)
- **Automation:** Automate testing, deployment, rollback (reduce human error)

---

**DevOps Vaatenurk:**

Debugging is a SKILL (not luck):
- Junior: Random guessing (2 hours)
- Senior: Systematic approach (10 minutes)

Best debuggers:
- ✅ Start with logs (obvious clues)
- ✅ Use events (Kubernetes tells you why)
- ✅ Eliminate variables (narrow scope)
- ✅ Document findings (help future-you)

Worst debuggers:
- ❌ Restart everything (hope it works)
- ❌ Skip logs (too lazy to read)
- ❌ Assume it's "just DNS" (verify!)
- ❌ Don't document (repeat same debugging next time)

**Final advice:**

Every incident is a learning opportunity:
- What went wrong? (root cause)
- How to prevent? (action items)
- How to detect faster? (better monitoring)

DevOps career = collection of war stories (and lessons learned from them)

---

**Õnnitleme! Sa läbisid kogu DevOps Administraatori koolituskava! 🎓**

25 peatükki, ~75-85 tundi materjali, alates VPS setup'ist kuni troubleshooting'ini.

**Järgmised sammud:**
📖 **Praktika:** Labor 1-6 (hands-on labs)
🚀 **Projekti töö:** Deploy real-world app to Kubernetes
💼 **Karjäär:** DevOps Engineer, SRE, Platform Engineer

**Remember:** DevOps is a journey, not a destination. Keep learning, keep improving, keep automating! 🚀
