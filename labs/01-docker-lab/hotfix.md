# Docker Exec Hotfix - VPS Security Wrapper

## 🐛 Probleem

VPS'is on bash function, mis automaatselt lisab `--security-opt apparmor=unconfined` **KÕIGILE** `docker exec`, `docker run` ja `docker create` käskudele.

### Bash Function VPS'is

```bash
docker ()
{
    case "$1" in
        run | exec | create)
            /usr/bin/docker "$1" --security-opt apparmor=unconfined "${@:2}"
        ;;
        *)
            /usr/bin/docker "$@"
        ;;
    esac
}
```

### Probleem

Kui kasutad käsku:
```bash
docker exec -i postgres-user psql -U postgres -d user_service_db
```

See muutub:
```bash
/usr/bin/docker exec --security-opt apparmor=unconfined -i postgres-user psql -U postgres -d user_service_db
```

**VIGA:** Docker ootab flag'e (`-i`) **ENNE** konteineri nime, aga wrapper lisab `--security-opt` pärast `exec` ja enne `-i`, mis põhjustab parsing'u vea:

```
unknown flag: --security-opt
```

## ✅ Lahendused

### Variant 1: Kasuta Native Docker'it (PARIM TOOTMISEKS)

```bash
/usr/bin/docker exec -i postgres-user psql -U postgres -d user_service_db <<'EOF'
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
```

### Variant 2: Unset Function Ajutiselt (KIIRE FIX)

```bash
# Eemalda wrapper session'is
unset -f docker

# Nüüd toimivad tavalised docker käsud
docker exec -i postgres-user psql -U postgres -d user_service_db <<'EOF'
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
```

### Variant 3: Paranda Bash Function (PIKAAJALINE FIX)

Lisa `.bashrc` või `.bash_profile` faili:

```bash
docker ()
{
    case "$1" in
        run | create)
            /usr/bin/docker "$1" --security-opt apparmor=unconfined "${@:2}"
        ;;
        exec)
            # Eralda flag'id ja argumendid
            shift
            local flags=()
            local args=()
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -*)
                        flags+=("$1")
                        shift
                        ;;
                    *)
                        args+=("$@")
                        break
                        ;;
                esac
            done
            /usr/bin/docker exec "${flags[@]}" --security-opt apparmor=unconfined "${args[@]}"
        ;;
        *)
            /usr/bin/docker "$@"
        ;;
    esac
}
```

Seejärel:
```bash
source ~/.bashrc
```

### Variant 4: Alias (LIHTNE, ÕPILASTELE)

```bash
# Lisa session'i algusesse
alias docker-native='/usr/bin/docker'

# Kasuta aliast kõigis SQL käskudes
docker-native exec -i postgres-user psql -U postgres -d user_service_db <<'EOF'
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
```

## 📝 Soovitused Harjutustele

### Harjutus 02: Multi-Container Setup

Lisa **Samm 0** (enne PostgreSQL käivitamist):

```markdown
### Samm 0: VPS Docker Wrapper Fix

⚠️ **OLULINE (ainult VPS'is):** VPS'is on Docker wrapper, mis võib põhjustada probleeme `docker exec` käskudega.

**Lahendus 1: Kasuta native Docker'it (SOOVITATUD)**

Kõigis `docker exec` käskudes asenda `docker` → `/usr/bin/docker`:

\`\`\`bash
# Asemel: docker exec -i postgres-user psql ...
# Kasuta: /usr/bin/docker exec -i postgres-user psql ...
\`\`\`

**Lahendus 2: Eemalda wrapper ajutiselt**

\`\`\`bash
# Eemalda wrapper session'is
unset -f docker

# Nüüd toimivad tavalised docker käsud
docker exec -i postgres-user psql ...
\`\`\`

**Kontrolli:**

\`\`\`bash
# Kontrolli, kas wrapper on aktiivne
type docker

# Kui näed "docker is a function", kasuta ülaltoodud lahendusi
# Kui näed "docker is /usr/bin/docker", pole wrapper'it
\`\`\`
```

