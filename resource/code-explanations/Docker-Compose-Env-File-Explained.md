# Docker Compose .env Fail - Koodiselgitus
Eesmärk: Defineeri keskkonnamuutujad ühes kohas, mida saad hiljem docker-compose.yml'is kasutada.
Loo .env fail saladustele ja konfiguratsioonile:
vim .env
Lisa järgmine sisu:

# ==========================================================================

# Environment Variables - Docker Compose (LOCAL TESTING)

# ==========================================================================

# TÄHTIS: See fail sisaldab saladusi!

# EI TOHI commit'ida Git'i! Lisa .gitignore'i!

# MÄRKUS: Need on LIHTSAMAD väärtused testimiseks.

# Production'is kasuta .env.prod faili tugevate paroolidega!

# ==========================================================================

# PostgreSQL Credentials

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres  \# Harjutus 3 vaikeväärtus (lihtne local testing jaoks)

# JWT Configuration

JWT_SECRET=VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=  \# Harjutus 3 väärtus
JWT_EXPIRES_IN=1h

# Application Ports (ei kasutata production mode'is - pordid eemaldatud)

USER_SERVICE_PORT=3000
TODO_SERVICE_PORT=8081
FRONTEND_PORT=8080
POSTGRES_USER_PORT=5432
POSTGRES_TODO_PORT=5433

# Database Names

USER_DB_NAME=user_service_db
TODO_DB_NAME=todo_service_db

# Node.js Environment

NODE_ENV=production

# Java Options

JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0

# Spring Profile

SPRING_PROFILE=prod

See samm võtab kõik rakenduse konfiguratsiooni ja saladused (paroolid, JWT võtmed jms) ja koondab need ühte keskseks `.env` faili, et docker-compose saaks neid muutujana kasutada ning et neid ei satuks kogemata Git’i ega pildi sisse.[^2][^3]

## Mis on `.env` fail siin?

- Tavaline tekstifail samas kataloogis, kus on `docker-compose.yml`, kus iga rida on kujul `NIMI=väärtus` ilma jutumärkideta.[^4]
- Docker Compose loeb sealt võtme–väärtuse paarid ja asendab need komponis `docker-compose.yml` sees (nt `${POSTGRES_USER}`) ning/või annab need konteinerite keskkonnamuutujatena edasi.[^6][^2]


## Miks hoida seda failis, mitte YAML-is?

- Üks koht kõikidele seadistustele: paroolid, portid, DB nimed, profiilid jms, mida muudad tihti või mis on masina/spetsiifilised.[^7][^4]
- Sama `docker-compose.yml` saab kasutada nii lokaalses testimises kui tootmises, vahetades ainult `.env` faili (`.env`, `.env.prod`, jne).[^6][^5]


## Turvalisus ja Git

- Failis on paroolid ja JWT salavõti, seega seda ei tohi Git’i commit’ida; sellepärast käib sinna kommentaar “lisa `.gitignore`‑i”.[^6][^4]
- Praktika on hoida eraldi näiteks `.env` (simple, local) ja `.env.prod` (tugevad paroolid, tootmine) ning jagada tootmisfaili turvalise kanali kaudu, mitte repo kaudu.[^6][^8]


## Mida iga plokk semantiliselt tähendab?

- **PostgreSQL Credentials** – kasutaja+parool mõlema Postgres konteineri jaoks; lihtsad väärtused, sobivad ainult lokaalseks harjutamiseks.
- **JWT Configuration** – `JWT_SECRET` on võti, millega teenused signeerivad ja valideerivad token’eid; `JWT_EXPIRES_IN=1h` ütleb, kui kaua token kehtib.
- **Application Ports** – defineerib, mis hostipordid seotakse teenuste külge lokaalses režiimis; tootmises võid lasta liiklusel tulla läbi reverse proxy või muude portide, seetõttu “ei kasutata production’is”.[^4]
- **Database Names** – eristab kasutaja-teenuse ja TODO-teenuse andmebaase samas Postgres instantsis, nii et skeemid ei läheks sassi.
- **NODE_ENV, JAVA_OPTS, SPRING_PROFILE** – teenuste käitumise nuppud: Node jaoks “production mode”, Java jaoks konteinerile optimeeritud mälu seaded ning Spring’ile profiil `prod`, mille järgi ta laeb vastava konfiguratsiooni.[^8]


## Kuidas seda docker-compose’is kasutatakse?

- `docker-compose.yml` failis viitad neile muutujatele kujul `${POSTGRES_USER}`, `${JWT_SECRET}`, `${SPRING_PROFILE}` jne; Compose asendab need väärtustega `.env` failist enne teenuste käivitamist.[^1][^4]
- Kui hiljem vajad tootmises teisi väärtusi, käivitad sama stack’i kas `--env-file .env.prod` või kasutad tootmisserveris teist `.env` faili, ilma et peaksid Compose’i või image’e muutma.[^6][^6]
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^20][^9]</span>

<div align="center">⁂</div>

[^1]: https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/

[^2]: https://www.hostinger.com/tutorials/what-is-docker-compose

[^3]: https://www.hostinger.com/support/12040789-hostinger-docker-manager-for-vps-simplify-your-container-deployments/

[^4]: https://simi.studio/en/ways-to-set-environment-variables-with-docker-compose/

[^5]: https://www.warp.dev/terminus/docker-compose-env-file

[^6]: https://overcast.blog/multi-environment-deployments-with-docker-a-guide-890e193191b6

[^7]: https://dimmaski.com/env-files-docker/

[^8]: https://stackoverflow.com/questions/73651880/failed-to-load-env-file-but-still-gets-the-environment-variables

[^9]: https://stackoverflow.com/questions/79612945/passing-host-environment-variables-to-docker-compose-using-visual-studio

[^10]: https://github.com/RawSmokeTerribilus/docker-compose-homelab

[^11]: https://stackoverflow.com/questions/43267413/how-to-set-environment-variables-from-env-file

[^12]: https://forums.docker.com/t/docker-compose-not-seeing-environment-variables-on-the-host/11837

[^13]: https://info.undp.org/docs/pdc/Documents/BTN/Env mgt tools and techniques.pdf

[^14]: https://www.youtube.com/watch?v=L3E4-e2If7w

[^15]: https://jules.google/docs/changelog/

[^16]: https://muneebkhawaja.com/docker-compose-env-files-and-portainer/

[^17]: https://www.reddit.com/r/docker/comments/jbkc0w/how_do_you_manage_env_files_for_docker_builds/

[^18]: https://owaspsamm.org/model/operations/environment-management/

[^19]: https://stackoverflow.com/questions/40525230/specify-the-env-file-docker-compose-uses

[^20]: https://docs.docker.com/compose/how-tos/environment-variables/envvars/

---

**Viimane uuendus:** 2025-12-13
**Tüüp:** Koodiselgitus (AI-genereeritud)
**Kasutatakse:** Lab 2, Harjutus 4 (Keskkondade haldus)
