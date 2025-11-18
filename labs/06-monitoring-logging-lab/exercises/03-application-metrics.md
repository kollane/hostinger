# Harjutus 3: Application Metrics

**Kestus:** 60 minutit
**Eesmärk:** Lisa custom metrics Node.js rakendusse ja eksponeeripromClient library'ga

---

## 📋 Ülevaade

Selles harjutuses lisad **User Service** rakendusse custom metrics'id, kasutades `prom-client` Node.js library't. Loome `/metrics` endpoint'i, mida Prometheus saab scrape'ida, ja lisame business metrics'id (HTTP requests, response times, errors).

**Application metrics** võimaldavad jälgida:
- HTTP request count ja rate
- Response times (latency)
- Error rate
- Business metrics (user registrations, logins)
- Node.js runtime metrics (memory, CPU, event loop)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Paigaldada prom-client library
- ✅ Lisada `/metrics` endpoint
- ✅ Kasutada Counter, Gauge, Histogram metrics'eid
- ✅ Trackida HTTP requests ja errors
- ✅ Koguda Node.js runtime metrics
- ✅ Testida metrics Prometheus'es
- ✅ Visualiseerida app metrics Grafana's

---

## 🏗️ Arhitektuur

```
┌────────────────────────────────────────────────────┐
│  User Service (Node.js + Express)                 │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  prom-client Middleware                      │ │
│  │  - Track HTTP requests                       │ │
│  │  - Measure response time                     │ │
│  │  - Count errors                              │ │
│  └────────┬─────────────────────────────────────┘ │
│           │                                        │
│           ▼                                        │
│  ┌──────────────────────────────────────────────┐ │
│  │  GET /metrics                                │ │
│  │  (Prometheus text format)                    │ │
│  │                                              │ │
│  │  # HELP http_requests_total Total requests  │ │
│  │  # TYPE http_requests_total counter         │ │
│  │  http_requests_total{method="GET"} 1234     │ │
│  └──────────────────────────────────────────────┘ │
│           ▲                                        │
└───────────┼────────────────────────────────────────┘
            │ scrape every 15s
    ┌───────┴────────┐
    │  Prometheus    │
    └────────────────┘
```

---

## 📝 Sammud

### Samm 1: Install prom-client (5 min)

**User Service projektis:**

```bash
cd labs/apps/backend-nodejs

# Install prom-client
npm install prom-client

# Check package.json
cat package.json | grep prom-client

# Peaks näitama:
# "prom-client": "^15.0.0"
```

---

### Samm 2: Loo Metrics Module (15 min)

**Loo fail `metrics.js`:**

```javascript
const client = require('prom-client');

// Enable default metrics (CPU, memory, event loop, etc.)
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

// Create a Registry
const register = new client.Registry();
client.register.setDefaultLabels({
  app: 'user-service'
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HTTP Metrics
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Counter: Total HTTP requests
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

// Histogram: HTTP request duration
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5]  // Buckets in seconds
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Business Metrics
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Counter: User registrations
const userRegistrationsTotal = new client.Counter({
  name: 'user_registrations_total',
  help: 'Total number of user registrations'
});

// Counter: User logins
const userLoginsTotal = new client.Counter({
  name: 'user_logins_total',
  help: 'Total number of user logins',
  labelNames: ['status']  // success or failure
});

// Gauge: Active users (currently logged in)
const activeUsers = new client.Gauge({
  name: 'active_users',
  help: 'Number of currently active users'
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Database Metrics
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Gauge: Database connections
const dbConnections = new client.Gauge({
  name: 'db_connections_active',
  help: 'Number of active database connections'
});

// Histogram: Database query duration
const dbQueryDuration = new client.Histogram({
  name: 'db_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['query'],
  buckets: [0.001, 0.01, 0.1, 0.5, 1]
});

// Export metrics
module.exports = {
  register: client.register,
  httpRequestsTotal,
  httpRequestDuration,
  userRegistrationsTotal,
  userLoginsTotal,
  activeUsers,
  dbConnections,
  dbQueryDuration
};
```

---

### Samm 3: Lisa Metrics Middleware (10 min)

**Loo fail `middleware/metrics.js`:**

