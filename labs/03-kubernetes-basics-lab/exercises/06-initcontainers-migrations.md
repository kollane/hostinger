# Harjutus 6: InitContainers & Database Migrations

**Kestus:** 60 minutit
**Eesmärk:** Deploy täielik mikroteenuste süsteem koos automaatsete database migration'itega

---

## 📋 Ülevaade

Selles harjutuses õpid **InitContainers** - container'eid, mis käivituvad **ENNE** main container'i ja loovad **database schema** Liquibase'iga.

See on **Lab 3 kulminatsioon** - deploy'me kogu 5-teenuse süsteemi:
- 2x PostgreSQL (StatefulSet + PVC)
- 2x Backend (Deployment + InitContainers for migrations)
- 1x Frontend (Deployment + NodePort)

**Lab 2 → Lab 3 Bridge:**
- **Lab 2:** Liquibase Docker Compose'is (`depends_on: service_completed_successfully`)
- **Lab 3:** Liquibase InitContainers'is (runs before main container)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista InitContainers kontseptsiooni
- ✅ Tõlkida Lab 2 Liquibase pattern'i Kubernetes'i
- ✅ Luua Liquibase ConfigMap changelog'idega
- ✅ Lisa initContainer Deployment'ile
- ✅ Mõista container lifecycle (init → main)
- ✅ Deploy täielik 5-teenuse stack
- ✅ Testida end-to-end workflow
- ✅ Debuggida InitContainer failure'id

---

## 🏗️ Arhitektuur

### Docker Compose vs Kubernetes InitContainers

```
┌──────────────────────────────────────────────────────────┐
│         Lab 2: Docker Compose Pattern                    │
│                                                          │
│  services:                                               │
│    liquibase-user:                                       │
│      image: liquibase/liquibase:4.20-alpine              │
│      command: --changeLogFile=changelog.xml update       │
│      depends_on:                                         │
│        postgres-user:                                    │
│          condition: service_healthy                      │
│      restart: "no"  # Run once only                      │
│                                                          │
│    user-service:                                         │
│      depends_on:                                         │
│        liquibase-user:                                   │
│          condition: service_completed_successfully  ←─┐  │
│      # Waits for Liquibase before starting           │  │
│                                                       │  │
└───────────────────────────────────────────────────────┼──┘
                                                        │
                   Translates to                       │
                        ▼                               │
┌───────────────────────────────────────────────────────┼──┐
│         Lab 3: Kubernetes InitContainers              │  │
│                                                       │  │
│  Deployment: user-service                             │  │
│    spec:                                              │  │
│      template:                                        │  │
│        spec:                                          │  │
│          initContainers:  ← Runs BEFORE main container│  │
│          - name: liquibase-migration                  │  │
│            image: liquibase/liquibase:4.20-alpine     │  │
│            command: [liquibase, update]               │  │
│            # Must complete successfully before main   ◄──┘
│                                                       │
│          containers:  ← Runs AFTER initContainers     │
│          - name: user-service                         │
│            # Starts ONLY if initContainer succeeded   │
│                                                       │
└───────────────────────────────────────────────────────┘
```

### Full Stack Architecture (End Goal)

