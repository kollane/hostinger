## Üldine idee

See on kahe-etapiline (multi-stage) Dockerfile Node.js rakendusele, kus:

- esimeses etapis (“builder”) installitakse sõltuvused ning vajadusel kasutatakse HTTP/HTTPS proxy’t.
- teises etapis (“runtime”) kasutatakse ainult valmis node_modules’i ja koodi, ilma ühegi proxy seadistuseta, et runtime‑image oleks puhas ja väiksem.

See lahendus aitab:

- hoida build’i toimimas ka proksi taga;
- vältida proksi seadete lekkimist lõpp‑image’isse;
- vähendada lõpp‑image’i suurust.


## 1. etapp: Builder

```dockerfile
FROM node:22-slim AS builder
```

- Alustab “builder” stage’i, base image on õhuke Node 22 variatsioon (slim). See sobib buildimiseks ja sisaldab Node + npm’i.

```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
```

- Deklareerib build‑time argumendid, mida saab anda `docker build --build-arg HTTP_PROXY=...` jms kaudu.
- Need eksisteerivad ainult buildimise ajal, ei lähe automaatselt lõpp‑image’i.

```dockerfile
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY}
```

- Seob ARG väärtused builder‑etapi keskkonnamuutujateks, et kõik järgnevad `RUN` käsud (sh `npm install`) kasutaksid vajadusel proksit.
- Need ENV’id kehtivad ainult selles stage’is; teises FROM‑is alustatakse nullist.

```dockerfile
WORKDIR /app
```

- Seab töökausta `/app` (järgnevad käsud ja COPY’d toimuvad seal).

```dockerfile
COPY package*.json ./
```

- Kopeerib ainult package‑failid (nt `package.json`, `package-lock.json`).
- See on cache‑sõbralik: kui kood muutub, aga sõltuvused mitte, jääb see kiht cache’i alles.

```dockerfile
RUN npm install --production
```

- Installib ainult production‑sõltuvused (ilma devDependencies’ita), kasutades vajadusel proksit.
- Tulemuseks on `/app/node_modules` builder‑image’is.


## 2. etapp: Runtime

```dockerfile
FROM node:22-slim AS runtime
```

- Uus, puhas image runtime’i jaoks, ilma buildi ajal kasutatud ENV‑ideta (HTTP_PROXY jne ei kandu siia üle).

```dockerfile
WORKDIR /app
```

- Jälle töökaust `/app` runtime‑etapis.

```dockerfile
COPY --from=builder /app/node_modules ./node_modules
```

- Kopeerib ainult valmis node_modules’i builder‑etapist runtime‑etappi.
- Nii ei pea runtime‑image’is npm’i jooksutama, see hoiab image’i väiksemana ja buildi kiiremana.

```dockerfile
COPY . .
```

- Kopeerib üle ülejäänud rakenduse koodi (sh `server.js` ja muu).
- Kuna see tehakse pärast node_modules’i kopeerimist, ei riku see dependency cache’i.

```dockerfile
EXPOSE 3000
```

- Dokumenteerib, et konteiner kuulab pordil 3000 (Node server). See on info orkestreerijatele/teistele tööriistadele.

```dockerfile
ENV NODE_ENV=production
```

- Seab runtime’is `NODE_ENV=production`, mis paneb mitmed Node raamistikud ja npm’iga seotud asjad tööle produktsioonirežiimis (optimeeritud kooditee, ei laadi dev‑feature’id).

```dockerfile
CMD ["node", "server.js"]
```

- Vaikekäsk konteineri käivitamisel: käivita rakendus `node server.js`.


## Portatiivsus ja turvalisus

- Proxy antakse build‑ajal läbi `ARG` ja kasutatakse ainult builder‑etapis, seega lõpp‑image’is pole ühtegi HTTP_PROXY/HTTPS_PROXY ENV’i ega väärtust (hea turvalisus ja portatiivsus).
- Multi‑stage ja sõltuvuste kopeerimine builder'ist runtime'i on soovitatud praktika, et hoida lõpp‑image väike ja puhas ning vältida build‑toolide või tundlike seadete sattumist produktsioonikeskkonda.
---

**Viimane uuendus:** 2025-01-25
**Tüüp:** Koodiselgitus (Code Explanation)
**Kasutatakse:**
- [Lab 1, Exercise 01a: Single Container Node.js](../../labs/01-docker-lab/exercises/01a-single-container-nodejs.md) - Variant B, Samm 2, rida 141
---