```javascript
const { httpRequestsTotal, httpRequestDuration } = require('../metrics');

// Middleware to track HTTP metrics
function metricsMiddleware(req, res, next) {
  const start = Date.now();

  // Capture response finish event
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;  // Convert to seconds
    const route = req.route ? req.route.path : req.path;
    const method = req.method;
    const status = res.statusCode;

    // Increment request counter
    httpRequestsTotal.inc({
      method,
      route,
      status
    });

    // Observe request duration
    httpRequestDuration.observe({
      method,
      route,
      status
    }, duration);
  });

  next();
}

module.exports = metricsMiddleware;
```

---

### Samm 4: Lisa /metrics Endpoint (5 min)

**Muuda `server.js`:**

```javascript
const express = require('express');
const metricsMiddleware = require('./middleware/metrics');
const { register } = require('./metrics');

const app = express();

// ... olemasolev middleware (body-parser, cors, jne)

// Add metrics middleware (enne route'e!)
app.use(metricsMiddleware);

// ... olemasolevad routes

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Metrics Endpoint
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err);
  }
});

// ... server.listen()
```

---

### Samm 5: Lisa Business Metrics (10 min)

**Muuda `routes/auth.js`:**

```javascript
const { userRegistrationsTotal, userLoginsTotal } = require('../metrics');

// Register endpoint
router.post('/register', async (req, res) => {
  try {
    // ... existing registration logic

    // Increment registration counter
    userRegistrationsTotal.inc();

    res.status(201).json({ user, token });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Login endpoint
router.post('/login', async (req, res) => {
  try {
    // ... existing login logic

    if (validPassword) {
      // Increment successful login
      userLoginsTotal.inc({ status: 'success' });

      res.json({ user, token });
    } else {
      // Increment failed login
      userLoginsTotal.inc({ status: 'failure' });

      res.status(401).json({ error: 'Invalid password' });
    }
  } catch (error) {
    userLoginsTotal.inc({ status: 'failure' });
    res.status(500).json({ error: error.message });
  }
});
```

---

### Samm 6: Testi Lokaalselt (5 min)

**Run application:**

```bash
npm start

# App käivitub port 3000
```

**Testi /metrics endpoint:**

```bash
curl http://localhost:3000/metrics

# Peaks näitama Prometheus format metrics:
# # HELP http_requests_total Total number of HTTP requests
# # TYPE http_requests_total counter
# http_requests_total{method="GET",route="/health",status="200",app="user-service"} 5
#
# # HELP http_request_duration_seconds Duration of HTTP requests in seconds
# # TYPE http_request_duration_seconds histogram
# http_request_duration_seconds_bucket{le="0.01",method="GET",route="/health",status="200"} 5
# http_request_duration_seconds_sum{method="GET",route="/health",status="200"} 0.015
# http_request_duration_seconds_count{method="GET",route="/health",status="200"} 5
#
# # HELP nodejs_heap_size_used_bytes Process heap size used from Node.js in bytes.
# # TYPE nodejs_heap_size_used_bytes gauge
# nodejs_heap_size_used_bytes{app="user-service"} 15728640
```

**Genereeri traffic:**

```bash
# Make requests
curl http://localhost:3000/health
curl http://localhost:3000/health
curl http://localhost:3000/health

# Check metrics
curl http://localhost:3000/metrics | grep http_requests_total

# Count should increment!
```

---

### Samm 7: Deploy Kubernetes'e (5 min)

**Commit ja push:**

```bash
git add metrics.js middleware/metrics.js server.js routes/auth.js package.json
git commit -m "Add Prometheus metrics with prom-client"
git push origin main

# CI/CD pipeline builds new image
# CD pipeline deploys to cluster
```

**Või build manually:**

```bash
# Build Docker image
docker build -t user-service:metrics .

# Tag
docker tag user-service:metrics your-username/user-service:metrics

# Push
docker push your-username/user-service:metrics

# Update deployment
kubectl set image deployment/user-service \
  user-service=your-username/user-service:metrics
```

---

### Samm 8: Kontrolli Prometheus'es (10 min)

**Prometheus UI → Targets:**

```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Ava browser:
# http://localhost:9090/targets
```

**Kontrolli ServiceMonitor:**

```bash
kubectl get servicemonitor -n default user-service-monitor

# Status → Targets peaks näitama:
# servicemonitor/default/user-service-monitor/0 (1/1 up)
```

**Testi metrics Prometheus'es:**

Prometheus UI → Graph:

```promql
# HTTP requests
http_requests_total{app="user-service"}

# Request rate (per second)
rate(http_requests_total{app="user-service"}[5m])

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{app="user-service"}[5m]))

# User registrations
user_registrations_total

# Active users
active_users
```

---

### Samm 9: Visualiseeri Grafana's (5 min)

**Loo dashboard panel'id:**

**Panel 1: Request Rate**
```promql
sum(rate(http_requests_total{app="user-service"}[5m])) by (method, route)
```

**Panel 2: Error Rate**
```promql
sum(rate(http_requests_total{app="user-service",status=~"5.."}[5m]))
```

**Panel 3: P95 Latency**
```promql
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{app="user-service"}[5m])) by (le))
```

**Panel 4: Registrations per Hour**
```promql
rate(user_registrations_total{app="user-service"}[1h]) * 3600
```

Salvesta dashboard nimega "User Service - Application Metrics"!

---

## ✅ Kontrolli Tulemusi

- [ ] **prom-client:**
  - [ ] Installed (package.json)
  - [ ] metrics.js module created

- [ ] **Metrics:**
  - [ ] `/metrics` endpoint works
  - [ ] HTTP metrics (requests, duration)
  - [ ] Business metrics (registrations, logins)
  - [ ] Node.js default metrics (heap, CPU)

- [ ] **Prometheus:**
  - [ ] ServiceMonitor scraping
  - [ ] Metrics visible (Graph tab)
  - [ ] PromQL queries work

- [ ] **Grafana:**
  - [ ] Dashboard created
  - [ ] Panels visualize app metrics

---

## 🐛 Troubleshooting

### Probleem 1: /metrics endpoint 404

**Põhjus:** Route puudub või middleware vale järjekord.

**Lahendus:**

```javascript
// server.js - ÕIGE järjekord:
app.use(metricsMiddleware);  // 1. Metrics middleware ENNE route'e
app.use('/api', routes);     // 2. API routes
app.get('/metrics', ...);    // 3. Metrics endpoint PEALE route'e
```

---

### Probleem 2: Metrics tühjad Prometheus'es

**Diagnoos:**

```bash
# Test /metrics local
kubectl port-forward deployment/user-service 3000:3000
curl http://localhost:3000/metrics

# Kontrolli ServiceMonitor
kubectl describe servicemonitor user-service-monitor
```

**Lahendus:** Ensure ServiceMonitor port name matches Service:

```yaml
# Service
ports:
- name: http  # Must match
  port: 80
  targetPort: 3000

# ServiceMonitor
endpoints:
- port: http  # Must match Service port name
```

---

## 🎓 Õpitud Mõisted

### Prometheus Client:
- **prom-client:** Node.js library Prometheus metrics'ide jaoks
- **Register:** Metrics registry (default või custom)
- **Default metrics:** Node.js runtime metrics (memory, CPU, GC)

### Metric Types:
- **Counter:** Monotonically increasing (requests_total)
- **Gauge:** Up/down value (active_users)
- **Histogram:** Distribution (request_duration_seconds)
- **Summary:** Quantiles (advanced)

### Labels:
- **label:** Key-value pair (method="GET", status="200")
- **cardinality:** Unique label combinations (avoid high cardinality!)

---

## 💡 Parimad Tavad

1. **Use labels sparingly** - High cardinality (many unique values) = performance issues
2. **Prefix metrics** - `http_`, `db_`, `user_` (organized)
3. **Use histograms for latency** - Not gauges
4. **Default metrics** - Always enable (heap, CPU, eventloop)
5. **Business metrics** - Track important events (registrations, purchases)
6. **Document metrics** - Add `help` text
7. **Test locally** - curl /metrics before deploying
8. **Monitor /metrics size** - Large response = too many metrics

---

## 🔗 Järgmine Samm

Järgmises harjutuses seadistame **Loki log aggregation** - kogume ja visualiseerime rakenduse logisid Grafana's.

**Jätka:** [Harjutus 4: Logging with Loki](04-logging-loki.md)

---

## 📚 Viited

- [prom-client Documentation](https://github.com/siimon/prom-client)
- [Prometheus Metric Types](https://prometheus.io/docs/concepts/metric_types/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)

---

**Õnnitleme! Rakendus eksponeerib nüüd Prometheus metrics'eid! 📊**