```
┌───────────────────────────────────────────────────────────────┐
│              Browser: http://<node-ip>:30080                  │
└────────────────────────────┬──────────────────────────────────┘
                             │
                             ▼
┌───────────────────────────────────────────────────────────────┐
│  Service: frontend (NodePort :30080)                          │
└────────────────────────────┬──────────────────────────────────┘
                             │
                             ▼
┌───────────────────────────────────────────────────────────────┐
│  Deployment: frontend (1 replica)                             │
│    Pod: frontend-xxx                                          │
│      Container: nginx (static files)                          │
│        → http://user-service:3000/api/*                       │
│        → http://todo-service:8081/api/*                       │
└─────────────────┬──────────────────────────┬──────────────────┘
                  │                          │
        ┌─────────▼─────────┐      ┌────────▼─────────┐
        │ Service:          │      │ Service:         │
        │ user-service      │      │ todo-service     │
        │ (ClusterIP :3000) │      │ (ClusterIP :8081)│
        └─────────┬─────────┘      └────────┬─────────┘
                  │                         │
        ┌─────────▼─────────┐      ┌────────▼──────────┐
        │ Deployment:       │      │ Deployment:       │
        │ user-service (2r) │      │ todo-service (2r) │
        │                   │      │                   │
        │ InitContainer:    │      │ InitContainer:    │
        │ ├─ liquibase-init │      │ ├─ liquibase-init │
        │ │  (runs once)    │      │ │  (runs once)    │
        │ │  ✓ CREATE users │      │ │  ✓ CREATE todos │
        │ │                 │      │ │                 │
        │ Container:        │      │ Container:        │
        │ └─ user-service   │      │ └─ todo-service   │
        │    (runs after ✓) │      │    (runs after ✓) │
        └─────────┬─────────┘      └────────┬──────────┘
                  │                         │
        ┌─────────▼─────────┐      ┌────────▼──────────┐
        │ Service:          │      │ Service:          │
        │ postgres-user     │      │ postgres-todo     │
        └─────────┬─────────┘      └────────┬──────────┘
                  │                         │
        ┌─────────▼─────────┐      ┌────────▼──────────┐
        │ StatefulSet:      │      │ StatefulSet:      │
        │ postgres-user     │      │ postgres-todo     │
        │   Pod: postgres-0 │      │   Pod: postgres-0 │
        │     └─ PVC: 10Gi  │      │     └─ PVC: 10Gi  │
        └───────────────────┘      └───────────────────┘
```

---

## 📝 Sammud

### Samm 1: Mõista InitContainers (5 min)

