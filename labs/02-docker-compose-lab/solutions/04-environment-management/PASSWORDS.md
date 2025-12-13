# Paroolide ja Saladuste Haldamine

## 📚 Harjutuse Lihtsustus

**⚠️ TÄHTIS:** Selles harjutuses kasutame **SAMA DB parooli** TEST ja PROD keskkonnas (`postgres`).

**Põhjus:**
- Kasutame samu PostgreSQL volume'id (`postgres-user-data`, `postgres-todo-data`)
- PostgreSQL **ignoreerib** uut parooli, kui volume on juba initsialiseeritud
- Fokus on multi-environment pattern'il (compose failid, .env failid), mitte volume haldamisel

**🏢 Reaalses Production Keskkonnas:**
- Eraldi serverid (test.company.com, prod.company.com)
- Eraldi volume'id (või managed DB: AWS RDS, Azure Database)
- **ERINEVAD tugevad paroolid** igale keskkonnale!

---

## 🔐 Turvalisuse Mudel (Harjutus)

| Keskkond | DB Parool | JWT Secret | Kas commit'ida git'i? |
|----------|-----------|------------|----------------------|
| **Local Dev** | `postgres` (hardcoded) | Harjutus 3 väärtus | ✅ Jah (docker-compose.yml) |
| **Test** | `postgres` (sama¹) | Base64, 256-bit | ✅ Jah (example fail) |
| **Production** | `postgres` (sama¹) | ERINEV Base64 hash | ❌ **EI! (.gitignore)** |

**¹ Harjutuse lihtsustus:** Sama DB parool (postgres), sest sama volume.
**Reaalses elus:** Eraldi serverid → eraldi volume'id → ERINEVAD paroolid!

---

## 📋 Kiire Alustamine

### 1️⃣ Loo `.env` failid template'ist

**Harjutuses kasutame ühte template'i (`.env.test.example`) aluseks kõigile keskkondadele:**

```bash
# Test keskkond (ei vaja muutmist)
cp .env.test.example .env.test
# Kasutab Harjutus 3 väärtusi (postgres, VXCkL39yz...)

# Production keskkond (muuda JWT_SECRET!)
cp .env.test.example .env.prod
nano .env.prod
# Muuda:
#   - JWT_SECRET=<openssl rand -base64 32 tulemus>
#   - LOG_LEVEL=warn
#   - SPRING_LOG_LEVEL=WARN
#   - NODE_ENV=production
#   - SPRING_PROFILE=prod
# POSTGRES_PASSWORD=postgres jääb samaks (harjutuse lihtsustus)
```

**💡 Märkus:** `.env.test.example` on template, `.env.prod.example` on näidisfail solution kaustas.

---

### 2️⃣ Genereeri JWT Secret (PRODUCTION)

**Harjutuses:**
- DB parool: `postgres` (sama mis TEST, ei vaja genereerimist)
- JWT Secret: Genereeri ERINEV hash (32 bytes, Base64)

```bash
# JWT Secret (32 bytes, base64) - PEAB olema erinev TEST'ist!
openssl rand -base64 32

# Või kasutades Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

**Näide:**
```bash
$ openssl rand -base64 32
8K+9fR3mL7vN2pQ6xW1yZ4tH5jB0cE8fG9aD3sK7mL1=
```

**🏢 Reaalses Production Keskkonnas:**
Genereerid ka DB parooli (eraldi server → eraldi volume):
```bash
openssl rand -base64 48  # PostgreSQL password
```

---

### 3️⃣ Kasutamine

#### **TEST keskkond** (nõrgad paroolid OK):
```bash
# Käivita koos .env.test failiga
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d

# Või lihtsalt (kui .env.test on kopeeritud → .env)
cp .env.test .env
docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d
```

#### **PRODUCTION keskkond** (tugevad paroolid KOHUSTUSLIKUD):
```bash
# 1. Muuda .env.prod paroolid
nano .env.prod

# 2. Käivita
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# 3. Kontrolli, et paroolid on rakendatud
docker exec postgres-user env | grep POSTGRES_PASSWORD
```

---

## ⚙️ Kuidas See Töötab?

### `docker-compose.yml` kasutab vaikeväärtustega env variable:

```yaml
environment:
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
  #                   ↑ Env var        ↑ Default
