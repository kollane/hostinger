# Lab 4 Lahendused

See kataloog sisaldab reference lahendusi Lab 4 harjutustele.

---

## 📂 Kataloogistruktuur

```
solutions/
├── README.md                    # See fail
├── nginx/                       # Harjutus 01 lahendused
│   └── kirjakast.cloud.conf    # Nginx reverse proxy konfiguratsioon
├── kubernetes/                  # Harjutus 02-05 lahendused
│   └── app-ingress.yaml        # Kubernetes Ingress manifest
└── helm/                        # Harjutus 04 lahendus (tulevikus)
    └── todo-app/               # Helm chart
```

---

## 🔧 Harjutus 01: DNS + Nginx Reverse Proxy

### nginx/kirjakast.cloud.conf

**Kirjeldus:** Nginx virtual host konfiguratsioon, mis suunab liiklust domeenist `kirjakast.cloud` Docker Compose teenustele.

**Kasutamine:**

```bash
# 1. Kopeeri fail Nginx sites-available kataloogi
sudo cp nginx/kirjakast.cloud.conf /etc/nginx/sites-available/kirjakast.cloud

# 2. Loo symlink sites-enabled kataloogi
sudo ln -s /etc/nginx/sites-available/kirjakast.cloud /etc/nginx/sites-enabled/

# 3. Testi konfiguratsiooni
sudo nginx -t

# 4. Taaslae Nginx
sudo systemctl reload nginx

# 5. Kontrolli staatust
sudo systemctl status nginx

# 6. Testi brauserist
curl http://kirjakast.cloud/
curl http://kirjakast.cloud/api/todos
```

**Eeldused:**
- Nginx paigaldatud (`sudo apt install nginx`)
- Docker Compose stack töötab (`cd labs/apps && docker compose up -d`)
- DNS A-kirje: `kirjakast.cloud → VPS IP`

**Routing:**
- `/` → Frontend (port 8080)
- `/todo` → Frontend (port 8080)
- `/api/todos` → Todo Service (port 8081)
- `/api/users` → User Service (port 3000)
- `/api/auth` → User Service (port 3000)
- `/health/user` → User Service health (port 3000)
- `/health/todo` → Todo Service health (port 8081)

---

## ☸️ Harjutus 02: Kubernetes Ingress

### kubernetes/app-ingress.yaml

**Kirjeldus:** Kubernetes Ingress ressurss, mis suunab liiklust path'i põhiselt erinevatele teenustele.

**Eeldused:**

1. **Nginx Ingress Controller paigaldatud:**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Kontrolli
kubectl get pods -n ingress-nginx
kubectl get ingressclass
```

2. **Rakendused paigaldatud Kubernetes'esse:**
```bash
# Namespace
kubectl create namespace todo-app

# PostgreSQL, User Service, Todo Service, Frontend
# (Vaata Harjutus 02 samm 2 täielikke manifest'e)
```

**Kasutamine:**

```bash
# 1. Rakenda Ingress
kubectl apply -f kubernetes/app-ingress.yaml

# 2. Kontrolli staatust
kubectl get ingress -n todo-app
kubectl describe ingress todo-app-ingress -n todo-app

# 3. Leia Ingress IP
kubectl get ingress -n todo-app todo-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 4. Seadista DNS
# DNS A-kirje: kirjakast.cloud → <Ingress IP>

# 5. Testi
curl http://kirjakast.cloud/
curl http://kirjakast.cloud/api/todos
```

**Annotation'id:**

- `nginx.ingress.kubernetes.io/rewrite-target: /` - URL rewrite
- `nginx.ingress.kubernetes.io/enable-cors: "true"` - CORS tugi
- `nginx.ingress.kubernetes.io/proxy-*-timeout: "60"` - Timeout'id

**Routing (sama kui Nginx variant):**
- `/` → `frontend:80`
- `/todo` → `frontend:80`
- `/api/todos` → `todo-service:8081`
- `/api/users` → `user-service:3000`
- `/api/auth` → `user-service:3000`

---

## 🎓 Võrdlus: Nginx vs Kubernetes Ingress

### Konfiguratsioonifailid

**Nginx (`nginx/kirjakast.cloud.conf`):**
```nginx
upstream user-service {
    server localhost:3000;
}