**InitContainers:**
- **Käivituvad ENNE** main container'eid
- **Järjekorras** (init1 → init2 → init3 → main)
- **Peavad lõppema edukalt** (exit code 0) enne main container start'i
- **Failure** = pod ei käivitu (InitContainer retry'b)

**Use cases:**
- **Database migrations** (Liquibase, Flyway)
- **Wait for dependencies** (wait for DB ready)
- **Setup tasks** (create directories, download files)
- **Security scanning** (scan image before running)

**Lifecycle:**

```
Pod Start
   │
   ▼
Init Container 1 (Liquibase migration)
   │ exit 0 (success)
   ▼
Init Container 2 (optional - wait for service)
   │ exit 0 (success)
   ▼
Main Container (user-service)
   │ Runs continuously
   ▼
Pod Running
```

**Failure:**

```
Init Container 1
   │ exit 1 (failure - DB connection failed)
   ▼
Retry Init Container 1 (backoff: 10s, 20s, 40s...)
   │ exit 1 (still failing)
   ▼
Pod Status: Init:CrashLoopBackOff
Main Container NEVER starts!
```

---

### Samm 2: Loo Liquibase ConfigMap (User Service) (10 min)

**Liquibase changelog files** - kirjeldavad DB schema muudatusi.

Lab 2'st on meil Liquibase changelogs - kasutame samu Kubernetes'es.

Loo fail `liquibase-user-cm.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: liquibase-user-changelog
  labels:
    app: user-service
data:
  # Master changelog file
  changelog-master.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <databaseChangeLog
        xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

        <include file="001-create-users-table.xml" relativeToChangelogFile="true"/>

    </databaseChangeLog>

  # Changeset 1: Create users table
  001-create-users-table.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <databaseChangeLog
        xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

        <changeSet id="001-create-users-table" author="devops-training">
            <createTable tableName="users">
                <column name="id" type="BIGSERIAL" autoIncrement="true">
                    <constraints primaryKey="true" nullable="false"/>
                </column>
                <column name="name" type="VARCHAR(100)">
                    <constraints nullable="false"/>
                </column>
                <column name="email" type="VARCHAR(255)">
                    <constraints nullable="false" unique="true"/>
                </column>
                <column name="password" type="VARCHAR(255)">
                    <constraints nullable="false"/>
                </column>
                <column name="role" type="VARCHAR(20)" defaultValue="user">
                    <constraints nullable="false"/>
                </column>
                <column name="created_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
                    <constraints nullable="false"/>
                </column>
                <column name="updated_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
                    <constraints nullable="false"/>
                </column>
            </createTable>

            <rollback>
                <dropTable tableName="users"/>
            </rollback>
        </changeSet>

    </databaseChangeLog>
```

**Deploy:**

```bash
kubectl apply -f liquibase-user-cm.yaml

# Kontrolli
kubectl get configmap liquibase-user-changelog

kubectl describe configmap liquibase-user-changelog
# Data:
# ====
# 001-create-users-table.xml:
# ----
# <?xml version="1.0" ...
#
# changelog-master.xml:
# ----
# <?xml version="1.0" ...
```

---

### Samm 3: Uuenda user-service Deployment InitContainer'iga (15 min)

Loo fail `user-service-deployment-with-init.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        tier: backend
    spec:
      # InitContainers - käivituvad ENNE main container'i
      initContainers:
      - name: liquibase-migration
        image: liquibase/liquibase:4.20-alpine
        command:
        - sh
        - -c
        - |
          echo "Starting Liquibase migration..."
          liquibase \
            --changeLogFile=/liquibase/changelog/changelog-master.xml \
            --url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME} \
            --username=${DB_USER} \
            --password=${DB_PASSWORD} \
            --log-level=INFO \
            update
          echo "Migration completed successfully!"

        # Environment variables (same as main container)
        envFrom:
        - configMapRef:
            name: user-config  # DB_HOST, DB_PORT, DB_NAME
        - secretRef:
            name: db-user-secret  # DB_USER, DB_PASSWORD

        # Mount Liquibase changelogs
        volumeMounts:
        - name: liquibase-changelog
          mountPath: /liquibase/changelog
          readOnly: true

      # Main container - käivitub AINULT kui initContainer õnnestus
      containers:
      - name: user-service
        image: user-service:1.0-optimized
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
          name: http

        envFrom:
        - configMapRef:
            name: user-config
        - secretRef:
            name: db-user-secret
        - secretRef:
            name: jwt-secret

      # Volumes
      volumes:
      - name: liquibase-changelog
        configMap:
          name: liquibase-user-changelog
```

**Deploy:**

```bash
# Apply Deployment
kubectl apply -f user-service-deployment-with-init.yaml

# Kontrolli pod'e
kubectl get pods -l app=user-service

# Output (algul):
# NAME                            READY   STATUS     RESTARTS   AGE
# user-service-7d4f8c9b6d-abc     0/1     Init:0/1   0          5s
#                                         ^^^^^^^^
#                                         Init container töötab

# Mõne sekundi pärast:
# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-7d4f8c9b6d-abc     1/1     Running   0          20s
# user-service-7d4f8c9b6d-def     1/1     Running   0          20s

# Vaata init container logisid
kubectl logs user-service-7d4f8c9b6d-abc -c liquibase-migration

# Output:
# Starting Liquibase migration...
# Liquibase Version: 4.20.0
# ...
# Liquibase command 'update' was executed successfully.
# Migration completed successfully!

# Vaata main container logisid
kubectl logs user-service-7d4f8c9b6d-abc -c user-service

# Output:
# Server running on port 3000
# Database connection: OK
```

**Kontrolli DB'd:**

```bash
# Connect PostgreSQL
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db

# List tables
user_service_db=# \dt

# Output:
#                    List of relations
#  Schema |         Name          | Type  |  Owner
# --------+-----------------------+-------+----------
#  public | databasechangelog     | table | postgres  ← Liquibase tracking
#  public | databasechangeloglock | table | postgres  ← Liquibase lock
#  public | users                 | table | postgres  ← OUR TABLE!

# Describe users table
user_service_db=# \d users

# Output:
#                                      Table "public.users"
#    Column   |            Type             | Collation | Nullable |              Default
# ------------+-----------------------------+-----------+----------+-----------------------------------
#  id         | bigint                      |           | not null | nextval('users_id_seq'::regclass)
#  name       | character varying(100)      |           | not null |
#  email      | character varying(255)      |           | not null |
#  password   | character varying(255)      |           | not null |
#  role       | character varying(20)       |           | not null | 'user'::character varying
#  created_at | timestamp without time zone |           | not null | CURRENT_TIMESTAMP
#  updated_at | timestamp without time zone |           | not null | CURRENT_TIMESTAMP

user_service_db=# \q
```

✅ **Liquibase lõi tabeli automaatselt!**

---

### Samm 4: Loo Liquibase ConfigMap (Todo Service) (5 min)

Sarnaselt user-service'le.

Loo fail `liquibase-todo-cm.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: liquibase-todo-changelog
  labels:
    app: todo-service
data:
  changelog-master.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <databaseChangeLog
        xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

        <include file="001-create-todos-table.xml" relativeToChangelogFile="true"/>

    </databaseChangeLog>

  001-create-todos-table.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <databaseChangeLog
        xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

        <changeSet id="001-create-todos-table" author="devops-training">
            <createTable tableName="todos">
                <column name="id" type="BIGSERIAL" autoIncrement="true">
                    <constraints primaryKey="true" nullable="false"/>
                </column>
                <column name="user_id" type="BIGINT">
                    <constraints nullable="false"/>
                </column>
                <column name="title" type="VARCHAR(200)">
                    <constraints nullable="false"/>
                </column>
                <column name="description" type="TEXT"/>
                <column name="completed" type="BOOLEAN" defaultValueBoolean="false">
                    <constraints nullable="false"/>
                </column>
                <column name="created_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
                    <constraints nullable="false"/>
                </column>
                <column name="updated_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
                    <constraints nullable="false"/>
                </column>
            </createTable>

            <createIndex tableName="todos" indexName="idx_todos_user_id">
                <column name="user_id"/>
            </createIndex>

            <rollback>
                <dropIndex tableName="todos" indexName="idx_todos_user_id"/>
                <dropTable tableName="todos"/>
            </rollback>
        </changeSet>

    </databaseChangeLog>
```

**Deploy:**

```bash
kubectl apply -f liquibase-todo-cm.yaml
```

---

### Samm 5: Uuenda todo-service Deployment InitContainer'iga (5 min)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo-service
  template:
    metadata:
      labels:
        app: todo-service
        tier: backend
    spec:
      initContainers:
      - name: liquibase-migration
        image: liquibase/liquibase:4.20-alpine
        command:
        - sh
        - -c
        - |
          echo "Starting Liquibase migration for Todo Service..."
          liquibase \
            --changeLogFile=/liquibase/changelog/changelog-master.xml \
            --url=${SPRING_DATASOURCE_URL} \
            --username=${SPRING_DATASOURCE_USERNAME} \
            --password=${SPRING_DATASOURCE_PASSWORD} \
            --log-level=INFO \
            update
          echo "Migration completed!"

        envFrom:
        - configMapRef:
            name: todo-config  # SPRING_DATASOURCE_URL
        - secretRef:
            name: db-todo-secret  # SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD

        volumeMounts:
        - name: liquibase-changelog
          mountPath: /liquibase/changelog
          readOnly: true

      containers:
      - name: todo-service
        image: todo-service:1.0-optimized
        imagePullPolicy: Never
        ports:
        - containerPort: 8081

        envFrom:
        - configMapRef:
            name: todo-config
        - secretRef:
            name: db-todo-secret

      volumes:
      - name: liquibase-changelog
        configMap:
          name: liquibase-todo-changelog
```

**Deploy:**

```bash
kubectl apply -f todo-service-deployment-with-init.yaml

# Kontrolli
kubectl get pods -l app=todo-service

# Vaata init container logisid
kubectl logs <todo-service-pod> -c liquibase-migration

# Kontrolli DB'd
kubectl exec -it postgres-todo-0 -- psql -U postgres -d todo_service_db -c "\dt"

# Output:
#                    List of relations
#  Schema |         Name          | Type  |  Owner
# --------+-----------------------+-------+----------
#  public | databasechangelog     | table | postgres
#  public | databasechangeloglock | table | postgres
#  public | todos                 | table | postgres  ← CREATED!
```

---

### Samm 6: Deploy Täielik Stack (10 min)

Nüüd deploy'me kõik 5 teenust korraga.

**Checklist:**

```bash
# 1. PV ja PVC (Harjutus 5)
kubectl get pv
# postgres-user-pv   10Gi   RWO   Bound
# postgres-todo-pv   10Gi   RWO   Bound

kubectl get pvc
# postgres-user-pvc   Bound   postgres-user-pv   10Gi
# postgres-todo-pvc   Bound   postgres-todo-pv   10Gi

# 2. ConfigMaps
kubectl get configmaps
# user-config
# todo-config
# postgres-user-config
# postgres-todo-config
# liquibase-user-changelog
# liquibase-todo-changelog

# 3. Secrets
kubectl get secrets
# db-user-secret
# db-todo-secret
# jwt-secret

# 4. StatefulSets (PostgreSQL)
kubectl get statefulsets
# postgres-user   1/1
# postgres-todo   1/1

# 5. Services
kubectl get services
# postgres-user    ClusterIP   None          5432/TCP
# postgres-todo    ClusterIP   None          5432/TCP
# user-service     ClusterIP   10.96.x.x     3000/TCP
# todo-service     ClusterIP   10.96.x.x     8081/TCP
# frontend         NodePort    10.96.x.x     80:30080/TCP

# 6. Deployments
kubectl get deployments
# user-service   2/2
# todo-service   2/2
# frontend       1/1

# 7. Pods
kubectl get pods

# Output (11 pod'i kokku):
# NAME                            READY   STATUS    RESTARTS   AGE
# postgres-user-0                 1/1     Running   0          20m
# postgres-todo-0                 1/1     Running   0          15m
# user-service-7d4f8c9b6d-abc     1/1     Running   0          10m
# user-service-7d4f8c9b6d-def     1/1     Running   0          10m
# todo-service-5c6b7d8e9f-ghi     1/1     Running   0          5m
# todo-service-5c6b7d8e9f-jkl     1/1     Running   0          5m
# frontend-6b5c8d9e0f-mno         1/1     Running   0          2m
```

---

### Samm 7: End-to-End Test (Full Workflow) (10 min)

**Test täielikku workflow't browser'ist:**

```bash
# Minikube: Get URL
minikube service frontend --url
# Output: http://192.168.49.2:30080

# K3s:
echo "http://localhost:30080"

# Browser'is:
# http://192.168.49.2:30080 (Minikube)
# http://localhost:30080 (K3s)
```

**Test API'dega (curl):**

```bash
# 1. Frontend health check
curl http://$(minikube ip):30080

# Output: HTML page

# 2. User Service health
kubectl port-forward svc/user-service 8080:3000 &
curl http://localhost:8080/health

# Output:
# {"status":"OK","database":"connected","timestamp":"..."}

# 3. Register user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Kubernetes User",
    "email": "k8s@example.com",
    "password": "kubernetes123"
  }'

