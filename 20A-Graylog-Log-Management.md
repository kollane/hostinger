# Peatükk 20A: Graylog Log Management Platform

**Kestus:** 3-4 tundi
**Eeldused:** Peatükk 2 (Linux, journalctl), Peatükk 9-13 (Kubernetes)
**Eesmärk:** Hallata centralized logging Graylog'iga

---

## Õpieesmärgid

- Mõista Graylog arhitektuuri (MongoDB, Elasticsearch/OpenSearch, Graylog)
- Log ingestion (GELF, Syslog, Beats)
- Streams ja pipelines (log routing ja parsing)
- Dashboards ja saved searches
- Alerting ja notifications
- Graylog vs Loki vs ELK stack

---

## 20.1 Miks Graylog?

### Centralized Logging Problem

**Without centralized logging:**

```
50 Pods across 10 Nodes:

Troubleshooting:
1. SSH to Node 1: kubectl logs pod-abc
2. SSH to Node 2: kubectl logs pod-def
3. SSH to Node 3: kubectl logs pod-ghi
...
50 commands to find one error!

Problems:
- Time-consuming (manual search)
- Logs lost when Pods deleted
- No correlation (can't see full request flow)
- No search (grep through 50 files)
```

---

### Graylog Solution

**Architecture:**

```
Applications → Log Shippers → Graylog → Search/Alerts/Dashboards

Log sources:
- Kubernetes Pods (GELF, Fluentd)
- Syslog (servers, network devices)
- Beats (Filebeat, Winlogbeat)

Graylog:
- Receives logs
- Parses and enriches
- Stores in Elasticsearch/OpenSearch
- Provides Web UI (search, dashboards, alerts)

Storage:
- Elasticsearch/OpenSearch (indexed logs)
- MongoDB (Graylog metadata)
```

**Benefits:**
- ✅ Single search interface (all logs)
- ✅ Persistent storage (survive Pod deletions)
- ✅ Full-text search (find errors in seconds)
- ✅ Correlation (trace requests across services)
- ✅ Alerting (notify on log patterns)

---

## 20.2 Graylog Architecture

### Components

**1. Graylog Server:**
- Receives logs from inputs
- Processes via pipelines
- Routes to streams
- Provides Web UI
- Sends alerts

**2. Elasticsearch/OpenSearch:**
- Stores indexed logs
- Full-text search
- Aggregations

**3. MongoDB:**
- Graylog metadata (users, dashboards, configuration)
- NOT log data

---

### Data Flow

```
1. Log generated:
   Pod: {"level":"error","message":"DB connection failed","timestamp":"2025-01-23T10:00:00Z"}

2. Fluentd/GELF sends to Graylog Input

3. Graylog receives log:
   - Extract fields (level, message, timestamp)
   - Apply pipelines (enrich, parse)
   - Route to stream

4. Store in Elasticsearch:
   - Index: graylog_0
   - Document ID: abc123

5. Search via Web UI:
   - Query: level:error AND message:*connection*
   - Result: Found in 0.05 seconds
```

---

## 20.3 Graylog Installation (Kubernetes)

### Helm Chart

```bash
# Add Graylog Helm repo
helm repo add graylog https://charts.graylog.org
helm repo update

# Install Graylog
helm install graylog graylog/graylog \
  --namespace logging \
  --create-namespace \
  --set graylog.rootUsername=admin \
  --set graylog.rootPassword="$(echo -n yourpassword | shasum -a 256 | awk '{print $1}')" \
  --set graylog.elasticsearch.hosts=http://elasticsearch:9200
```

**What gets installed:**
- Graylog Server (2 replicas)
- Elasticsearch/OpenSearch (StatefulSet)
- MongoDB (StatefulSet)

---

### Access Graylog Web UI

```bash
kubectl port-forward -n logging svc/graylog 9000:9000

# Open: http://localhost:9000
# Login: admin / yourpassword
```

---

## 20.4 Log Ingestion

### Input Types

**1. GELF (Graylog Extended Log Format)**

**Create input:**
```
System → Inputs → Select "GELF UDP"
Port: 12201
Bind address: 0.0.0.0
Launch input
```

**Send logs from application:**

```javascript
// Node.js + gelf-pro
const gelfPro = require('gelf-pro');

gelfPro.setConfig({
  host: 'graylog.logging.svc.cluster.local',
  port: 12201,
  facility: 'backend-api'
});

app.use((req, res, next) => {
  gelfPro.info('HTTP request', {
    method: req.method,
    path: req.path,
    ip: req.ip
  });
  next();
});

app.use((err, req, res, next) => {
  gelfPro.error(err.message, {
    stack: err.stack,
    path: req.path
  });
  res.status(500).send('Internal Server Error');
});
```

