# Harjutus 3: SSL/TLS Sertifikaadid

**Kestus:** 60 minutit
**Eesmärk:** Lisa HTTPS tugi nii traditsioonilisele Nginx'ile (Path A) kui Kubernetes Ingress'ile (Path A + B)

---

## 📋 Ülevaade

Selles harjutuses õpid seadistama SSL/TLS sertifikaate, et tagada turvaline HTTPS ühendus. Path A õpilased õpivad mõlemat lähenemist (certbot + cert-manager), Path B ainult cert-manager'it Kubernetes'es.

**Path A:** Nginx (certbot) + Kubernetes (cert-manager)
**Path B:** Kubernetes (cert-manager)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista SSL/TLS põhimõtteid ja sertifikaatide elutsüklit
- ✅ Paigaldada Let's Encrypt sertifikaate certbot'iga (Path A)
- ✅ Paigaldada cert-manager Kubernetes klasterisse
- ✅ Luua Certificate ressursid automaatseks halduseks
- ✅ Konfigureerida Ingress HTTPS jaoks
- ✅ Testida HTTPS ühendust
- ✅ Seadistada automaatset sertifikaadi uuendust

---

## 🏗️ Arhitektuur

### Path A: Mõlemad lahendused

```
┌─────────────────────────────────────────┐
│      Traditsiooniline (VPS)             │
│                                         │
│  kirjakast.cloud (HTTPS)                │
│          ↓                              │
│  Nginx + Let's Encrypt (certbot)        │
│          ↓                              │
│  Backend teenused                       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│      Kaasaegne (Kubernetes)             │
│                                         │
│  kirjakast.cloud (HTTPS)                │
│          ↓                              │
│  Ingress Controller + cert-manager      │
│          ↓                              │
│  Services → Pods                        │
└─────────────────────────────────────────┘
```

### Path B: Ainult Kubernetes

```
kirjakast.cloud (HTTPS)
        ↓
Ingress Controller + cert-manager
        ↓
    Services
        ↓
      Pods
```

---

## 📝 Sammud

## Path A: Osa 1 - Nginx SSL/TLS (30 min)

### Samm 1: Paigalda certbot (5 min)

**Mis on certbot?**
Certbot on Let's Encrypt'i ametlik klient automaatseks sertifikaatide hankimiseks ja uuendamiseks.

```bash
# Paigalda certbot Nginx pluginaga
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Kontrolli versiooni
certbot --version
```

**Kontrolli:**
```bash
which certbot
# Peaks näitama: /usr/bin/certbot
```

---

### Samm 2: Hangi Let's Encrypt sertifikaat (10 min)

**Eeldused:**
- DNS A-kirje kirjakast.cloud osutab sinu VPS IP-le
- Nginx töötab ja on konfigureeritud (Harjutus 1)
- Port 80 on avatud

```bash
# Hangi sertifikaat domeenile
sudo certbot --nginx -d kirjakast.cloud -d www.kirjakast.cloud

# Certbot küsib:
# 1. Email (teatiste jaoks): sinu@email.com
# 2. Terms of Service: Agree
# 3. Share email with EFF: Your choice
# 4. Redirect HTTP to HTTPS?: 2 (Yes)
```

**Mis juhtub:**
1. Certbot kontrollib domeeni omandust (ACME challenge)
2. Hangib sertifikaadi Let's Encrypt'ist
3. Muudab automaatselt Nginx konfiguratsiooni
4. Seadistab HTTPS redirect'i

**Kontrolli sertifikaati:**
```bash
# Vaata sertifikaadi infot
sudo certbot certificates

# Peaks näitama:
# Certificate Name: kirjakast.cloud
# Domains: kirjakast.cloud www.kirjakast.cloud
# Expiry Date: 2025-XX-XX
# Certificate Path: /etc/letsencrypt/live/kirjakast.cloud/fullchain.pem
# Private Key Path: /etc/letsencrypt/live/kirjakast.cloud/privkey.pem
```

---

### Samm 3: Kontrolli Nginx konfiguratsiooni (5 min)

Certbot muutis automaatselt sinu Nginx konfiguratsiooni:

```bash
# Vaata uuendatud konfiguratsiooni
sudo vim /etc/nginx/sites-available/kirjakast.cloud.conf
```

**Oodatud muudatused:**

