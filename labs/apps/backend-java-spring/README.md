# Todo Service - Java Spring Boot Application

Mikroteenuste arhitektuuri õpperakendus DevOps koolituseks.

## 📋 Ülevaade

Todo Service on RESTful API teenus todo märkmete haldamiseks, mis:
- Kasutab Java 17 + Spring Boot 3 + PostgreSQL
- Autentib kasutajaid JWT tokenitega (integreerub User Service'iga)
- Pakub täielikku CRUD funktsionaalsust
- On containerized (Docker) ja orkestreeritav (Kubernetes)

## 🏗️ Arhitektuur

```
Frontend (Port 8080)
    │
    ├──> User Service (Node.js:3000) ──> PostgreSQL (5432)
    │         │
    │         └─> Genereerib JWT tokeni
    │
    └──> Todo Service (Java:8081) ──> PostgreSQL (5433)
              │
              └─> Valideerib JWT tokeni
```

### Tehnoloogiad

- **Framework:** Spring Boot 3.2
- **Java Version:** 17
- **Database:** PostgreSQL 16 + Spring Data JPA
- **Security:** Spring Security + JWT (io.jsonwebtoken)
- **Build Tool:** Gradle 8.5
- **Container Base:** eclipse-temurin:17-jre-alpine

## 🚀 Kiirstart

### Eeldused

- Java 17 või uuem
- PostgreSQL 16
- Gradle 8.5+ (või kasuta `./gradlew`)

### 1. Andmebaasi seadistamine

```bash
# Loo andmebaas ja tabelid
sudo -u postgres psql -f database-setup.sql

# Või Docker'is:
docker run -d \
  --name postgres-todo \
  -e POSTGRES_DB=todo_service_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5433:5432 \
  postgres:16-alpine

# Käivita setup script
docker exec -i postgres-todo psql -U postgres -d todo_service_db < database-setup.sql
```

### 2. Keskkonnamuutujad

```bash
cp .env.example .env
vim .env  # Muuda andmebaasi ühendust ja JWT_SECRET
```

**TÄHTIS:** `JWT_SECRET` peab olema SAMA nagu User Service'il!

### 3. Build ja käivita

```bash
# Build rakendus
./gradlew clean bootJar

# Käivita
./gradlew bootRun

# Või Java'ga otse
java -jar build/libs/todo-service.jar
```

Rakendus käivitub aadressil: **http://localhost:8081**

## 🐳 Docker

### Build Docker Image

```bash
# Lihtne build (eeldab, et JAR on juba olemas)
./gradlew bootJar
docker build -t todo-service:1.0 .

# Optimized build (multi-stage)
docker build -f Dockerfile.optimized -t todo-service:1.0-opt .
```

### Run Container

```bash
docker run -d \
  --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=postgres-todo \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=your-secret-key-change-this-in-production \
  todo-service:1.0-opt
```

### Docker Compose (Full Stack)

```bash
# Kõik teenused koos (Frontend + User Service + Todo Service + PostgreSQL)
docker compose -f ../../docker-compose.yml up -d
```

## 🔌 API Endpointid

| Meetod | Endpoint | Kirjeldus | Auth |
|--------|----------|-----------|------|
| **POST** | `/api/todos` | Loo uus todo | ✅ JWT |
| **GET** | `/api/todos` | Loe kõik todo'd (pagination, filter) | ✅ JWT |
| **GET** | `/api/todos/{id}` | Loe üks todo | ✅ JWT |
| **PUT** | `/api/todos/{id}` | Uuenda todo't | ✅ JWT |
| **DELETE** | `/api/todos/{id}` | Kustuta todo | ✅ JWT |
| **PATCH** | `/api/todos/{id}/complete` | Märgi tehtuks | ✅ JWT |
| **GET** | `/api/todos/stats` | Statistika | ✅ JWT |
| **GET** | `/health` | Health check | ❌ |

### Swagger UI

API dokumentatsioon: **http://localhost:8081/swagger-ui.html**

## 🧪 Testimine

### Käsitsi (cURL)

```bash
# Health check
curl http://localhost:8081/health

# Login User Service'is (saa JWT token)
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  | jq -r '.token')

echo "Token: $TOKEN"

# Loo todo
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Õpi Docker",
    "description": "Läbi töötada Lab 1 harjutused",
    "priority": "high",
    "dueDate": "2025-11-20T18:00:00"
  }'

# Loe kõik todo'd
curl -X GET "http://localhost:8081/api/todos?page=0&size=10" \
  -H "Authorization: Bearer $TOKEN"

# Märgi todo tehtud (id=1)
curl -X PATCH http://localhost:8081/api/todos/1/complete \
  -H "Authorization: Bearer $TOKEN"

# Loe statistika
curl -X GET http://localhost:8081/api/todos/stats \
  -H "Authorization: Bearer $TOKEN"
```

### Unit Tests

```bash
./gradlew test
```

## 📁 Projekti Struktuur

```
backend-java-spring/
├── src/
│   ├── main/
│   │   ├── java/com/hostinger/todoapp/
│   │   │   ├── config/          # Security, CORS, OpenAPI
│   │   │   ├── controller/      # REST Controllers
│   │   │   ├── dto/             # Data Transfer Objects
│   │   │   ├── exception/       # Exception handling
│   │   │   ├── model/           # JPA Entities
│   │   │   ├── repository/      # Database access
│   │   │   ├── security/        # JWT validation
│   │   │   ├── service/         # Business logic
│   │   │   └── TodoApplication.java
│   │   └── resources/
│   │       └── application.properties
│   └── test/                    # Tests
├── build.gradle                 # Dependencies
├── Dockerfile                   # Basic Docker image
├── Dockerfile.optimized         # Multi-stage build
├── database-setup.sql           # DB schema
├── .env.example                 # Environment template
└── README.md                    # This file
```

## 🔐 Security

### JWT Autentimine

1. **User Service** genereerib JWT tokeni (POST /api/auth/login)
2. **Frontend** saadab tokeni Todo Service'ile (Authorization: Bearer <token>)
3. **Todo Service** valideerib tokenit sama JWT_SECRET'iga
4. Ekstraktib `userId`, `email`, `role` tokenist
5. Seadistab Spring Security konteksti

### Turvalisus

- ✅ JWT token validation
- ✅ CORS konfiguratsioon
- ✅ Non-root container user
- ✅ Environment variables for secrets
- ✅ Input validation
- ✅ SQL injection prevention (JPA)

## 🌍 Keskkonnad

### Development (Local)

```bash
DB_HOST=localhost
DB_PORT=5433
JWT_SECRET=development-secret
```

### Docker Compose

```bash
DB_HOST=postgres-todo
DB_PORT=5432
JWT_SECRET=shared-secret-with-user-service
```

### Kubernetes

```bash
DB_HOST=postgres-todo-service.default.svc.cluster.local
DB_PORT=5432
JWT_SECRET=<from-secret>
```

## 📊 Monitoring

### Health Check

```bash
curl http://localhost:8081/health
```

### Actuator Endpoints

- `/actuator/health` - Detailed health info
- `/actuator/info` - Application info

### Logs

```bash
# Docker logs
docker logs -f todo-service

# Kubernetes logs
kubectl logs -f deployment/todo-service
```

## 🐛 Troubleshooting

### Rakendus ei käivitu

```bash
# Kontrolli Java versiooni
java -version  # Peaks olema 17+

# Kontrolli Gradle versiooni
./gradlew --version

# Kontrolli andmebaasi ühendust
psql -h localhost -p 5433 -U postgres -d todo_service_db
```

### JWT token ei tööta

```bash
# Kontrolli, et JWT_SECRET on SAMA nagu User Service'il
echo $JWT_SECRET

# Kontrolli token'i sisu (jwt.io)
echo $TOKEN | cut -d'.' -f2 | base64 -d
```

### Database connection errors

```bash
# Kontrolli PostgreSQL staatust
docker ps | grep postgres

# Kontrolli ühendust
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "SELECT COUNT(*) FROM todos;"
```

## 📚 DevOps Laboriharjutused

See rakendus on osa DevOps õppekavast:

- **Lab 1:** Docker containerization
- **Lab 2:** Docker Compose multi-container setup
- **Lab 3:** Kubernetes deployment
- **Lab 4:** Advanced Kubernetes (Ingress, HPA)
- **Lab 5:** CI/CD with GitHub Actions
- **Lab 6:** Monitoring with Prometheus + Grafana

## 📄 Litsents

MIT License - DevOps Training Project

## 🤝 Kontakt

DevOps Training - devops@hostinger.com