---

**2. Syslog**

**Create input:**
```
System → Inputs → Select "Syslog UDP"
Port: 514
```

**Send from Linux:**

```bash
# rsyslog config
echo '*.* @graylog.logging.svc.cluster.local:514' >> /etc/rsyslog.d/50-graylog.conf
systemctl restart rsyslog
```

---

**3. Beats (Filebeat)**

**Filebeat config:**

```yaml
# filebeat.yml
filebeat.inputs:
- type: container
  paths:
    - /var/log/containers/*.log

output.logstash:
  hosts: ["graylog:5044"]
```

**Graylog input:**
```
System → Inputs → Select "Beats"
Port: 5044
```

---

### Fluentd Integration (Kubernetes)

**Fluentd DaemonSet** (collects all Pod logs):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: logging
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      <parse>
        @type json
      </parse>
    </source>

    <filter kubernetes.**>
      @type kubernetes_metadata
    </filter>

    <match kubernetes.**>
      @type gelf
      host graylog.logging.svc.cluster.local
      port 12201
      protocol udp
      <buffer>
        flush_interval 10s
      </buffer>
    </match>

---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: logging
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-gelf
        volumeMounts:
        - name: config
          mountPath: /fluentd/etc/fluent.conf
          subPath: fluent.conf
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: fluentd-config
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

**Result:** All Kubernetes logs → Graylog

📖 **Praktika:** Labor 6, Harjutus 5 - Graylog setup + Fluentd

---

## 20.5 Streams - Log Routing

### What are Streams?

**Stream = Log category** (filter and route logs)

**Examples:**
- Stream: Production Errors (level:error AND environment:production)
- Stream: Backend API Logs (application:backend)
- Stream: Security Events (category:security)

---

### Create Stream

```
Streams → Create Stream

Title: Backend Errors
Description: All error logs from backend API

Stream rules:
- Field: level
  Type: match exactly
  Value: error

- Field: kubernetes_namespace_name
  Type: match exactly
  Value: production

- Field: kubernetes_container_name
  Type: match regex
  Value: ^backend-.*
```

**Behavior:**

```
Log arrives:
level=error, namespace=production, container=backend-abc

1. Check stream rules: ✅ Matches all rules
2. Route to "Backend Errors" stream
3. Store in Elasticsearch with stream tag
4. Appears in stream view
```

---

### Stream Alerts

```
Stream: Backend Errors

Create Alert:
Condition: More than 10 messages in the last 5 minutes

Notifications:
- Email: devops@company.com
- Slack: #backend-alerts
```

**Effect:** If 11+ errors in 5min → alert fired

---

## 20.6 Pipelines - Log Processing

### What are Pipelines?

**Pipeline = Log transformation** (parse, enrich, modify)

**Use cases:**
- Extract JSON fields from message
- GeoIP lookup (IP → country)
- Add custom fields
- Drop spam logs

---

### Pipeline Example - Parse JSON

**Log message:**

```
{"level":"error","message":"DB connection timeout","user":"john@example.com","duration":5000}
```

**Pipeline rule:**

```
# System → Pipelines → Manage rules → Create rule

Rule source:
---
rule "parse_json_message"
when
  has_field("message")
then
  let parsed = parse_json(to_string($message.message));
  set_field("log_level", parsed.level);
  set_field("log_message", parsed.message);
  set_field("user_email", parsed.user);
  set_field("request_duration", parsed.duration);
end
```

**Result:**

```
Original fields:
- message: {"level":"error","message":"DB connection timeout",...}

New fields:
- log_level: error
- log_message: DB connection timeout
- user_email: john@example.com
- request_duration: 5000
```

**Benefit:** Searchable fields! `user_email:john@example.com`

---

### Pipeline Example - GeoIP

```
rule "geoip_lookup"
when
  has_field("src_ip")
then
  let geo = lookup_value("geoip", to_string($message.src_ip));
  set_field("src_country", geo["country_name"]);
  set_field("src_city", geo["city_name"]);
  set_field("src_lat", geo["latitude"]);
  set_field("src_lon", geo["longitude"]);
end
```

**Result:**

```
src_ip: 203.0.113.42
→ GeoIP lookup
→ src_country: Estonia
→ src_city: Tallinn
```

---

### Pipeline Stage

**Connect rules to stream:**

```
System → Pipelines → Manage pipelines

Create pipeline: "Log Processing"

Stage 0:
- parse_json_message
- geoip_lookup

Connect to stream: All messages
```