# Output:
# {
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": {
#     "id": 1,
#     "name": "Kubernetes User",
#     "email": "k8s@example.com",
#     "role": "user"
#   }
# }

# Save token
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# 4. Get users (authenticated)
curl http://localhost:8080/api/users \
  -H "Authorization: Bearer $TOKEN"

# Output:
# [
#   {
#     "id": 1,
#     "name": "Kubernetes User",
#     "email": "k8s@example.com",
#     "role": "user"
#   }
# ]

# 5. Todo Service health
kubectl port-forward svc/todo-service 8081:8081 &
curl http://localhost:8081/actuator/health

# Output:
# {"status":"UP","components":{"db":{"status":"UP"},...}}

# 6. Create todo (assuming todo API needs JWT from user-service)
curl -X POST http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Deploy to Kubernetes",
    "description": "Complete Lab 3 exercises",
    "userId": 1
  }'

# 7. Get todos
curl http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN"

# Output:
# [
#   {
#     "id": 1,
#     "userId": 1,
#     "title": "Deploy to Kubernetes",
#     "description": "Complete Lab 3 exercises",
#     "completed": false
#   }
# ]
```

**Kontrolli DB'sid:**

```bash
# User DB
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "SELECT id, name, email FROM users;"

# Output:
#  id |      name       |      email
# ----+-----------------+-----------------
#   1 | Kubernetes User | k8s@example.com

