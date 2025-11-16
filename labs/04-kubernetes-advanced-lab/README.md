# Labor 4: Kubernetes Täiustatud + Tootmisse Paigaldamine

**Kestus:** 6 tundi (Path A) või 4 tundi (Path B)
**Eeldused:** Labor 3 läbitud, Peatükk 17-19 (Kubernetes täiustatud)
**Eesmärk:** Õppida tootmisse paigaldamise mustreid ning Kubernetes'e täiustatud funktsioone

---

## 📋 Ülevaade

Selles laboris õpid kahte erinevat lähenemist rakenduste tootmisse paigaldamiseks:
- **Traditsiooniline lähenemine:** DNS + Nginx reverse proxy (VPS-põhine)
- **Kaasaegne lähenemine:** Kubernetes Ingress Controller

Mõlemad meetodid lahendavad sama probleemi - kuidas suunata liiklust välistest domeenidest sinu mikroteenustele - kuid erinevate tehnikatega.

---

## 🛤️ Vali Oma Õppetee

### Path A: Algaja tee (6 tundi)
**Kellele:** Esimest korda reverse proxy või domeenide seadistamisega kokku puutuvad

**Õppejärjekord:**
1. DNS + Nginx Reverse Proxy (harjutus 01) - 90 min
2. Kubernetes Ingress (harjutus 02) - 90 min
3. SSL/TLS sertifikaadid (harjutus 03) - 60 min
4. Helm Charts (harjutus 04) - 60 min
5. Autoscaling + Rolling Updates (harjutus 05) - 60 min

**Eelised:**
- ✅ Mõistad reverse proxy põhimõtteid täielikult
- ✅ Näed evolutsiooni traditsioonilisest kaasaegseks
- ✅ Oskad seadistada mõlemat lahendust
- ✅ Saad võrrelda erinevaid lähenemisi

### Path B: Kogenud tee (4 tundi)
**Kellele:** Juba töötanud Nginx või teiste reverse proxy lahendustega

**Õppejärjekord:**
1. Kubernetes Ingress (harjutus 02) - 90 min
2. SSL/TLS sertifikaadid (harjutus 03) - 60 min
3. Helm Charts (harjutus 04) - 60 min
4. Autoscaling + Rolling Updates (harjutus 05) - 60 min

**Eelised:**
- ✅ Otsejoon kaasaegse lahenduse juurde
- ✅ Vähem aega, sama tulemus
- ✅ Fokus Kubernetes-spetsiifilistele võimalustele

---

## 🎯 Õpieesmärgid

