<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Seleta lahti:\# ====================================

# 1. etapp: Builder (sõltuvuste installimine)

# ====================================

FROM node:22-slim AS builder

# ARG võimaldab anda proxy build-time'is (portaabel!)

ARG HTTP_PROXY
ARG HTTPS_PROXY

# ENV ainult builder etapis (ei leki runtime'i!)

ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY}

WORKDIR /app

# Kopeeri sõltuvuste failid

COPY package*.json ./

# Installi sõltuvused (kasutab proxy't, kui antud)

RUN npm install --production

# ====================================

# 2. etapp: Runtime (clean, ilma proksita)

# ====================================

FROM node:22-slim AS runtime

WORKDIR /app

# Kopeeri node_modules builder'ist

COPY --from=builder /app/node_modules ./node_modules

# Kopeeri rakenduse kood

COPY . .

# Avalda port

EXPOSE 3000

# Keskkond

ENV NODE_ENV=production

# Käivita rakendus

CMD ["node", "server.js"]

Seeleta lahti, mida see Dockerfile teeb ja miks ta on üles ehitatud just nii.

## Üldine idee

See on kahe-etapiline (multi-stage) Dockerfile Node.js rakendusele, kus:

- esimeses etapis (“builder”) installitakse sõltuvused ning vajadusel kasutatakse HTTP/HTTPS proxy’t;[^1][^2]
- teises etapis (“runtime”) kasutatakse ainult valmis node_modules’i ja koodi, ilma ühegi proxy seadistuseta, et runtime‑image oleks puhas ja väiksem.[^3][^4]

See lahendus aitab:

- hoida build’i toimimas ka proksi taga;
- vältida proksi seadete lekkimist lõpp‑image’isse;
- vähendada lõpp‑image’i suurust.[^2][^5]


## 1. etapp: Builder

```dockerfile
FROM node:22-slim AS builder
```

- Alustab “builder” stage’i, base image on õhuke Node 22 variatsioon (slim). See sobib buildimiseks ja sisaldab Node + npm’i.[^6][^7]

```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
```

- Deklareerib build‑time argumendid, mida saab anda `docker build --build-arg HTTP_PROXY=...` jms kaudu.[^8][^1]
- Need eksisteerivad ainult buildimise ajal, ei lähe automaatselt lõpp‑image’i.[^9][^10]

```dockerfile
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY}
```

- Seob ARG väärtused builder‑etapi keskkonnamuutujateks, et kõik järgnevad `RUN` käsud (sh `npm install`) kasutaksid vajadusel proksit.[^1][^2]
- Need ENV’id kehtivad ainult selles stage’is; teises FROM‑is alustatakse nullist.[^11][^3]

```dockerfile
WORKDIR /app
```

- Seab töökausta `/app` (järgnevad käsud ja COPY’d toimuvad seal).[^7]

```dockerfile
COPY package*.json ./
```

- Kopeerib ainult package‑failid (nt `package.json`, `package-lock.json`).
- See on cache‑sõbralik: kui kood muutub, aga sõltuvused mitte, jääb see kiht cache’i alles.[^4][^12]

```dockerfile
RUN npm install --production
```

- Installib ainult production‑sõltuvused (ilma devDependencies’ita), kasutades vajadusel proksit.[^13][^12][^6]
- Tulemuseks on `/app/node_modules` builder‑image’is.


## 2. etapp: Runtime

```dockerfile
FROM node:22-slim AS runtime
```

- Uus, puhas image runtime’i jaoks, ilma buildi ajal kasutatud ENV‑ideta (HTTP_PROXY jne ei kandu siia üle).[^3][^11]

```dockerfile
WORKDIR /app
```

- Jälle töökaust `/app` runtime‑etapis.

```dockerfile
COPY --from=builder /app/node_modules ./node_modules
```

- Kopeerib ainult valmis node_modules’i builder‑etapist runtime‑etappi.[^14][^3]
- Nii ei pea runtime‑image’is npm’i jooksutama, see hoiab image’i väiksemana ja buildi kiiremana.[^4][^14]

```dockerfile
COPY . .
```

- Kopeerib üle ülejäänud rakenduse koodi (sh `server.js` ja muu).
- Kuna see tehakse pärast node_modules’i kopeerimist, ei riku see dependency cache’i.[^12][^4]

```dockerfile
EXPOSE 3000
```

- Dokumenteerib, et konteiner kuulab pordil 3000 (Node server). See on info orkestreerijatele/teistele tööriistadele.[^7]

```dockerfile
ENV NODE_ENV=production
```

- Seab runtime’is `NODE_ENV=production`, mis paneb mitmed Node raamistikud ja npm’iga seotud asjad tööle produktsioonirežiimis (optimeeritud kooditee, ei laadi dev‑feature’id).[^6][^13][^12]

```dockerfile
CMD ["node", "server.js"]
```

- Vaikekäsk konteineri käivitamisel: käivita rakendus `node server.js`.[^15][^7]


## Portatiivsus ja turvalisus

- Proxy antakse build‑ajal läbi `ARG` ja kasutatakse ainult builder‑etapis, seega lõpp‑image’is pole ühtegi HTTP_PROXY/HTTPS_PROXY ENV’i ega väärtust (hea turvalisus ja portatiivsus).[^5][^2][^1]
- Multi‑stage ja sõltuvuste kopeerimine builder'ist runtime'i on soovitatud praktika, et hoida lõpp‑image väike ja puhas ning vältida build‑toolide või tundlike seadete sattumist produktsioonikeskkonda.[^3][^4][^7]
<span style="display:none">[^16][^17][^18][^19][^20]</span>

<div align="center">⁂</div>

---

**Viimane uuendus:** 2025-01-25
**Tüüp:** Koodiselgitus (Code Explanation)
**Kasutatakse:**
- [Lab 1, Exercise 01a: Single Container Node.js](../../labs/01-docker-lab/exercises/01a-single-container-nodejs.md) - Variant B, Samm 2, rida 141

---

[^1]: https://docs.docker.com/build/building/variables/

[^2]: https://www.datacamp.com/tutorial/docker-proxy

[^3]: https://docs.docker.com/build/building/multi-stage/

[^4]: https://cyberpanel.net/blog/docker-multi-stage-builds

[^5]: https://docs.docker.com/engine/cli/proxy/

[^6]: https://www.bretfisher.com/node-docker-good-defaults/

[^7]: https://docs.docker.com/guides/nodejs/containerize/

[^8]: https://docs.docker.com/reference/cli/docker/buildx/build/

[^9]: https://spacelift.io/blog/docker-build-args

[^10]: https://www.datacamp.com/tutorial/docker-build-args

[^11]: https://stackoverflow.com/questions/53541362/persist-env-in-multi-stage-docker-build

[^12]: https://kariera.future-processing.pl/blog/dockerfile-good-practices-for-node-and-npm/

[^13]: https://snyk.io/blog/10-best-practices-to-containerize-nodejs-web-applications-with-docker/

[^14]: https://dev.to/davydocsurg/mastering-docker-for-nodejs-advanced-techniques-and-best-practices-55m9

[^15]: https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md

[^16]: https://github.com/moby/moby/issues/4962

[^17]: https://stackoverflow.com/questions/55598484/docker-http-proxy-settings-not-affecting-runtime-behavior

[^18]: https://github.com/docker/cli/issues/4501

[^19]: https://github.com/moby/moby/issues/27949

[^20]: https://docs.podman.io/en/v5.3.2/markdown/podman-build.1.html