# Todo DB
kubectl exec -it postgres-todo-0 -- psql -U postgres -d todo_service_db -c "SELECT id, title, completed FROM todos;"

# Output:
#  id |        title          | completed
# ----+-----------------------+-----------
#   1 | Deploy to Kubernetes  | f
```

✅ **TÄIELIK SÜSTEEM TÖÖTAB!**

---

### Samm 8: Debuggi InitContainer Failures (5 min)

**Kui initContainer ebaõnnestub:**

```bash
kubectl get pods

# Output:
# NAME                            READY   STATUS                  RESTARTS   AGE
# user-service-7d4f8c9b6d-abc     0/1     Init:Error              0          30s
#                                         ^^^^^^^^^^
#                                         Init container failed

# Või:
# user-service-7d4f8c9b6d-abc     0/1     Init:CrashLoopBackOff   2          2m

# Describe pod
kubectl describe pod user-service-7d4f8c9b6d-abc

# Events:
# Warning  Failed  1m  kubelet  Error: liquibase-migration container exited with code 1

# Vaata init container logisid
kubectl logs user-service-7d4f8c9b6d-abc -c liquibase-migration

# Output (näide error):
# Starting Liquibase migration...
# ERROR: Connection could not be created to jdbc:postgresql://postgres-user:5432/user_service_db with driver org.postgresql.Driver
# Caused by: java.net.UnknownHostException: postgres-user
```

**Levinud põhjused:**
1. **DB pole valmis** - postgres-user Service ei eksisteeri
2. **Vale connection string** - DB_HOST, DB_PORT, DB_NAME vale
3. **Vale credentials** - DB_USER, DB_PASSWORD vale
4. **Liquibase changelog error** - XML syntax error
5. **ConfigMap puudub** - liquibase-user-changelog ei eksisteeri

**Lahendus:**

```bash
# 1. Kontrolli, kas PostgreSQL töötab
kubectl get pods -l tier=database
# postgres-user-0   1/1   Running