---

## 20.7 Search and Analysis

### Search Syntax

**Basic search:**

```
# All error logs
level:error

# Specific namespace
kubernetes_namespace_name:production

# Wildcard
message:*connection*

# Boolean
level:error AND kubernetes_namespace_name:production

# Regex
kubernetes_container_name:/^backend-.*/

# Time range
timestamp:[2025-01-23T00:00:00 TO 2025-01-23T23:59:59]
```

---

### Saved Searches

```
Search → Create saved search

Title: Backend Production Errors
Query: level:error AND kubernetes_namespace_name:production AND kubernetes_container_name:/^backend-.*/

Relative time range: Last 24 hours

Save
```

**Use case:** Quick access to common searches

---

### Aggregations (Statistics)

**Field statistics:**

```
Search: level:error

Quick values → kubernetes_container_name

Result:
- backend-abc: 45 errors
- backend-def: 23 errors
- backend-ghi: 12 errors
```

**Chart:**

```
Search: *
Histogram: timestamp (interval: 1 hour)
Stacked: level

Result: Line chart showing error/warning/info logs per hour
```

---

## 20.8 Dashboards

### Create Dashboard

```
Dashboards → Create dashboard

Title: Production Overview

Add widget:
- Type: Search result count
- Query: level:error AND kubernetes_namespace_name:production
- Title: Production Errors (last 24h)

Add widget:
- Type: Quick values
- Field: kubernetes_container_name
- Query: level:error
- Title: Errors by Container

Add widget:
- Type: Field chart
- Field: level
- Query: kubernetes_namespace_name:production
- Title: Log Levels Distribution
```

**Result:** Dashboard with real-time stats

---

### Dashboard Auto-Refresh

```
Dashboard → Settings → Auto-refresh: Every 30 seconds
```

**Use case:** NOC monitor (TV screen)

---

## 20.9 Alerting

### Alert Conditions

**1. Message Count:**
```
More than 50 messages in the last 5 minutes
Query: level:error AND message:*OutOfMemory*
```

**2. Field Value:**
```
Field value is higher than 100
Field: response_time
Stream: Backend API
```

**3. Field Aggregation:**
```
Field mean is higher than 500
Field: request_duration
Stream: Backend API
```

---

### Notifications

**Slack:**

```
Alerts → Notifications → Create notification

Type: Slack
Webhook URL: https://hooks.slack.com/services/...
Channel: #devops-alerts
Custom message: Alert: ${alert_condition.title} - ${stream.title}
```

**Email:**

```
Type: Email
Recipients: devops@company.com,oncall@company.com
Subject: Graylog Alert: ${alert_condition.title}
```

---

### Alert Example

```
Alert condition:
- Title: High Error Rate
- Query: level:error AND kubernetes_namespace_name:production
- Condition: More than 100 messages in the last 5 minutes

Notification:
- Slack: #production-alerts
- Email: oncall@company.com

Grace period: 5 minutes (don't alert again for 5min)
```

📖 **Praktika:** Labor 6, Harjutus 6 - Graylog streams, pipelines, alerts

---

## 20.10 Graylog vs Loki vs ELK Stack

### Comparison

| Kriteerium | Graylog | Loki (Grafana) | ELK Stack |
|------------|---------|----------------|-----------|
| **Components** | Graylog + ES/OpenSearch + MongoDB | Loki + Promtail | Elasticsearch + Logstash + Kibana |
| **Storage** | Elasticsearch (indexed) | Object storage (chunks) | Elasticsearch (indexed) |
| **Query language** | Lucene | LogQL | Lucene |
| **Indexing** | Full-text (all fields) | Labels only (not full-text) | Full-text (all fields) |
| **Resource usage** | High (ES indexing) | Low (label-based) | High (ES indexing) |
| **Search speed** | Fast (indexed) | Slower (label filtering) | Fast (indexed) |
| **Scalability** | Horizontal (ES shards) | Horizontal (chunks) | Horizontal (ES shards) |
| **Alerting** | Built-in | Via Grafana | Via Kibana/Watcher |
| **UI** | Graylog Web UI | Grafana | Kibana |
| **Complexity** | Medium | Low | High |
| **Cost** | Open-source + ES/OpenSearch | Open-source | Open-source (or Elastic license) |
| **Best for** | Full-text log search | Kubernetes (label-based) | Advanced analysis (ML) |

---

### Architecture Comparison

**Graylog:**
```
Pods → Fluentd → Graylog → Elasticsearch → Graylog UI
```

