# Mitmeastmeline build – üksikasjalik seletus

See Dockerfile kasutab **Docker mitmeastmelist ehitamist** (multi-stage build), et luua kiire, turvalisem ja väiksema suurusega Node.js konteinerit. Iga osa on hoolikalt planeeritud.

---

## BuildKit ja syntax versioon

```dockerfile
# syntax=docker/dockerfile:1.4
# ☝️ BuildKit syntax versiooni määrang - vähendab UndefinedVar hoiatusi
```

BuildKit syntax versiooni määrang - vähendab UndefinedVar hoiatusi tähendab, et Docker kasutab BuildKit mootorit, mis on kiirem ja toetab laiendatud funktsioonid (näiteks `RUN --mount`, paremat kihistamist jne). Versioon 1.4 on stabiilne ja turvaline valik.

---

## Global ARG deklaratsioonid enne esimest FROM

```dockerfile
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG NO_PROXY=""
```

Need ARG'd on deklareeritud **enne esimest `FROM`**, mis tähendab, et need on "globaalsed" ehitamise argumendid ja ei kuulu ühtegi konkreetsesse stage'i.

**Miks see oluline on:**

- ARG'd, mis on enne `FROM`, on nähtavad kogu ehitamise protsessis, kuid neid saab iga stage'is kasutada ainult siis, kui uuesti deklareerid ilma väärtuseta.
- `HTTP_PROXY`, `HTTPS_PROXY` ja `NO_PROXY` on Dockeri sisseehitatud build-arg'd, mis aitavad npm-il (ja muudel tööriistadel) ligipääs internetti, kui oled firma proxy taga.
- Kui sa käivitad `docker build --build-arg HTTP_PROXY=http://proxy.company.com:8080 .`, saab see väärtus edasi ARG'ile.

**Märkus pedagoogiline:** Kuigi BuildKit tunneb neid ARG'e automaatselt (built-in), me deklareerime need siiski eksplitsiitselt, et:
1. Dokumenteerida oodatud ARG'e (self-documenting Dockerfile)
2. Seada vaikeväärtused `""` (tühi string, mitte `undefined`)
3. Algajad näevad kohe, kust `${HTTP_PROXY}` tuleb

---

## Stage 1: Dependencies – npm sõltuvuste installimine

```dockerfile
FROM node:22-slim AS dependencies

ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY}
```

### Base image

`node:22-slim` on **ametlik Node.js pilt, mis on väga kerge** – see sisaldab ainult Node.js'i ja npm'i, ilma ebavajalike tööriistadeta. Slim versioon on palju väiksem kui täisversioon (näiteks `node:22` või `node:22-bookworm`).

### ENV ja proxy

`ENV` käsk määrab **keskkonna muutujad ainult selles stage'is**. Kui varasemast ARG'ist saadi proxy aadress, siis seab `${HTTP_PROXY}` selle väärtuse ENV muutujasse. `npm ci` loeb neid muutujaid automaatselt, et teada, kus interneti kaudu langeda, kui oled proxy taga.

```dockerfile
WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production
```

### Cataloog ja copy

`WORKDIR /app` määrab töökataloogi – kõik järgnevad käsud toimuvad selles kataloogis. `COPY package*.json ./` kopeerib **mõlemad failid** (kui need on olemas):

- `package.json` – projekti metaandmed ja peamised sõltuvused
- `package-lock.json` – täpne versioonide lukk, et taasprodutseeritav paigaldus

### npm ci ja caching

`npm ci --only=production` teeb **puhtast paigaldust** (clean install) otse `package-lock.json`'ist, paigaldades ainult **production sõltuvused**, mitte devDependencies.

**Miks `npm ci` ja mitte `npm install`?**

- `npm ci` on mõeldud automatiseeritud keskkondadesse (CI/CD, konteinerite ehitamine). See tagab, et sama versioon installitakse iga kord.
- `npm install` võib muuta `package-lock.json`'i ja lisada uusi versioone, mida sa ei taha.
- `--only=production` tähendab, et devDependencies (test-raamistikud, linterid jne) jäetakse paigaldamata, vähendades image suurust ja parandades turvalisust.

**Kihistamine ja cache:**

Kui sa hiljem muudad äpi koodi, kuid `package*.json` jääb samaks, ei taasehita Docker seda `npm ci` käsku – kasutab eelmisest ehitusest salvestatud layer'it. See säästab ehitamise aega dragult.

---

## Stage 2: Runtime – rakenduse käitamine

```dockerfile
FROM node:22-slim
WORKDIR /app
```

Uus `FROM` käsk alustab **teisest pildist** – puhtast `node:22-slim` pildist. Esimese stage'i sisu (sh `node_modules`) **ei liiguta automaatselt** – see kopeeriakse selgesõnaliselt.

---

### Non-root kasutaja loomine

```dockerfile
RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs nodejs
```

See käsk loob:

- **Grupp `nodejs`** GID-ga 1001
- **Kasutaja `nodejs`** UID-ga 1001, kuulub gruppi `nodejs`

`-r` lipp teeb kasutajast "süsteemi kasutaja" (system user) – tal ei ole login shell'i ega home kataloogi, mis on konteinerite jaoks ohutu. See vähendab turvalisuse ohte – kui konteiner on kompromiteeritud, ei saa ründaja täisrooti õigusi.

**Miks non-root?**