# 2. Kontrolli Service
kubectl get service postgres-user

# 3. Kontrolli ConfigMap
kubectl get configmap liquibase-user-changelog

# 4. Kontrolli Secret
kubectl get secret db-user-secret

# 5. Test DB connection manually
kubectl run test-pg --image=postgres:16-alpine --rm -it -- \
  psql -h postgres-user -U postgres -d user_service_db -c "SELECT 1"

# Kui töötab - Liquibase env vars on valed
```

---

### Samm 9: Rollout Uus Migration (5 min)

**Kui lisame uue changeset:**

```bash
# Muuda ConfigMap
kubectl edit configmap liquibase-user-changelog

# Lisa uus changeset:
# 002-add-user-profile-fields.xml: |
#   <changeSet id="002" author="devops">
#     <addColumn tableName="users">
#       <column name="bio" type="TEXT"/>
#     </addColumn>
#   </changeSet>

# Uuenda changelog-master.xml include list

# Rollout Deployment (restart pod'id)
kubectl rollout restart deployment user-service

# Vaata logisid
kubectl logs -f <new-pod> -c liquibase-migration

# Output:
# Starting Liquibase migration...
# Liquibase: Running Changeset: 002-add-user-profile-fields.xml::002::devops
# Migration completed!

# Kontrolli DB'd
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "\d users"