## 🔍 Diagnoos

### Kontrolli Docker Wrapper'it

```bash
# Kontrolli, kas docker on function
type docker

# Peaks näitama:
# docker is a function
# docker ()
# {
#     case "$1" in
#         run | exec | create)
#             /usr/bin/docker "$1" --security-opt apparmor=unconfined "${@:2}"
#         ;;
#         ...
# }
```

### Kontrolli Bash Config

```bash
# Otsi docker function'i
grep -n "docker ()" ~/.bashrc ~/.bash_profile ~/.profile 2>/dev/null
```

### Kontrolli Aliased

```bash
# Vaata kõiki aliaseid
alias | grep docker
```

## 📊 Mõjutatud Harjutused

| Harjutus | Mõjutatud Käsud | Fix |
|----------|-----------------|-----|
| **02-multi-container** | Samm 2, 3 (CREATE TABLE) | Kasuta `/usr/bin/docker exec` |
| **03-networking** | Samm 2, 3 (CREATE TABLE) | Kasuta `/usr/bin/docker exec` |
| **04-volumes** | Samm 4 (CREATE TABLE) | Kasuta `/usr/bin/docker exec` |

## 🎯 Õpilaste Juhised

**Enne Lab 1 alustamist:**

```bash
# 1. Kontrolli, kas wrapper on aktiivne
type docker

# 2. Kui näed "docker is a function", eemalda see:
unset -f docker

# 3. Verifitseeri
type docker
# Peaks näitama: docker is /usr/bin/docker

# 4. Nüüd võid jätkata harjutustega normaalset süntaksit kasutades
```

**VÕI lisa alias `.bashrc` faili:**

```bash
echo "alias docker-native='/usr/bin/docker'" >> ~/.bashrc
source ~/.bashrc

# Kasuta docker-native kõigis heredoc käskudes
docker-native exec -i postgres-user psql ...
```

## 🚨 Kriitilised Käsud

Need käsud **EI TÖÖTA** wrapper'iga:

```bash
❌ docker exec -i postgres-user psql -U postgres -d user_service_db <<EOF
❌ docker exec -i postgres-user psql -U postgres -d user_service_db -c "CREATE TABLE ..."
❌ cat file.sql | docker exec -i postgres-user psql -U postgres -d user_service_db
```

Need käsud **TÖÖTAVAD** wrapper'iga:

```bash
✅ /usr/bin/docker exec -i postgres-user psql -U postgres -d user_service_db <<EOF
✅ docker exec postgres-user psql -U postgres -d user_service_db -c "SELECT 1;"  # Ilma -i flag'ita
✅ docker ps
✅ docker logs postgres-user
```

## 📚 Tehnilised Detailid

### Miks `--security-opt` on vajalik?

**AppArmor (Application Armor)** on Linux kernel'i turvamoodul, mis piirab protsesside õigusi:

- **Docker vaikimisi:** Laeb kõigile konteineritele `docker-default` AppArmor profiili
- **Profiil piirab:** Võrguligipääs, failisüsteemi ligipääs, kernel võimalused
- **VPS eesmärk:** Lihtsamaks õppimiseks eemaldada AppArmor piirangud

**`apparmor=unconfined` tähendab:**
```
"Ära kasuta AppArmor profiili sellel konteineril"
= Konteiner töötab ILMA AppArmor piiranguteta
= Tavapärane Linux protsess (ainult user permissions kehtivad)
```

### Miks wrapper on valesti implementeeritud?

**Probleem 1: Vale positsioon**

Docker CLI järjekord on:
```
docker COMMAND [OPTIONS] CONTAINER [COMMAND] [ARG...]
```

Wrapper lisab `--security-opt` positsioonile:
```
docker exec --security-opt apparmor=unconfined -i postgres-user psql ...
```

See on **VALE**, sest `-i` on `exec` käsu option, mitte konteineri nimi.