**Loki:**
```
Pods → Promtail → Loki → Object Storage → Grafana
```

**ELK:**
```
Pods → Filebeat → Logstash → Elasticsearch → Kibana
```

---

### When to Choose

**Choose Graylog kui:**
- ✅ Need full-text search (find any word in logs)
- ✅ Want built-in alerting (no external tools)
- ✅ Complex log parsing (pipelines, extractors)
- ✅ Centralized logging for mixed environments (K8s + VMs + network devices)

**Choose Loki kui:**
- ✅ Kubernetes-focused (label-based filtering)
- ✅ Low resource usage (cost-sensitive)
- ✅ Already use Grafana (unified UI with metrics)
- ✅ Simple queries (don't need full-text search)

**Choose ELK kui:**
- ✅ Advanced analytics (machine learning, anomaly detection)
- ✅ Large-scale (petabytes of logs)
- ✅ Complex dashboards (Kibana Canvas)
- ✅ Existing Elastic expertise

---

### Hybrid Setup (Best of Both)

```
Kubernetes → Promtail → Loki → Grafana (metrics + logs)
           → Fluentd → Graylog (full-text search + alerts)

Why both?
- Loki: Fast label-based filtering (Grafana integration)
- Graylog: Full-text search and complex alerting

Cost: Higher (two systems) but best flexibility
```

---

## 20.11 Graylog Best Practices

### 1. Index Management

**Rotate indices:**

```
System → Indices → Index set: Default

Rotation strategy: Time-based (1 day)
Retention strategy: Delete (keep last 30 days)

Result:
- graylog_0 (today)
- graylog_1 (yesterday)
- graylog_2 (2 days ago)
...
- graylog_30 (30 days ago)
- graylog_31 (deleted)
```

**Benefit:** Control storage usage (old logs deleted)

---

### 2. Input Throttling

**Limit message rate:**

```
Input → GELF UDP → Edit

Throttling: Enable
Max messages/sec: 1000
```

**Prevent:** Log storm overwhelming Graylog

---

### 3. Stream Processing Order

```
Pipeline stage 0: Parsing (JSON, regex)
Pipeline stage 1: Enrichment (GeoIP, lookups)
Pipeline stage 2: Filtering (drop spam)
```

**Parse before enrichment** (can't enrich unparsed fields)

---

### 4. Field Naming Convention

```
# ✅ GOOD
kubernetes_namespace_name
kubernetes_pod_name
http_response_code

# ❌ BAD
ns
p
code
```

**Use descriptive names** (searchable, understandable)

---

### 5. Regular Backups

```bash
# Backup MongoDB (Graylog config)
mongodump --host mongodb:27017 --db graylog --out /backup/graylog-$(date +%Y%m%d)

# Elasticsearch snapshots
curl -X PUT "elasticsearch:9200/_snapshot/backup/snapshot_$(date +%Y%m%d)" -H 'Content-Type: application/json' -d'
{
  "indices": "graylog_*"
}'
```

---

## Kokkuvõte

**Graylog architecture:**
- Graylog Server (log processing, Web UI)
- Elasticsearch/OpenSearch (indexed storage)
- MongoDB (metadata)

**Log ingestion:**
- GELF, Syslog, Beats, Fluentd
- Kubernetes integration (Fluentd DaemonSet)

**Streams:**
- Log routing (production errors, backend logs)
- Stream-specific alerts

**Pipelines:**
- Log parsing (JSON, regex)
- Enrichment (GeoIP, custom fields)
- Filtering (drop spam)

**Search:**
- Lucene syntax (full-text search)
- Saved searches, aggregations
- Dashboards (widgets, auto-refresh)

**Alerting:**
- Conditions (message count, field value)
- Notifications (Slack, email, PagerDuty)

**vs Alternatives:**
- Graylog: Full-text search, built-in alerts
- Loki: Label-based, low resources
- ELK: Advanced analytics, ML

---

**DevOps Vaatenurk:**

```bash
# Access Graylog
kubectl port-forward -n logging svc/graylog 9000:9000

# Check Graylog logs
kubectl logs -n logging deployment/graylog

# Elasticsearch health
curl http://elasticsearch:9200/_cluster/health

# MongoDB backup
kubectl exec -n logging mongodb-0 -- mongodump --db graylog --archive > graylog-backup.archive
```

---

**Järgmised Sammud:**
- Production deployment (HA, monitoring)
- Advanced pipelines (complex parsing)
- Integration (Grafana, PagerDuty, Jira)

📖 **Praktika:** Labor 6 - Complete observability stack (Prometheus + Grafana + Graylog)