# Output näitab uut column'i "bio"
```

---

### Samm 10: Production Best Practices (5 min)

### ✅ InitContainer Best Practices

1. **Idempotent migrations** - Liquibase/Flyway handle'ivad seda
2. **Timeout** - Lisa `activeDeadlineSeconds` (max run time)
   ```yaml
   initContainers:
   - name: liquibase-migration
     activeDeadlineSeconds: 300  # Max 5 min
   ```

3. **Resource limits**
   ```yaml
   initContainers:
   - name: liquibase-migration
     resources:
       limits:
         cpu: 500m
         memory: 512Mi
   ```

4. **Health checks** - Wait for DB ready
   ```yaml
   initContainers:
   - name: wait-for-db
     image: busybox:1.35
     command:
     - sh
     - -c
     - |
       until nc -z postgres-user 5432; do
         echo "Waiting for PostgreSQL..."
         sleep 2
       done
       echo "PostgreSQL is ready!"
   ```

5. **Immutable ConfigMaps** - Versioned changelogs
   ```yaml
   configMap:
     name: liquibase-user-changelog-v2  # Versioned
   ```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Full Stack Deployed:**
  - [ ] 2x PostgreSQL StatefulSet
  - [ ] 2x Backend Deployment (with InitContainers)
  - [ ] 1x Frontend Deployment
  - [ ] 5x Services

- [ ] **Database Schema:**
  - [ ] `users` table (from Liquibase)
  - [ ] `todos` table (from Liquibase)
  - [ ] `databasechangelog` (Liquibase tracking)

- [ ] **InitContainers:**
  - [ ] Liquibase migrations run before app start
  - [ ] Tables created automatically
  - [ ] Migrations idempotent (can re-run)

- [ ] **End-to-End Test:**
  - [ ] Frontend kättesaadav browser'ist
  - [ ] User registration töötab
  - [ ] User login töötab (JWT)
  - [ ] Todo CRUD töötab
  - [ ] Andmed persistivad

**Final Check:**

```bash
# Kõik pod'id Running
kubectl get pods

# All services healthy
curl http://$(minikube ip):30080
kubectl port-forward svc/user-service 8080:3000
curl http://localhost:8080/health  # {"status":"OK","database":"connected"}

# DB schema exists
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "\dt"
# users, databasechangelog, databasechangeloglock

# End-to-end workflow works
# (Register → Login → Create Todo → List Todos)
```

---

## 🐛 Troubleshooting

### Probleem 1: Init:Error või Init:CrashLoopBackOff

```bash
kubectl get pods
# user-service-xxx   0/1   Init:CrashLoopBackOff   3   2m

kubectl describe pod user-service-xxx
# Last State:     Terminated
#   Reason:       Error
#   Exit Code:    1

kubectl logs user-service-xxx -c liquibase-migration
# ERROR: Connection to database failed
```

**Lahendus:** Kontrolli DB ühendust (Service, credentials, DB readiness).

---

### Probleem 2: Liquibase "Table already exists"

```bash
kubectl logs user-service-xxx -c liquibase-migration
# ERROR: Table 'users' already exists
```

**Põhjus:** Liquibase changelog ei ole idempotent või databasechangelog table puudub.

**Lahendus:**

```bash
# Kontrolli databasechangelog
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "SELECT * FROM databasechangelog;"

# Kui table puudub - Liquibase ei saanud kirjutada (permissions?)
# Kui exists - changeset ID mismatch

# Reset (AINULT DEV!):
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "DROP TABLE users, databasechangelog, databasechangeloglock;"
```

---

### Probleem 3: Main container ei käivitu pärast init success

```bash
kubectl get pods
# user-service-xxx   0/1   Running   0   30s
# (Peaks olema 1/1 Running)