```

**Tähendus:**
- **Kui** `.env` failis on `POSTGRES_PASSWORD=strong_password` → kasutab seda
- **Kui** `.env` faili pole või muutuja puudub → kasutab default'i `postgres`

---

## 🛡️ Turvalisuse Best Practices

### ✅ DO (Tee nii):

1. **Production'is kasuta ALATI `.env.prod` faili**
   ```bash
   docker-compose --env-file .env.prod up -d
   ```

2. **Genereeri paroolid automaatselt**
   ```bash
   echo "POSTGRES_PASSWORD=$(openssl rand -base64 48)" >> .env.prod
   echo "JWT_SECRET=$(openssl rand -base64 32)" >> .env.prod
   ```

3. **Hoia `.env.prod` turvaliselt**
   - Password manager (1Password, Bitwarden)
   - Vault (HashiCorp Vault)
   - Cloud secrets (AWS Secrets Manager, Azure Key Vault)
   - **MITTE git'is!**

4. **Kasuta erinevaid JWT secret'e igale keskkonnale**
   - Test: `VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=` (Base64, 256-bit)
   - Production: `8K+9fR3mL7vN2pQ6xW1yZ4tH5jB0cE8fG9aD3sK7mL1=` (ERINEV Base64 hash)

   **Harjutuses:** DB parool on sama (`postgres`) - volume konflikt!
   **Reaalses elus:** DB paroolid ka erinevad (eraldi serverid)

5. **Rotate (vaheta) paroole regulaarselt**
   ```bash
   # Uus parool
   NEW_PASS=$(openssl rand -base64 48)

   # Uuenda .env.prod
   sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_PASS/" .env.prod

   # Restart teenused
   docker-compose --env-file .env.prod up -d --force-recreate
   ```

---

### ❌ DON'T (Ära tee nii):

1. ❌ **EI commit'i `.env.prod` git'i**
   ```bash
   # ✅ Kontrolli, et .gitignore on õige
   cat .gitignore | grep .env
   ```

2. ❌ **EI kasuta sama parooli kõikides keskkondades**

3. ❌ **EI jaga paroole Slack'is, email'is, jne**

4. ❌ **EI pane paroole otse docker-compose.yml faili production'is**
   ```yaml
   # ❌ VALE (production)
   environment:
     POSTGRES_PASSWORD: my-secret-password

   # ✅ ÕIGE (production)
   environment:
     POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # Tuleb .env.prod failist
   ```

---

## 📝 Näited (Harjutus)

### TEST keskkond (`.env.test`):
```bash
POSTGRES_PASSWORD=postgres  # Harjutus 3 vaikeväärtus
JWT_SECRET=VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=  # Base64, 256-bit
NODE_ENV=development
LOG_LEVEL=debug
SPRING_PROFILE=dev
```

### PRODUCTION keskkond (`.env.prod`):
```bash
POSTGRES_PASSWORD=postgres  # Sama mis TEST (harjutuse lihtsustus!)
JWT_SECRET=8K+9fR3mL7vN2pQ6xW1yZ4tH5jB0cE8fG9aD3sK7mL1=  # ERINEV hash!
NODE_ENV=production
LOG_LEVEL=warn
SPRING_PROFILE=prod
```

**🏢 Reaalse Production `.env.prod` näide:**
```bash
POSTGRES_PASSWORD=kJ8xN2vL9mR3qW5tY8pF7nH6zX4cV1bM...  # ERINEV tugev hash
JWT_SECRET=8K+9fR3mL7vN2pQ6xW1yZ4tH5jB0cE8fG9aD3sK7mL1=
NODE_ENV=production
LOG_LEVEL=warn
```

---

## 🔍 Troubleshooting

### Probleem: "Parool ei tööta"

```bash
# Kontrolli, kas .env fail laaditakse
docker-compose --env-file .env.prod config | grep POSTGRES_PASSWORD

# Kontrolli konteineris
docker exec postgres-user env | grep POSTGRES_PASSWORD
```

### Probleem: "Unustasin production parooli"

```bash
# 1. Seiska konteinerid
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

# 2. Kustuta volumes (⚠️ ANDMEKADU!)
docker volume rm postgres-user-data postgres-todo-data

# 3. Genereeri uued paroolid
openssl rand -base64 48  # Kopeeri .env.prod faili

# 4. Käivita uuesti
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
```

**Parem lahendus:** Hoia `.env.prod` backup'it password manager'is!

---

## 📚 Viited

- **Docker Compose Environment Variables:** https://docs.docker.com/compose/environment-variables/
- **PostgreSQL Security:** https://www.postgresql.org/docs/current/auth-password.html
- **OWASP Secrets Management:** https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html

---

**Viimane uuendus:** 2025-12-13
