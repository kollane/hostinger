# Dive Tool - Docker Image Kihtide Analüüs

**Dive** on üks tähtsamaid tööriistu DevOps-i maailmas, sest see näitab sulle **täpselt**, kuidas sinu Docker image tegelikult välja näeb "seest". See on nagu röntgeniks konteinerile.

***

### Mis on Dive ja miks see oluline?

Kujuta ette, et sul on karp (Docker image). Väljast näeb ta väike ja puhas. Aga seest? Seal võib olla vanapabereid, raisatuid, ja kõike muud, mida sa ei näe, kuni karp lahti tead.

**Dive** avab selle karbi lahti ja näitab:

1. Iga **kihti** (layer), millest image koosneb.
2. Täpselt, milliseid faile **millises kihis** lisati, muudeti ja kustutati.
3. Kui palju ruumi on **raisatud** (st failid, mis kustutatigi hiljem).
4. Image'i **efektiivsushinnangu** 0-100%.

***

### Kuidas Dive töötab?

Docker image koosnevad **kihtidest** (layers), nagu pirukakoor.

```
┌─────────────────────────────────────┐  ← Kiht 4 (COPY app.jar)
│  /app/app.jar (5 MB)                │
├─────────────────────────────────────┤
│  (Ehitus käsk, kuid failid kustutat)│  ← Kiht 3 (RUN rm -rf /tmp/*)
│                                     │
├─────────────────────────────────────┤
│  /usr/lib/java, /root/.m2 jne       │  ← Kiht 2 (RUN apt-get install ...)
│  (sinu puhul peaks siin MIDAGI ei   │     JA KULUB KIHIS 3 MINEMA!
│   olema, sest multi-stage!)         │
├─────────────────────────────────────┤
│  Linux OS (Alpine, Debian jne)      │  ← Kiht 1 (FROM image:tag)
└─────────────────────────────────────┘
```

**Probleem:** Kui Kiht 2-s installid 500 MB suuruse Maven repo ja Kiht 3-s käsk `RUN rm -rf ~/.m2`, siis:

- Maven repo **ei kao** tegelikult image'ist.
- See on jätkuvalt kihis 2 olemas, lihtsalt "invisible" marked-ina.
- Lõpp-image on siiski 500 MB suurem, kui peaks.

**Dive** näitab sulle seda probleemi otsekohe.

***

### Kuidas Dive'i kasutada (Step-by-Step)?

#### 1. Installi Dive

Kaks viisi:

**Viis A: Dockerina (No Install)**

```bash
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest minu-app:v1
```

**Viis B: Native Binary**

```bash
# macOS
brew install dive

# Linux
curl -OL https://github.com/wagoodman/dive/releases/download/v0.12.0/dive_0.12.0_linux_amd64.tar.gz
tar xzf dive_0.12.0_linux_amd64.tar.gz
sudo mv dive /usr/local/bin/
```


#### 2. Käivita Dive oma image'ile

```bash
dive minu-app:v1
```

Või kui sa äsja ehitasid:

```bash
docker build -t minu-app:v1 . && dive minu-app:v1
```


***

### Dive'i kasutajaliides (UI)

Kui sa Dive'i käivitad, näed ekraanil **kaks paneelit**:

```
╔════════════════════════════════════════════════════════════════╗
║  Layers (Vasakul)        │  File Tree (Paremal)              ║
║                          │                                    ║
║  Kiht 1: base            │  / (root)                          ║
║  ├─ 120 MB               │  ├─ usr/                           ║
║  │  Added: 45 files      │  │  ├─ bin/                        ║
║  │                       │  │  └─ lib/                        ║
║  Kiht 2: maven-builder   │  ├─ app/                           ║
║  ├─ 320 MB               │  │  └─ app.jar  (5 MB) [new]       ║
║  │  Added: 2245 files    │  └─ root/                          ║
║  │  Removed: 0 files     │     └─ .m2/ (REMOVED IN NEXT)      ║
║  │                       │                                    ║
║  Kiht 3: runtime         │  Legend:                           ║
║  ├─ 0 MB                 │  [deleted] = kustutatakse          ║
║  │  Added: 0 files       │  [modified] = muudatakse           ║
║  │  Removed: 2000 files  │  [new] = lisatakse                 ║
║                          │                                    ║
║ Efficiency: 95%          │                                    ║
║ Wasted Space: 15 MB      │                                    ║
╚════════════════════════════════════════════════════════════════╝
```