kubectl describe pod user-service-xxx
# State:          Waiting
#   Reason:       CrashLoopBackOff

kubectl logs user-service-xxx -c user-service
# Error: Cannot find module '/app/src/index.js'
```

**Põhjus:** Main container image error (mitte initContainer).

---

## 🎓 Õpitud Mõisted

### InitContainers
- **InitContainer:** Runs before main container
- **Sequential execution:** init1 → init2 → main
- **Must succeed:** exit 0 required
- **Use cases:** Migrations, setup, wait-for-deps

### Liquibase
- **Changelog:** XML files describing schema changes
- **Changeset:** Single atomic change
- **databasechangelog:** Tracks applied changesets
- **Idempotent:** Can re-run safely
- **Rollback:** Reverse changes

### Container Lifecycle
1. **Init:0/1** - Init container 1 running
2. **Init:CrashLoopBackOff** - Init container failing
3. **PodInitializing** - Init containers succeeded, main starting
4. **Running** - Main container running
5. **CrashLoopBackOff** - Main container failing

---

## 💡 Parimad Tavad

### ✅ DO (Tee):
1. **Kasuta InitContainers migration'itele** - Clean separation
2. **Idempotent migrations** - Liquibase/Flyway
3. **Wait for dependencies** - Init container: wait-for-db
4. **Resource limits** - InitContainer CPU/memory
5. **Timeout** - `activeDeadlineSeconds`
6. **Version changelogs** - ConfigMap versioning

### ❌ DON'T (Ära tee):
1. **Ära tee destructive changes blindly** - DROP TABLE production'is!
2. **Ära unusta rollback'e** - Iga changeset needs rollback
3. **Ära kasuta main container migration'itele** - Use InitContainer

---

## 🎉 Lab 3 Lõpetatud!

**Õnnitleme! Oled deploy'nud täieliku production-ready Kubernetes stack'i!**

### Mida saavutasime:

✅ **Harjutus 1:** Kubernetes cluster + Pods
✅ **Harjutus 2:** Deployments + ReplicaSets + Scaling
✅ **Harjutus 3:** Services + DNS + Networking
✅ **Harjutus 4:** ConfigMaps + Secrets
✅ **Harjutus 5:** PersistentVolumes + StatefulSets
✅ **Harjutus 6:** InitContainers + Liquibase Migrations

### Täielik süsteem:
- **5 teenust** (2 DB + 2 Backend + 1 Frontend)
- **11 pod'i** kokku
- **Persistent storage** (andmed jäävad alles)
- **Automaatsed DB migratsioonid** (Liquibase)
- **Service discovery** (DNS-based)
- **Secure config** (ConfigMaps + Secrets)
- **End-to-end workflow** (Register → Login → CRUD)

---

## 🔗 Järgmine Labor

**Lab 4: Kubernetes Täiustatud** (5h)
- Ingress (HTTPS, domain routing)
- Health Probes (liveness, readiness)
- HorizontalPodAutoscaler (CPU autoscaling)
- RBAC (security)
- Helm (package manager)

---

## 📚 Viited

**Kubernetes Dokumentatsioon:**
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)

**Liquibase:**
- [Liquibase Documentation](https://docs.liquibase.com/)
- [Liquibase Kubernetes](https://docs.liquibase.com/workflows/liquibase-community/using-liquibase-and-kubernetes.html)

**Alternatives:**
- [Flyway](https://flywaydb.org/) - Java-based migration tool
- [golang-migrate](https://github.com/golang-migrate/migrate) - Go-based

---

**🎉 Palju õnne! Oled läbinud Lab 3: Kubernetes Põhitõed! 🎉**

*Nüüd on sul töötav production-ready mikroteenuste süsteem Kubernetes'es!*

*Järgmises labs viime selle järgmisele tasemele - Ingress, Autoscaling, RBAC, Helm!*
