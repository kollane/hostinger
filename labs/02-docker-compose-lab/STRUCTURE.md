# Lab 2: Docker Compose - Struktuuri Ülevaade

## Loodud Failid

### Harjutused (exercises/)
- **01-basic-compose.md** (561 rida, 60 min) - PostgreSQL + Backend
- **02-full-stack.md** (633 rida, 60 min) - Frontend lisamine
- **03-dev-prod-envs.md** (633 rida, 45 min) - Dev/Prod keskkonnad
- **04-dual-postgres.md** (615 rida, 45 min) - Containerized vs External DB

**Kokku:** 2442 rida harjutusi

### Lahendused (solutions/)
- **docker-compose.yml** - Base full-stack konfiguratsioon
- **docker-compose.dev.yml** - Development override
- **docker-compose.prod.yml** - Production override
- **docker-compose.external-db.yml** - External PostgreSQL pattern
- **.env.example** - Environment variables template
- **.env.dev** - Dev environment
- **.env.prod** - Prod environment
- **.env.external** - External DB environment
- **README.md** (405 rida) - Kasutamisjuhend

## Harjutuste Progressioon

```
Harjutus 1: Basic Compose (60 min)
    └─> PostgreSQL + Backend
         └─> Õpid: services, volumes, networks, health checks

Harjutus 2: Full Stack (60 min)
    └─> Harjutus 1 + Frontend
         └─> Õpid: 3-tier architecture, depends_on, port mapping

Harjutus 3: Dev/Prod Environments (45 min)
    └─> Harjutus 2 + separate configs
         └─> Õpid: override pattern, env files, hot reload vs optimized

Harjutus 4: Dual PostgreSQL (45 min)
    └─> Võrdleb kahte deployment pattern'i
         └─> Õpid: containerized vs external, backup strategies
```

## Kvaliteet

✅ **Struktuur:** Järgib Lab 1 formaati täpselt
✅ **Keel:** Eesti keel + inglise tehniline terminoloogia
✅ **Progressiivne:** Iga harjutus ehitab eelmise peale
✅ **Põhjalik:** Keskelt 560-630 rida harjutuse kohta
✅ **Praktiline:** Kõik käsud on töötavad
✅ **Pedagoogiline:** Selgitused, näited, troubleshooting
✅ **Production-ready:** Best practices, security, optimization

## Kasutatavus

Õppija saab:
1. Alustada Harjutusest 1 (lihtne 2-service stack)
2. Liikuda Harjutusele 2 (täielik 3-tier stack)
3. Õppida Harjutuses 3 (dev vs prod keskkonnad)
4. Mõista Harjutuses 4 (deployment patterns)

Iga harjutus sisaldab:
- 📋 Ülevaade ja eesmärk
- 🎯 Õpieesmärgid (checkboxed)
- 🏗️ Arhitektuuridiagramm (ASCII)
- 📝 Step-by-step sammud
- ✅ Kontrollinimekiri
- 🧪 Testid
- 🎓 Õpitud mõisted
- 💡 Parimad tavad
- 🐛 Troubleshooting
- 🔗 Link järgmisele harjutusele

## Lahenduste Täielikkus

Solutions kaust sisaldab:
- 4 erinevat compose faili (base, dev, prod, external)
- 4 environment faili (.example, .dev, .prod, .external)
- Põhjalik README kasutusjuhenditega
- Backup/restore juhised
- Troubleshooting guide
- Best practices

**Labor 2 on 100% valmis ja valmis kasutamiseks! ✅**