Kui konteiner jookseb root'iga (`USER root` või jäetakse ette kirjutamata), võib igasugune konteineris käiv koodi ründaja otseselt saada host süsteemi juurde pääsu, eriti kui konteiner on eesõigustega käivitatud (nt `docker run --privileged`). Non-root piiritleb kahjusid.

**Märkus:** Debian-based image'ides (nagu `node:22-slim`) kasuta `groupadd`/`useradd`. Alpine-based image'ides kasuta `addgroup`/`adduser`.

---

### Sõltuvuste kopeerimine

```dockerfile
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules
```

See käsk kopeerib **varem ehitatud `node_modules` kataloogi** esimesest stage'ist (`dependencies`) selle stage'i `/app/node_modules` kataloogi. `--chown=nodejs:nodejs` määrab omanikuks `nodejs` kasutaja ja grupi.

**Miks see oluline on:**

- `node_modules` on juba paigaldatud ja testitud – ei pea npm'i jälle käivitama.
- Omaniku määramine ettemakstult tagab, et `nodejs` kasutaja saab neid faile lugeda ja kirjutada, kui vaja.
- Esimeses stage'is oli root'i omanik, aga siin seame õige omaniku.

---

### Rakenduse koodi kopeerimine

```dockerfile
COPY --chown=nodejs:nodejs . .
```

Kopeerib **kõik jäänud failid** (äpi kood, config failid jne) tarvikusse, omanikuks taas `nodejs` kasutaja.

---

### Non-root kasutaja aktivatsioon

```dockerfile
USER nodejs:nodejs
```

Käsk määrab, et **kõik järgnevad käsud (ja konteiner) jooksevad kasutajana `nodejs`**, mitte root'ina. See on kriitilise turvalisuse samm.

---

### Port avamine

```dockerfile
EXPOSE 3000
```

Dokumenteerib, et konteiner kuulab pordi 3000. See pole tegelik avalikuks tegemine – tulemüüri seadistus käib `docker run -p` jne juures, kuid see aitab dokumenteerida, mis porti app kasutab.

---

## HEALTHCHECK – automaatne tervisekontroll

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD node healthcheck.js || exit 1
```

### Mida see teeb

Docker **käivitab iga 30 sekundi tagant** (`--interval=30s`) skripti `node healthcheck.js`, et kontrollida, kas konteiner on ikka "terve".

- `--timeout=3s`: kui skript ei lõpe 3 sekundi jooksul, loetakse test ebaõnnestunuks.
- `--start-period=10s`: konteiner saab esimesed 10 sekundit startup'i jaoks – esimestel testidel lubatakse ebaõnnestumised.
- `CMD node healthcheck.js || exit 1`: käivitab `healthcheck.js` faili; kui see väljub koodiga 0 (õnnestus), on konteiner terve; kui väljub mitte-nulliga, on haige.

### Praktikas

`healthcheck.js` file peaks tegema midagi lihtsat, näiteks HTTP GET-päringu sinu app'i `/health` endpoint'ile. Näiteks:

```javascript
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/health',
  method: 'GET',
  timeout: 2000
};

const req = http.request(options, (res) => {
  process.exit(res.statusCode === 200 ? 0 : 1);
});

req.on('error', () => process.exit(1));
req.end();
```

Kui tervisekontroll ebaõnnestub 3 korda järjest, märgib Docker konteineri kui "unhealthy" ja saad `docker ps` käsus näha `(unhealthy)` märke. Seda saab kasutada automaatse taaskäivituse või alertide jaoks orkestreerimise süsteemides (Kubernetes, Docker Compose jne).

---

## Käivitumine

```dockerfile
CMD ["node", "server.js"]
```

Konteiner käivitub käsuga `node server.js` – see on vaikimisi käsk, mille Docker käivitab, kui `docker run` käivitatakse ilma otsese käsuta. Exec vorm `["node", "server.js"]` (massiiv) on parem kui shell vorm `node server.js`, sest signaalid (`SIGTERM` jne) jõuavad õigesti Node.js'i protsessini.

---

## Kokkuvõte: miks see Dockerfile hea?

| Omadus | Eelis |
| :-- | :-- |
| **Mitmeastmeline build** | Finaalse image'i suurust väheneb drastiliselt – esimene stage näitab ainult, kuidas paigaldada npm sõltuvused, teises on ainult runtime |
| **`npm ci --only=production`** | Väiksem image, turvalisem, reproducible (samme versioon iga kord) |
| **Non-root kasutaja** | Turvalisem – kui konteiner on kompromiteeritud, pole root õigusi |
| **Proxy tugi (ARG/ENV)** | Töötab paiksetele proxy'dele järgmistest (nt firmades) – npm saab internetti |
| **HEALTHCHECK** | Kubernetes, Docker Compose ja muud orkestreerimise süsteemid teavad, kas app töötab või pole |
| **Lightweight base (`node:22-slim`)** | Image on väike ja kiire |

Kokkuvõttes: **kiire, turvalisku ja optimeeritud production Dockerfile**, mis sobib hästi konteinerite orkestreerimise ja CI/CD süsteemidega.

---

**Tüüp:** Koodiselgitus (KOODISELGITUS)
**Kasutatakse:** Lab 1, Harjutus 05 (Node.js optimeeritud Dockerfile)
**Viimane uuendus:** 2025-01-25
**Allikas:** AI-genereeritud selgitus (Perplexity AI), kohandatud TERMINOLOOGIA.md reeglite järgi
