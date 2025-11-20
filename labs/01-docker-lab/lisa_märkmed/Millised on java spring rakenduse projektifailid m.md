<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Millised on java spring rakenduse projektifailid mis on vajalikud kontineriseerimisel

Java Spring rakenduse konteineriseerimisel on vajalikud järgmised projektifailid, et Dockerimage ehitamine ja konteineri käivitamine oleksid edukad:

***

### Vajalikud projektifailid konteineriseerimiseks

- **Dockerfile**
    - Sisaldab juhiseid, kuidas rakenduse konteinerit ehitada ja käivitada.[^1][^2]
- **Maven projekti puhul:**
    - `pom.xml` – määratleb kõik sõltuvused, Java versiooni ja build’i konfiguratsiooni.[^3][^4]
- **Gradle projekti puhul:**
    - `build.gradle` – sisaldab sõltuvusi ja build’i sätteid.[^5]
    - `settings.gradle` – Gradle konfiguratsioon, eriti suuremates projektides.
- **Allikakood:**
    - `src/` kataloog (Java lähtekood, tavaliselt failistruktuur nagu `src/main/java`, `src/main/resources`).[^2][^3]
- **Rakenduse jar fail**
    - Build’i tulemusena tekib kaustas `target/` (Maven) või `build/libs/` (Gradle) fat/executable JAR fail (nt `app.jar`).[^6][^7]
- **(Soovituslik) .dockerignore**
    - Välistab buildi/konteinerisse mittevajalikud failid (nt .git, target/).[^6]
- **Spring Boot eriseaded:**
    - `application.properties` või `application.yml` (konfiguratsioon, mis peaks toetama välistamist/keskkonnamuutujaid).[^8]


#### (soovi korral)

- **healthcheck.js** või muu skript, kui teie Dockerfile kasutab HEALTHCHECK käsu jaoks välist skripti Node või shelli keskkonnas.
- **docker-compose.yml** (kui soovid konteinerit mitme teenusega/arendada keerukamat lahendust mitme konteineriga).[^9]

***

### Failide näidisstruktuur

```text
projekt/
├── Dockerfile
├── .dockerignore
├── pom.xml                # Maven (või build.gradle, settings.gradle Gradle puhul)
├── src/
│   └── main/
│       ├── java/
│       └── resources/
├── target/
│   └── app.jar            # Tekib pärast Maven buildi (või build/libs/app.jar Gradle jaoks)
├── application.properties
└── (docker-compose.yml)   # pole kohustuslik
```


***

Neid faile ja struktuuri järgides on võimalik Spring Boot rakendus edukalt konteineriseerida, tagades, et kõik vajalikud komponendid jõuavad korrektselt Docker image’i ja konteinerisse.[^3][^2][^6]
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18]</span>

<div align="center">⁂</div>

[^1]: https://spring.io/guides/gs/spring-boot-docker

[^2]: https://www.geeksforgeeks.org/java/dockerizing-spring-boot-apps/

[^3]: https://stackoverflow.com/questions/78437127/running-a-springboot-project-in-docker

[^4]: https://blog.frankel.ch/hitchhiker-guide-containerizing-java-apps/

[^5]: https://www.youtube.com/watch?v=jhaXgXQveKQ

[^6]: https://www.docker.com/blog/9-tips-for-containerizing-your-spring-boot-code/

[^7]: https://bell-sw.com/videos/dockerize-spring-boot-wisely-6-tips-to-improve-the-container-images-of-your-spring-boot-apps/

[^8]: https://www.baeldung.com/dockerizing-spring-boot-application

[^9]: https://dev.to/ahmadtheswe/dockerize-your-spring-boot-app-3ang

[^10]: https://www.youtube.com/watch?v=Fw_F5-UGgHQ

[^11]: https://masteringbackend.com/posts/spring-boot-docker-dockerizing-java-spring-boot-apps

[^12]: https://www.geeksforgeeks.org/java/containerizing-java-applications-creating-a-spring-boot-app-using-dockerfile/

[^13]: https://stackoverflow.com/questions/73546442/best-practice-for-dockerizing-a-springboot-app-in-a-cicd-pipeline

[^14]: https://docs.docker.com/guides/java/containerize/

[^15]: https://openliberty.io/guides/spring-boot.html

[^16]: https://www.reddit.com/r/docker/comments/134be9v/how_do_you_read_and_write_files_within_a_docker/

[^17]: https://menttor.live/library/creating-dockerfiles-for-spring-boot-applications

[^18]: https://www.baeldung.com/spring-boot-podman-desktop

