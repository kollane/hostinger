# Paroolide ja Saladuste Haldamine

## 🔐 Turvalisuse Mudel

| Keskkond | Paroolide Allikas | Turvalisus | Kas commit'ida git'i? |
|----------|-------------------|------------|----------------------|
| **Local Dev** | Hardcoded defaults (`postgres`) | ⚠️ Nõrk (OK local) | ✅ Jah (docker-compose.yml) |
| **Test** | `.env.test` fail | ⚠️ Nõrk (OK test) | ✅ Jah (example fail) |
| **Prelive** | `.env.prelive` fail | ✅ Tugev | ❌ **EI! (.gitignore)** |
| **Production** | `.env.prod` fail | ✅ Väga tugev | ❌ **EI KUNAGI!** |

---

## 📋 Kiire Alustamine

### 1️⃣ Loo `.env` failid template'idest

```bash
# Test keskkond
cp .env.test.example .env.test
# Hardcoded test paroolid on OK (ei lähe git'i)

# Prelive keskkond
cp .env.prelive.example .env.prelive
nano .env.prelive  # Muuda POSTGRES_PASSWORD ja JWT_SECRET

# Production keskkond
cp .env.prod.example .env.prod
nano .env.prod  # MUUDA KINDLASTI kõik paroolid!
```

---

### 2️⃣ Genereeri Tugevad Paroolid (Production)

```bash
# PostgreSQL parool (48 bytes, base64)
openssl rand -base64 48

# JWT Secret (32 bytes, base64)
openssl rand -base64 32

# Või kasutades pwgen (kui installitud)
pwgen -s 48 1  # PostgreSQL
pwgen -s 32 1  # JWT secret
```

**Näide:**
```bash
$ openssl rand -base64 48
kJ8xN2vL9mR3qW5tY8pF7nH6zX4cV1bM9sA2dG5hT3jK8lP0oI9uY7eR6tW4qX3zN2

$ openssl rand -base64 32
VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
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

4. **Kasuta erinevaid paroole igale keskkonnale**
   - Test: `test123` (lihtne, debugging)
   - Prelive: `prelive_strong_pass_456!` (tugev)
   - Production: `kJ8xN2vL9mR3qW5tY8pF7nH6zX4cV1bM...` (väga tugev, genereeritud)

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

## 📝 Näited

### TEST keskkond (`.env.test`):
```bash
POSTGRES_PASSWORD=test123
JWT_SECRET=test-secret-not-for-production
LOG_LEVEL=debug
```

### PRODUCTION keskkond (`.env.prod`):
```bash
POSTGRES_PASSWORD=kJ8xN2vL9mR3qW5tY8pF7nH6zX4cV1bM9sA2dG5hT3jK8lP0oI9uY7eR6tW4qX3zN2
JWT_SECRET=VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
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

**Viimane uuendus:** 2025-12-11