**ÕIGE järjekord:**
```
docker exec -i --security-opt apparmor=unconfined postgres-user psql ...
```

**Probleem 2: `docker exec` EI VAJA `--security-opt`**

`--security-opt` on vajalik ainult **`docker run`** ja **`docker create`** käskudele:

```bash
# ✅ Vajalik - loob uue konteineri
docker run --security-opt apparmor=unconfined postgres:16

# ❌ EI OLE vajalik - juba töötav konteiner
docker exec -i postgres-user psql
# (konteiner juba töötab oma AppArmor profiilid seadistatud docker run ajal)
```

### Kuidas parandada wrapper'it?

**Variant 3 (ülalpool)** parsib flag'id korrektselt ja lisab `--security-opt` õigesse kohta, **AGA** see on üle keerulisem kui vaja.

**✅ PARIM LAHENDUS VPS ADMINILE:**

Eemalda `exec` wrapper'ist täielikult, sest `docker exec` ei vaja `--security-opt`:

```bash
docker ()
{
    case "$1" in
        run | create)
            # Ainult run ja create vajavad --security-opt
            /usr/bin/docker "$1" --security-opt apparmor=unconfined "${@:2}"
        ;;
        *)
            # Kõik muud käsud (sh exec) ilma --security-opt'ita
            /usr/bin/docker "$@"
        ;;
    esac
}
```

**Mida see muudab:**
- ✅ `docker run` ja `docker create` lisavad endiselt `--security-opt apparmor=unconfined`
- ✅ `docker exec` töötab normaalset (ilma `--security-opt`'ita, nagu peabki)
- ✅ Kõik muud käsud (`ps`, `logs`, `stop`, jne) töötavad normaalset
- ✅ Õpilased ei kohta enam "unknown flag: --security-opt" viga

**Kuidas paigaldada VPS'is:**

```bash
# 1. Ava bash config
sudo vim /etc/bash.bashrc
# VÕI iga kasutaja jaoks:
vim ~/.bashrc

# 2. Leia olemasolev docker() funktsioon
# 3. Asenda see ülaloleva parandatud versiooniga
# 4. Salvesta

# 5. Lae config uuesti
source /etc/bash.bashrc
# VÕI
source ~/.bashrc

# 6. Testi
type docker
# Peaks näitama uut funktsiooni

# 7. Testi, et exec töötab
docker exec -i <container> echo "Test"
```

## 🔗 Seotud Failid

- `labs/01-docker-lab/exercises/02-multi-container.md` - Samm 2, 3
- `labs/01-docker-lab/exercises/03-networking.md` - Samm 2, 3
- `labs/01-docker-lab/exercises/04-volumes.md` - Samm 4

---

**Viimane uuendus:** 2025-01-25
**Mõjutatud versioonid:** VPS devops-student1, student2, student3
**Staatus:** ⚠️ KRIITILINE - Blokeerib Lab 1 Harjutus 2+

---

## 🔧 VPS Adminile: Püsiv Lahendus

**Paranda wrapper VPS'is**, et õpilased ei kohta enam seda viga:

1. **Ava bash config:**
   ```bash
   sudo vim /etc/bash.bashrc
   ```

2. **Leia ja asenda olemasolev `docker()` funktsioon:**
   ```bash
   docker ()
   {
       case "$1" in
           run | create)
               # Ainult run ja create vajavad --security-opt
               /usr/bin/docker "$1" --security-opt apparmor=unconfined "${@:2}"
           ;;
           *)
               # Kõik muud käsud (sh exec) ilma --security-opt'ita
               /usr/bin/docker "$@"
           ;;
       esac
   }
   ```

3. **Salvesta ja lae uuesti:**
   ```bash
   source /etc/bash.bashrc
   ```

4. **Testi:**
   ```bash
   docker exec -i postgres-user echo "Test töötab!"
   ```

**Tulemus:** Õpilased ei vaja enam `unset -f docker` käsku! ✅
