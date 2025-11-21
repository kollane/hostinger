<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# EHITUSE (BUILD) etapis, kuidas ma tean, millised failid tuleb kopeerida?

EHITUSE (BUILD)-etapis tuleb Dockerfile’is kopeerida **need failid ja kaustad**, mis on vajalikud rakenduse (application) edukaks ehitamiseks (buildimiseks). Need sõltuvad kasutatavast ehitussüsteemist (build system) (näiteks Gradle, Maven, npm jne) ja rakenduse (application) struktuurist.[^2][^3][^4]

### Kuidas valida, mida kopeerida:

- **Ehituse (build) skriptid ja konfiguratsioon**
  Pane kõigepealt failid nagu `build.gradle`, `settings.gradle`, ja vajadusel `gradle/` alakaust. Need on vajalikud sõltuvuste (dependencies) allalaadimiseks ja ehitusprotsessi (build process) käivitamiseks.
- **Lähtekood**
  Kopeeri `src/` kaust, sest seal asub kogu rakenduse (application) lähtekood.
  Näide: `COPY src ./src`
- **Lisakonfiguratsioonid**
  Kui projektis on näiteks `application.properties`, `docker-compose.yml` või teisi vajalikke faile ehituseks (build), kopeeri ka need.
- **Sõltuvused (dependency cache)**
  Kui ehitad ehituse (build) vahemälu (cache) loogikat, kopeeri kõigepealt ehitus-konfiguratsioonid (build configurations) ja tõmba sõltuvused (dependencies) juba enne lähtekoodi kopeerimist, et kiirendada korduvaid ehitusi (builds).


### Näide:

```
COPY build.gradle settings.gradle ./
COPY gradle ./gradle
RUN gradle dependencies --no-daemon

COPY src ./src
RUN gradle bootJar --no-daemon
```

- Esmalt ehitus-skriptid (build-scripts) ja konfiguratsioon (sõltuvused (dependencies) saavad vahemällu (cache) minna).
- Lõpuks lähtekood ja tegelikuks ehituseks (build) vajaliku allika kopeerimine.

Kui mõni fail puudu jääb, viskab Docker ehitus (build) ehitus-etapis (build-stage) vea ("file not found"). Võimalik on ka ehituse (build) logis või käsitsi kontrollida, mis faile ja kaustu allikas vajab. Parim allikas kontrollimiseks on ehitus-süsteemi (build-system) enda dokumentatsioon või projektistruktuur (failipuu).

Kokkuvõte: **kopeerida tuleb kõik failid ja kaustad, mis on vajalikud rakenduse (application) ehitamiseks (build)**; enamasti ehitus skriptid, konfiguratsioonid ja lähtekood.[^3][^4][^5]
<span style="display:none">[^1][^6][^7][^8]</span>

<div align="center">⁂</div>

[^1]: https://docs.docker.com/build/building/multi-stage/

[^2]: https://stackoverflow.com/questions/57910644/docker-multistage-how-to-copy-built-files-between-stages

[^3]: https://docs.docker.com/get-started/docker-concepts/building-images/multi-stage-builds/

[^4]: https://spacelift.io/blog/docker-multistage-builds

[^5]: https://cyberpanel.net/blog/docker-multi-stage-builds

[^6]: https://www.reddit.com/r/docker/comments/15wfnhm/another_multistage_docker_build_copy_issue_but_i/

[^7]: https://forums.docker.com/t/problem-with-multi-stage-builds-and-mount-point/146389

[^8]: https://www.linux.digibeatrix.com/et/development-environment-setup/manage-docker-images-ubuntu/