```nginx
server {
    listen 80;
    server_name kirjakast.cloud www.kirjakast.cloud;

    # Certbot lisas HTTP → HTTPS redirect
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name kirjakast.cloud www.kirjakast.cloud;

    # Certbot lisas SSL sertifikaadi viited
    ssl_certificate /etc/letsencrypt/live/kirjakast.cloud/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/kirjakast.cloud/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Sinu olemasolevad location block'id
    location /api/users {
        proxy_pass http://localhost:3000;
        # ...
    }
}
```

**Testi konfiguratsiooni:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

### Samm 4: Testi HTTPS ühendust (5 min)

```bash
# Test 1: HTTPS
curl -I https://kirjakast.cloud

# Oodatud vastus:
# HTTP/2 200
# server: nginx/1.24.0
# ...

# Test 2: HTTP redirect
curl -I http://kirjakast.cloud

# Oodatud vastus:
# HTTP/1.1 301 Moved Permanently
# Location: https://kirjakast.cloud/

# Test 3: Brauseris
# Külasta: https://kirjakast.cloud
# Peaks näitama rohelist lukku (secure connection)
```

**SSL/TLS kontroll:**
```bash
# Kontrolli SSL sertifikaadi detaile
echo | openssl s_client -connect kirjakast.cloud:443 -servername kirjakast.cloud 2>/dev/null | openssl x509 -noout -dates

# Peaks näitama:
# notBefore=...
# notAfter=... (3 kuud tulevikus)
```

---

### Samm 5: Seadista automaatne uuendus (5 min)

Let's Encrypt sertifikaadid kehtivad 90 päeva. Certbot seadistab automaatse uuenduse.

```bash
# Kontrolli automaatset uuendust
sudo certbot renew --dry-run

# Peaks näitama:
# Congratulations, all simulated renewals succeeded

# Vaata cron job'i
sudo systemctl status certbot.timer

# Või vaata systemd timer'it
sudo systemctl list-timers | grep certbot
```

**Manuaalne uuendus (kui vaja):**
```bash
sudo certbot renew
sudo systemctl reload nginx
```

---

## Path A + B: Osa 2 - Kubernetes cert-manager (30 min)

### Samm 6: Paigalda cert-manager (10 min)

**Mis on cert-manager?**
cert-manager on Kubernetes'e native lahendus SSL/TLS sertifikaatide automaatseks halduseks.

```bash
# Loo cert-manager namespace
kubectl create namespace cert-manager

# Lisa Helm repo
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Paigalda cert-manager Helm'iga
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.0 \
  --set installCRDs=true

# Või kubectl'iga:
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

**Kontrolli paigaldust:**
```bash
# Vaata pod'e
kubectl get pods -n cert-manager

# Peaks näitama 3 töötavat pod'i:
# cert-manager-xxxxxxxxxx-xxxxx        1/1  Running
# cert-manager-cainjector-xxxxx-xxxxx  1/1  Running
# cert-manager-webhook-xxxxxxxxx-xxxxx 1/1  Running

# Kontrolli CRD'sid (Custom Resource Definitions)
kubectl get crd | grep cert-manager
# Peaks näitama: certificates, issuers, clusterissuers, jne
```

---

### Samm 7: Loo ClusterIssuer Let's Encrypt jaoks (10 min)

**ClusterIssuer** ütleb cert-manager'ile, kust sertifikaate hankida.

Loo fail `letsencrypt-clusterissuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Let's Encrypt production server
    server: https://acme-v02.api.letsencrypt.org/directory

    # Email teatiste jaoks
    email: sinu@email.com

    # Salvestab ACME konto private key
    privateKeySecretRef:
      name: letsencrypt-prod-key

    # HTTP-01 challenge (tõendab domeeni omandust)
    solvers:
    - http01:
        ingress:
          class: nginx
```

**Loo ka staging issuer testimiseks:**

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # Let's Encrypt staging server (ei loe rate limite vastu)
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: sinu@email.com
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

**Rakenda:**
```bash
kubectl apply -f letsencrypt-clusterissuer.yaml

# Kontrolli
kubectl get clusterissuer
# NAME                  READY   AGE
# letsencrypt-prod      True    10s
# letsencrypt-staging   True    10s
```

---

### Samm 8: Uuenda Ingress TLS jaoks (10 min)

Muuda oma Ingress ressurssi (Harjutus 2'st), et lisada TLS:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: default
  annotations:
    # Ingress class
    kubernetes.io/ingress.class: nginx

    # cert-manager annotation - loob automaatselt Certificate ressursi
    cert-manager.io/cluster-issuer: letsencrypt-prod

    # Redirect HTTP → HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"

    # Force SSL
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  # TLS konfiguratsioon
  tls:
  - hosts:
    - kirjakast.cloud
    - www.kirjakast.cloud
    secretName: kirjakast-cloud-tls  # cert-manager loob selle Secret'i

  rules:
  - host: kirjakast.cloud
    http:
      paths:
      - path: /api/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 3000

      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 8080
```