location /api/users {
    proxy_pass http://user-service;
    proxy_set_header Host $host;
}
```

**Kubernetes Ingress (`kubernetes/app-ingress.yaml`):**
```yaml
- path: /api/users
  pathType: Prefix
  backend:
    service:
      name: user-service
      port:
        number: 3000
```

### Muudatuste Rakendamine

**Nginx:**
```bash
vim /etc/nginx/sites-available/kirjakast.cloud
nginx -t
systemctl reload nginx
```

**Kubernetes:**
```bash
vim app-ingress.yaml
kubectl apply -f app-ingress.yaml
# Automaatselt rakenduv
```

### Load Balancing

**Nginx:**
```nginx
upstream user-service {
    server localhost:3000;
    server localhost:3001;  # Käsitsi lisatud
    server localhost:3002;
}
```

**Kubernetes:**
```yaml
# Automaatne - Service discovery
# Ingress suunab → Service → kõik pod'id (endpoints)
spec:
  replicas: 3  # Deployment'is
```

---

## 🐛 Troubleshooting

### Nginx ei tööta

```bash
# Kontrolli süntaksit
sudo nginx -t

# Vaata logisid
sudo tail -f /var/log/nginx/kirjakast.cloud-error.log

# Kontrolli kas backend teenused töötavad
docker compose ps

# Testi backend'i otse
curl http://localhost:3000/health
curl http://localhost:8081/health
```

### Kubernetes Ingress ei tööta

```bash
# Kontrolli Ingress Controller'it
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Kontrolli Ingress ressurssi
kubectl get ingress -n todo-app
kubectl describe ingress -n todo-app todo-app-ingress

# Kontrolli Service endpoints
kubectl get endpoints -n todo-app

# Kontrolli pod'ide staatust
kubectl get pods -n todo-app
kubectl logs -n todo-app <pod-name>
```

---

## 💡 Kasulikud Käsud

### Nginx

```bash
# Testi konfiguratsioon
sudo nginx -t

# Taaslae ilma downtime'ita
sudo systemctl reload nginx

# Restart
sudo systemctl restart nginx

# Vaata access logi reaalajas
sudo tail -f /var/log/nginx/kirjakast.cloud-access.log

# Vaata error logi
sudo tail -f /var/log/nginx/kirjakast.cloud-error.log

# Leia Nginx protsess
ps aux | grep nginx

# Kontrolli avatud porte
sudo netstat -tlnp | grep :80
```

### Kubernetes

```bash
# Ingress
kubectl get ingress -n todo-app
kubectl describe ingress -n todo-app <name>
kubectl edit ingress -n todo-app <name>
kubectl delete ingress -n todo-app <name>

# Ingress Controller logid
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=100 -f

# Service endpoints
kubectl get endpoints -n todo-app
kubectl describe endpoints -n todo-app <service-name>

# Port-forward (testimiseks)
kubectl port-forward -n todo-app service/user-service 3000:3000

# Ingress Controller Nginx config
kubectl exec -it -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf
```

---

## 📚 Edasine Lugemine

### Nginx
- [Nginx Reverse Proxy Docs](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Nginx Upstream Module](https://nginx.org/en/docs/http/ngx_http_upstream_module.html)
- [Nginx Virtual Server Examples](https://www.nginx.com/resources/wiki/start/topics/examples/server_blocks/)

### Kubernetes Ingress
- [Kubernetes Ingress Docs](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Ingress Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)

---

## ✅ Checklist - Kas Lahendus Töötab?

### Nginx (Harjutus 01)

- [ ] `sudo nginx -t` → syntax is ok
- [ ] `systemctl status nginx` → active (running)
- [ ] `curl http://kirjakast.cloud/` → HTTP 200
- [ ] `curl http://kirjakast.cloud/api/todos` → JSON response
- [ ] `curl http://kirjakast.cloud/health/user` → {"status":"UP"}

### Kubernetes Ingress (Harjutus 02)

- [ ] `kubectl get pods -n ingress-nginx` → Running
- [ ] `kubectl get ingress -n todo-app` → ADDRESS not empty
- [ ] `kubectl get pods -n todo-app` → All Running
- [ ] `kubectl get endpoints -n todo-app` → All have IP addresses
- [ ] `curl http://kirjakast.cloud/` → HTTP 200 (via Ingress)
- [ ] `curl http://kirjakast.cloud/api/todos` → JSON (via Ingress)

---

**Viimane uuendus:** 2025-11-16
**Autor:** DevOps Training Labs
