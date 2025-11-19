<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# BUILD etapis, kuidas ma tean, millised failid tuleb kopeerida?

BUILD-etapis tuleb Dockerfile’is kopeerida **need failid ja kaustad**, mis on vajalikud rakenduse edukaks ehitamiseks (buildimiseks). Need sõltuvad kasutatavast buildisüsteemist (näiteks Gradle, Maven, npm jne) ja rakenduse struktuurist.[^2][^3][^4]

### Kuidas valida, mida kopeerida:

- **Build script’id ja konfiguratsioon**
  Pane kõigepealt failid nagu `build.gradle`, `settings.gradle`, ja vajadusel `gradle/` alakaust. Need on vajalikud sõltuvuste allalaadimiseks ja buildiprotsessi käivitamiseks.
- **Lähtekood**
  Kopeeri `src/` kaust, sest seal asub kogu rakenduse lähtekood.
  Näide: `COPY src ./src`
- **Lisakonfiguratsioonid**
  Kui projektis on näiteks `application.properties`, `docker-compose.yml` või teisi vajalikke faile build’iks, kopeeri ka need.
- **Sõltuvused (dependency cache)**
  Kui ehitad build cache loogikat, kopeeri kõigepealt build-konfiguratsioonid ja tõmba sõltuvused juba enne lähtekoodi kopeerimist, et kiirendada korduvaid builde.


### Näide:

```
COPY build.gradle settings.gradle ./
COPY gradle ./gradle
RUN gradle dependencies --no-daemon

COPY src ./src
RUN gradle bootJar --no-daemon
```

- Esmalt build-script’id ja konfiguratsioon (sõltuvused saavad cache’i minna).
- Lõpuks lähtekood ja tegelik build’iks vajaliku allika kopeerimine.

Kui mõni fail puudu jääb, viskab Docker build build-etapis vea ("file not found"). Võimalik on ka buildi logis või käsitsi kontrollida, mis faile ja kaustu allikas vajab. Parim allikas kontrollimiseks on build-süsteemi enda dokumentatsioon või projektistruktuur (failipuu).

Kokkuvõte: **kopeerida tuleb kõik failid ja kaustad, mis on vajalikud rakenduse buildimiseks**; enamasti build scriptid, konfiguratsioonid ja lähtekood.[^3][^4][^5]
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