### Path A täidab kõik eesmärgid:
- ✅ Seadistada DNS A-kirjed domeenile
- ✅ Konfigureerida Nginx reverse proxy VPS-is
- ✅ Mõista virtual hosts ja upstream'ide kontseptsiooni
- ✅ Paigaldada Ingress Controller Kubernetes klasterisse
- ✅ Luua Ingress ressursid path-based routing'uks
- ✅ Võrrelda traditsioonilist ja kaasaegset lähenemist
- ✅ Seadistada SSL/TLS sertifikaadid (Let's Encrypt)
- ✅ Luua Helm Charts rakenduste paketeerimiseks
- ✅ Kasutada Horizontal Pod Autoscaling (HPA)
- ✅ Implementeerida Rolling Updates
- ✅ Seadistada Health Checks ja Readiness Probes

### Path B täidab kaasaegsed eesmärgid:
- ✅ Paigaldada Ingress Controller Kubernetes klasterisse
- ✅ Luua Ingress ressursid path-based routing'uks
- ✅ Seadistada SSL/TLS sertifikaadid cert-manager'iga
- ✅ Luua Helm Charts rakenduste paketeerimiseks
- ✅ Kasutada Horizontal Pod Autoscaling (HPA)
- ✅ Implementeerida Rolling Updates
- ✅ Seadistada Health Checks ja Readiness Probes

---

## 📂 Labori Struktuur

```
04-kubernetes-advanced-lab/
├── README.md                           # Sinu asukad siin
├── exercises/
│   ├── 01-dns-nginx-proxy.md          # Path A algus: DNS + Nginx (90 min)
│   ├── 02-kubernetes-ingress.md       # Path A/B mõlemad: K8s Ingress (90 min)
│   ├── 03-ssl-tls.md                  # Path A/B: SSL sertifikaadid (60 min)
│   ├── 04-helm-charts.md              # Path A/B: Helm paketid (60 min)
│   └── 05-autoscaling-rolling.md      # Path A/B: Skaleerumine (60 min)
├── solutions/
│   ├── nginx/
│   │   ├── kirjakast.cloud.conf       # Nginx reverse proxy konfiguratsioon
│   │   └── ssl.conf                   # SSL seaded
│   ├── kubernetes/
│   │   ├── ingress-nginx.yaml         # Ingress Controller paigaldus
│   │   ├── app-ingress.yaml           # Rakenduse Ingress reeglid
│   │   ├── hpa.yaml                   # Horizontal Pod Autoscaler
│   │   └── cert-manager.yaml          # cert-manager paigaldus
│   └── helm/
│       └── todo-app/                  # Helm chart näidis
└── comparison.md                      # Nginx vs Ingress võrdlustabel
```

---

## 🔄 Mis on Reverse Proxy?

**Lihtne selgitus:**

Reverse proxy on server, mis asub sinu rakenduste ees ja suunab kasutajate päringud õigele teenusele.

```
Kasutaja (brauser)
    ↓
    http://kirjakast.cloud/todo
    ↓
Reverse Proxy (Nginx VÕI Ingress Controller)
    ↓
    ├─→ /todo         → Frontend (port 8080)
    ├─→ /api/todos    → Todo Service (port 8081)
    └─→ /api/users    → User Service (port 3000)
```

**Miks kasutada?**
- ✅ Üks domeen, mitu teenust (kirjakast.cloud suunab kõik eri portidele)
- ✅ SSL/TLS lõpetamine (HTTPS) ühes kohas
- ✅ Load balancing (liikluse jagamine)
- ✅ Puhverdamine (caching)
- ✅ Ligipääsu kontroll ja turvalisus

---

## 🆚 Nginx vs Kubernetes Ingress

| Aspekt | Nginx (Traditsiooniline) | Kubernetes Ingress |
|--------|-------------------------|-------------------|
| **Paigaldus** | VPS-i (host OS) | Kubernetes klaster |
| **Konfiguratsioon** | nginx.conf failid | YAML manifest'id (Ingress) |
| **Haldusliidesed** | SSH + vim/nano | kubectl |
| **SSL sertifikaadid** | certbot (Let's Encrypt) | cert-manager (automaatne) |
| **Teenuste avastamine** | Käsitsi (static upstream'id) | Automaatne (K8s Service'id) |
| **Skaleerumine** | Vertikaalne (suurem server) | Horisontaalne (replicas) |
| **Tõrkekindlus** | Üks fail point | High Availability (multiple pods) |
| **Kasutatakse** | VPS, dedikeeritud serverid | Kubernetes keskkonnad |
| **Õppimiskõver** | Keskmine (Nginx config syntax) | Kõrgem (K8s kontseptsioonid) |
| **Ideaalne** | Väiksemad projektid, lihtne setup | Suured klastrid, mikroteenused |

---

## 🚀 Kuidas Alustada?

### 1. Vali oma tee

**Kui sa ei ole kindel, vali Path A.** See annab parema arusaamise mõlemast lähenemisest.

### 2. Alusta harjutustega

**Path A (Algaja):**
```bash
cd exercises
# Alusta harjutus 01-st
cat 01-dns-nginx-proxy.md
```

**Path B (Kogenud):**
```bash
cd exercises
# Alusta harjutus 02-st
cat 02-kubernetes-ingress.md
```

### 3. Kasuta lahendusi

Iga harjutuse jaoks on valmis lahendused `solutions/` kataloogis. Proovi esmalt ise, vaata lahendust ainult kui jääd kinni.

---

## 📊 Labori Edenemise Checklist

### Path A - Täielik Tee
- [ ] **Harjutus 01:** DNS A-kirje loodud ja Nginx reverse proxy töötab
- [ ] **Harjutus 01:** Teenustele pääseb ligi domeeni kaudu (http://kirjakast.cloud)
- [ ] **Harjutus 02:** Ingress Controller paigaldatud Kubernetes'esse
- [ ] **Harjutus 02:** Ingress ressursid loodud ja teenused kättesaadavad
- [ ] **Harjutus 03:** SSL sertifikaadid mõlemas lahenduses töötavad (HTTPS)
- [ ] **Harjutus 04:** Helm chart loodud ja rakendus paigaldatud
- [ ] **Harjutus 05:** HPA skaleerib pod'e automaatselt
- [ ] **Harjutus 05:** Rolling update toimib ilma downtime'ita
- [ ] **Võrdlus:** Mõistad mõlema lahenduse eeliseid ja puudusi

### Path B - Kiire Tee
- [ ] **Harjutus 02:** Ingress Controller paigaldatud
- [ ] **Harjutus 02:** Rakendused kättesaadavad Ingress kaudu
- [ ] **Harjutus 03:** cert-manager automaatselt haldab SSL serte
- [ ] **Harjutus 04:** Helm chart paigaldatud
- [ ] **Harjutus 05:** Autoscaling ja rolling updates töötavad

---

## 🎓 Mida Sa Õpid?

### Infrastruktuuri Kontseptsioonid
- DNS A-kirjete seadistamine
- Reverse proxy arhitektuur
- Virtual hosts ja upstream'id
- Path-based routing vs host-based routing
- SSL/TLS sertifikaadid ja HTTPS

### Kubernetes Kontseptsioonid
- Ingress Controllers (Nginx Ingress, Traefik, HAProxy)
- Ingress Resources ja routing reeglid
- Service discovery Kubernetes'es
- Horizontal Pod Autoscaling (HPA)
- Rolling updates strateegia
- Readiness ja liveness probes

### Tööhalduse Tööriistad
- Helm package manager
- cert-manager automaatsed sertifikaadid
- kubectl debug käsud
- Prometheus metrics HPA jaoks

### Tootmise Best Practices
- Zero-downtime deployments
- Automaatne skaleerimine
- Health monitoring
- SSL/TLS turvalisus
- GitOps workflow (Helm)

---

## 💡 Kasulikud Käsud

### Nginx (Harjutus 01)
```bash
# Kontrolli konfiguratsiooni
sudo nginx -t

# Taaslae konfiguratsioon
sudo systemctl reload nginx

# Vaata logisid
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Kontrolli DNS
dig kirjakast.cloud
nslookup kirjakast.cloud
```

### Kubernetes (Harjutused 02-05)
```bash
# Ingress
kubectl get ingress
kubectl describe ingress <name>
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# HPA
kubectl get hpa
kubectl describe hpa <name>

# Rolling update
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>

# Helm
helm list
helm install <name> <chart>
helm upgrade <name> <chart>
helm rollback <name> <revision>
```

---

## 🐛 Tüüpilised Vead ja Lahendused

### DNS ei toimi
**Probleem:** `dig kirjakast.cloud` ei tagasta VPS IP'd
**Lahendus:** DNS muudatused võivad võtta 5-60 minutit. Kontrolli DNS pakkuja juures.

### Nginx annab 502 Bad Gateway
**Probleem:** Upstream teenus ei vasta
**Lahendus:** Kontrolli kas backend teenused töötavad (`docker compose ps`)

### Ingress ei suuna teenustele
**Probleem:** `kubectl get ingress` näitab ADDRESS tühjana
**Lahendus:** Ingress Controller pole paigaldatud või pole valmis

### HPA ei skaleeri
**Probleem:** Pod'ide arv ei muutu
**Lahendus:** Metrics server puudub või CPU requests pole seatud

### SSL sertifikaat ei tööta
**Probleem:** Brauser näitab "Not Secure"
**Lahendus:** Kontrolli cert-manager logi või Let's Encrypt rate limite

---

## 📚 Edasine Lugemine

- [Nginx Reverse Proxy Guide](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Helm Documentation](https://helm.sh/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [cert-manager Documentation](https://cert-manager.io/docs/)

---

## 🎯 Järgmised Sammud

Pärast seda laborit:
1. **Lab 5:** CI/CD pipeline GitHub Actions'iga
2. **Lab 6:** Monitoring Prometheus + Grafana'ga

---

**Staatus:** 📝 Harjutused loomise järgus
**Viimane uuendus:** 2025-11-16
**Autor:** DevOps Training Labs