***

### Nupud ja navigatsioon

| Nupp | Tegevus |
| :-- | :-- |
| **↑ / ↓** | Navigeeri kihtide vahel |
| **← / →** | Navigeeri failipuus |
| **Space** | Laienda/salvesta faili/kausta |
| **Ctrl+L** | Kuva ainult "wasted" failid (kriitiliselt oluline!) |
| **Ctrl+U** | Kuva ainult "untagged" kihid |
| **Delete** | Näita, mis kustutatakse valitud kihis |
| **Ctrl+Q** | Väljumine |


***

### Praktiline näide: Halb vs Hea Dockerfile

#### ❌ HALB Dockerfile (Multi-stage puudub)

```dockerfile
FROM maven:3.8-openjdk-17

WORKDIR /app
COPY . .
RUN mvn package -DskipTests
RUN rm -rf ~/.m2  # See ei aita, kuna .m2 on juba image'is!

ENTRYPOINT ["java", "-jar", "target/app.jar"]
```

**Dive näitab:**

```
Layer 1: maven:3.8-openjdk-17 (1.2 GB)
  Added: 45000+ files (Maven, compiler, jne)

Layer 2: COPY . . (50 MB)
  Added: lähtekoodi failid

Layer 3: RUN mvn package (200 MB)
  Added: compiled JAR + Maven cache

Layer 4: RUN rm -rf ~/.m2 (0 MB)
  Removed: 200 MB failid, AGA need on ikka image'is!

─────────────────────────────────────
Efficiency: 45%
Wasted Space: 200 MB
─────────────────────────────────────
```

**Probleem:** Image on 1.45 GB! Dive näitab punases värvuses, et see on hull.

***

#### ✅ HAIDIV Dockerfile (Multi-stage)

```dockerfile
# Stage 1: Builder
FROM maven:3.8-openjdk-17 AS builder
WORKDIR /app
COPY . .
RUN mvn package -DskipTests

# Stage 2: Runtime (puhas leht!)
FROM openjdk:17-slim
WORKDIR /app
COPY --from=builder /app/target/app.jar .
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Dive näitab:**

```
Layer 1: FROM openjdk:17-slim (180 MB)
  Added: Java runtime (ainult)

Layer 2: COPY --from=builder /app/target/app.jar (50 MB)
  Added: app.jar (5 MB)

─────────────────────────────────────
Efficiency: 99%
Wasted Space: 0 MB
─────────────────────────────────────
```

**Tulemus:** Image on 235 MB! **6x väiksem** ja **puhas**.

***

### Dive'i väljund käsurealt (CSV export)

Kui tahad automatiseerida ja CI/CD-sse integreerida:

```bash
dive minu-app:v1 --json dive-report.json
```

Selle JSON faili saad edasi anda andmeanalüütika tööriistale või kirjutada skripti, mis kontrollib, kas efektiivsus on piisav:

```bash
# Näide: Fail CI/CD, kui efektiivsus < 95%
dive minu-app:v1 --json report.json && \
  EFFICIENCY=$(jq '.ImageEfficiencyScore' report.json) && \
  if (( $(echo "$EFFICIENCY < 95" | bc -l) )); then \
    echo "FAIL: Image efficiency is $EFFICIENCY%, need >= 95%"; \
    exit 1; \
  fi
```


***

### Kokkuvõtted Dive'i kasutamisest

**Millal kasutada:**

- Pärast iga `docker build` käsku (eriti algselt).
- Kui image'i suurus kasvab ootamatult.
- Multi-stage optimeerimise testimiseks.

**Mida otsida:**

1. **Efficiency Score:** Peaks olema > 95%.
2. **Wasted Space:** Peaks olema < 1% kogu suurusest.
3. **Faili puus:** Kas näed seal "ehitusprahti"? (Maven, GCC, lähtekood)

**Edu kriteerium:**

- Näed ainult `openjdk`, `node` või muud runtime ja lõpp-binaaari.
- Ehitus-teekid (Maven, GCC, apt-get paketid) **ei ole** näha.

Kui su Dive'i raport näeb hea välja, oled valmis Kubernetesele liikuma!

---

**Viimane uuendus:** 2025-12-12
**Tüüp:** Koodiselgitus
**Kasutatakse:** Lab 1, Harjutus 05 (Samm 7: Image Quality Verification)