**Rakenda:**
```bash
kubectl apply -f app-ingress.yaml

# Vaata Ingress'i
kubectl get ingress app-ingress
# ADDRESS peaks olema täidetud
```

---

### Samm 9: Kontrolli Certificate loomist (5 min)

cert-manager loob automaatselt Certificate ressursi:

```bash
# Vaata Certificate ressurssi
kubectl get certificate

# Peaks näitama:
# NAME                   READY   SECRET                 AGE
# kirjakast-cloud-tls    True    kirjakast-cloud-tls    1m

# Vaata detaile
kubectl describe certificate kirjakast-cloud-tls

# Kontrolli event'e:
# Events:
#   Type    Reason     Age   Message
#   ----    ------     ----  -------
#   Normal  Issuing    2m    Issuing certificate as Secret does not exist
#   Normal  Generated  2m    Stored new private key in temporary Secret
#   Normal  Requested  2m    Created new CertificateRequest resource
#   Normal  Issuing    1m    The certificate has been successfully issued
```

**Kontrolli Secret'i:**
```bash
kubectl get secret kirjakast-cloud-tls

# Vaata sertifikaadi sisu
kubectl get secret kirjakast-cloud-tls -o yaml

# Dekodeeri sertifikaadi (base64)
kubectl get secret kirjakast-cloud-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -text
```

---

### Samm 10: Testi HTTPS Ingress'i kaudu (5 min)

```bash
# Test 1: HTTPS vastus
curl -I https://kirjakast.cloud/api/users

# Oodatud:
# HTTP/2 200
# server: nginx

# Test 2: HTTP redirect
curl -I http://kirjakast.cloud/api/users

# Oodatud:
# HTTP/1.1 308 Permanent Redirect
# Location: https://kirjakast.cloud/api/users

# Test 3: Kontrolli sertifikaati
echo | openssl s_client -connect kirjakast.cloud:443 -servername kirjakast.cloud 2>/dev/null | openssl x509 -noout -issuer -subject

# Oodated:
# issuer=C = US, O = Let's Encrypt, CN = R3
# subject=CN = kirjakast.cloud

# Test 4: Brauseris
# Külasta: https://kirjakast.cloud
# Peaks näitama rohelist lukku
```

---

## ✅ Kontrolli Tulemusi

### Path A - Täielik Tee

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Nginx + Let's Encrypt:**
  - [ ] certbot paigaldatud
  - [ ] Sertifikaat kirjakast.cloud domeenile
  - [ ] HTTPS töötab (https://kirjakast.cloud)
  - [ ] HTTP → HTTPS redirect
  - [ ] Automaatne uuendus seadistatud (certbot.timer)

- [ ] **Kubernetes + cert-manager:**
  - [ ] cert-manager paigaldatud
  - [ ] ClusterIssuer loodud (letsencrypt-prod)
  - [ ] Certificate ressurss loodud ja READY=True
  - [ ] Ingress TLS konfigureeritud
  - [ ] HTTPS töötab Ingress kaudu

### Path B - Kiire Tee

- [ ] **Kubernetes + cert-manager:**
  - [ ] cert-manager paigaldatud
  - [ ] ClusterIssuer loodud
  - [ ] Certificate ressurss valmis
  - [ ] Ingress HTTPS töötab

---

## 🐛 Troubleshooting

### Probleem 1: certbot ACME challenge ebaõnnestub

**Sümptom:**
```
Challenge failed for domain kirjakast.cloud
```

**Põhjused ja lahendused:**
1. **DNS ei osuta VPS IP-le:**
   ```bash
   # Kontrolli DNS
   dig kirjakast.cloud +short
   # Peaks näitama: 93.127.213.242
   ```

2. **Port 80 ei ole kättesaadav:**
   ```bash
   # Kontrolli firewall'i
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

3. **Nginx ei tööta:**
   ```bash
   sudo systemctl status nginx
   sudo systemctl start nginx
   ```

---

### Probleem 2: cert-manager Certificate ei muutu READY

**Sümptom:**
```bash
kubectl get certificate
# NAME                 READY   SECRET              AGE
# kirjakast-cloud-tls  False   kirjakast-cloud-tls 5m
```

**Debug:**
```bash
# Vaata Certificate event'e
kubectl describe certificate kirjakast-cloud-tls

# Vaata CertificateRequest
kubectl get certificaterequest
kubectl describe certificaterequest <name>

# Vaata Challenge (HTTP-01)
kubectl get challenge
kubectl describe challenge <name>

# Vaata cert-manager logisid
kubectl logs -n cert-manager deployment/cert-manager
```

**Levinud põhjused:**

1. **DNS ei osuta Ingress IP-le:**
   ```bash
   # Vaata Ingress IP
   kubectl get ingress app-ingress -o wide

   # Kontrolli DNS
   dig kirjakast.cloud +short
   ```

2. **Ingress class vale:**
   ```yaml
   # Kontrolli, et annotation on õige:
   kubernetes.io/ingress.class: nginx
   ```

3. **ClusterIssuer ei ole READY:**
   ```bash
   kubectl get clusterissuer letsencrypt-prod
   kubectl describe clusterissuer letsencrypt-prod
   ```

---

### Probleem 3: Let's Encrypt rate limit

**Sümptom:**
```
Error: too many certificates already issued
```

**Lahendus:**
Kasuta staging environment'i testimiseks:

```yaml
cert-manager.io/cluster-issuer: letsencrypt-staging
```

Let's Encrypt prod limit: 50 sertifikaati nädalas sama domeeni jaoks.

---

### Probleem 4: Sertifikaat ei uuene automaatselt

**Nginx (certbot):**
```bash
# Kontrolli timer'it
sudo systemctl status certbot.timer
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Testi uuendust
sudo certbot renew --dry-run
```

**Kubernetes (cert-manager):**
cert-manager uuendab automaatselt sertifikaate 30 päeva enne aegumist.

```bash
# Vaata Certificate renewal event'e
kubectl describe certificate kirjakast-cloud-tls
```

---

## 🎓 Õpitud Mõisted

### SSL/TLS Kontseptsioonid:
- **SSL/TLS:** Turvaline krüpteeritud ühendus
- **Certificate Authority (CA):** Let's Encrypt
- **ACME Protocol:** Automaatne sertifikaatide hankimine
- **HTTP-01 Challenge:** Domeeni omanduse tõendamine
- **Certificate Lifecycle:** Hangimine → Kasutamine → Uuendamine

### Certbot (Nginx):
- **certbot --nginx:** Automaatne Nginx konfigureerimine
- **certbot renew:** Sertifikaatide uuendamine
- **certbot.timer:** Systemd automaatne uuendus

### cert-manager (Kubernetes):
- **ClusterIssuer:** Globaalne sertifikaatide hankija
- **Certificate:** Kubernetes ressurss sertifikaadi jaoks
- **Secret:** Sertifikaadi ja private key salvestus
- **Ingress TLS:** HTTPS konfiguratsioon Ingress'is

---

## 💡 Parimad Tavad

### Üldised:
1. **Alati testi staging environment'is enne prod'i** (rate limit'ide vältimiseks)
2. **Kasuta automaatset uuendust** - käsitsi uuendamine on vigade allikas
3. **Monitoori sertifikaatide aegumist** - seadista alerte
4. **Kasuta HTTP → HTTPS redirect'i** - sunni kasutajaid turvalist ühendust kasutama

### Nginx (certbot):
1. **Backup enne certbot'i:** `sudo cp -r /etc/nginx /etc/nginx.backup`
2. **Testi enne reload'i:** `sudo nginx -t`
3. **Kontrolli cron job'i:** `sudo systemctl list-timers | grep certbot`

### Kubernetes (cert-manager):
1. **Alusta staging issuer'iga:** Väldi Let's Encrypt rate limite
2. **Üks ClusterIssuer kõigile:** Ära loo Issuer'it iga namespace'i jaoks
3. **Monitoori Certificate ressursse:** `kubectl get certificate -A`
4. **Kasuta annotations:** Ingress annotation on lihtsam kui manuaalne Certificate

---

## 🔗 Järgmine Samm

Järgmises harjutuses õpid pakendama oma rakendusi Helm Chart'ideks!

**Jätka:** [Harjutus 4: Helm Charts](04-helm-charts.md)

---

## 📚 Viited

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Certbot Documentation](https://eff-certbot.readthedocs.io/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Kubernetes Ingress TLS](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)

---

**Õnnitleme! Sinu rakendus on nüüd kaitstud HTTPS'iga! 🔒**
