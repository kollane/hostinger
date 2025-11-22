# Harjutus 1: Ingress Controller & Routing

**Kestus:** 60 minutit
**Eesmärk:** Asenda NodePort Ingress routing'uga

---

## 📋 Ülevaade

Selles harjutuses **asendad Lab 3 NodePort access Ingress routing'uga**. Õpid paigaldama Ingress Controller'it ja konfigureerima path-based routing'u.

**Enne vs Pärast:**
- **Enne (Lab 3):** Frontend NodePort :30080 → `http://VPS:30080`
- **Pärast (Lab 4):** Ingress → `http://kirjakast.cloud` (port 80)

---

## 🎯 Õpieesmärgid

- ✅ Mõista Ingress Controller vs Ingress Resource erinevust
- ✅ Paigaldada ingress-nginx Controller
- ✅ Luua Ingress ressurssi path-based routing'uks
- ✅ Testida Ingress routing'u
- ✅ Debuggida Ingress probleeme

---

## 🏗️ Arhitektuur

### Enne (Lab 3 - NodePort)

```
Browser → http://VPS:30080
              ↓
         Frontend Service (NodePort :30080)
              ↓
         Frontend Pods
```

### Pärast (Lab 4 - Ingress)

```
Browser → http://kirjakast.cloud
              ↓
         Ingress Controller (LoadBalancer/NodePort)
              ↓
         Ingress Resource (routing rules)
              ├─ / → Frontend Service
              ├─ /api/users → User Service
              └─ /api/todos → Todo Service
```

---

## 📝 Sammud

### Samm 1: Mõista Ingress Kontseptsiooni (5 min)

**Ingress = 2 komponenti:**

1. **Ingress Controller** (sisuliselt nginx pod cluster'is)
   - Jookseb Kubernetes pod'ina
   - Loeb Ingress ressursse
   - Suunab liiklust teenustele

2. **Ingress Resource** (YAML manifest routing reeglitega)
   - Defineerib path-based routing
   - Näitab milline path → milline Service

**Analoogia:**
- Ingress Controller = Nginx server
- Ingress Resource = nginx.conf fail

### Samm 2: Paigalda Ingress-nginx Controller (15 min)

**Meetod 1: Kubectl apply (soovitatud)**

```bash
# Paigalda ingress-nginx (official manifest)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Kontrolli paigaldust
kubectl get pods -n ingress-nginx
kubectl get services -n ingress-nginx

# Oodatud:
# NAME                                 READY   STATUS    RESTARTS   AGE
# ingress-nginx-controller-xxx         1/1     Running   0          1m
```

**Meetod 2: Helm (optional)**

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

**Kontrolli:**

```bash
# Ingress Controller Service
kubectl get svc -n ingress-nginx

# Minikube:
# TYPE: NodePort (EXTERNAL-IP: <none>)
# K3s/Cloud:
# TYPE: LoadBalancer (EXTERNAL-IP: pending või IP)
```

### Samm 3: Loo Ingress Ressurss (20 min)

Loo `app-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-app-ingress
  annotations:
    # Ingress-nginx specific
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: kirjakast.cloud  # Asenda oma domeeniga või kasuta IP'd
    http:
      paths:
      # Backend API routes (peaksid olema ENNE frontend'i)
      - path: /api/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 3000

      - path: /api/todos
        pathType: Prefix
        backend:
          service:
            name: todo-service
            port:
              number: 8081

      # Frontend (kõige üldisem, VIIMANE)
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

**Rakenda:**

```bash
kubectl apply -f app-ingress.yaml

# Kontrolli
kubectl get ingress
kubectl describe ingress todo-app-ingress
```

### Samm 4: Testi Ingress Routing (15 min)

**4a. Leia Ingress IP/Port**

```bash
# Minikube
minikube service -n ingress-nginx ingress-nginx-controller --url

# K3s/Kubeadm
kubectl get svc -n ingress-nginx ingress-nginx-controller
# NodePort: http://<NODE-IP>:<NODEPORT>
```

**4b. Testi path routing**

```bash
# Frontend (/)
curl http://<INGRESS-IP>/

# User Service API
curl http://<INGRESS-IP>/api/users

# Todo Service API
curl http://<INGRESS-IP>/api/todos

# Health checks
curl http://<INGRESS-IP>/api/users/health
curl http://<INGRESS-IP>/api/todos/health
```

**4c. Browser test**

```bash
# Ava brauseris
http://<INGRESS-IP>/
http://<INGRESS-IP>/api/users
```

### Samm 5: Debug Ingress Probleeme (5 min)

```bash
# 1. Kontrolli Ingress Controller logisid
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# 2. Kontrolli Ingress ressurssi
kubectl describe ingress todo-app-ingress

# 3. Kontrolli Services
kubectl get svc

# 4. Kontrolli backend Pods
kubectl get pods -l app=user-service
kubectl get pods -l app=todo-service
kubectl get pods -l app=frontend
```

---

## ✅ Kontrolli Tulemusi

- [ ] Ingress Controller töötab (`kubectl get pods -n ingress-nginx`)
- [ ] Ingress ressurss loodud (`kubectl get ingress`)
- [ ] Frontend kättesaadav: `http://<INGRESS-IP>/`
- [ ] User Service API: `http://<INGRESS-IP>/api/users`
- [ ] Todo Service API: `http://<INGRESS-IP>/api/todos`

---

## 🎓 Õpitud Mõisted

**Ingress Controller:**
- Nginx pod cluster'is
- Loeb Ingress ressursse
- Teeb reverse proxy

**Ingress Resource:**
- YAML manifest
- Defineerib routing reeglid
- pathType: Prefix vs Exact

**ingressClassName:**
- Uus (Kubernetes 1.18+)
- Asendab vana `kubernetes.io/ingress.class` annotation

**Annotations:**
- nginx-specific seaded
- `rewrite-target`, `ssl-redirect`, jne

---

## 💡 Parimad Praktikad

1. **Path järjekord:** API routes ENNE frontend'i
2. **pathType: Prefix** - kasulik kui `/api/users` → `/api/users/*`
3. **ingressClassName** - kasuta seda, mitte annotation'it
4. **Backend health checks** - veendu et teenused töötavad

---

## 🐛 Levinud Probleemid

### "Ingress ADDRESS empty"

```bash
# Ingress Controller pole valmis
kubectl get pods -n ingress-nginx
# Oota kuni STATUS = Running
```

### "404 Not Found"

```bash
# Vale path või service nimi
kubectl describe ingress todo-app-ingress
kubectl get svc  # Kontrolli service nimesid
```

### "502 Bad Gateway"

```bash
# Backend pods ei tööta
kubectl get pods
kubectl logs <pod-name>
```

---

## 🔗 Järgmine Samm

Järgmises harjutuses lisad **Horizontal Pod Autoscaler** (HPA) automaatseks skaleerimiseks!

**Jätka:** [Harjutus 2: Horizontal Pod Autoscaler](02-horizontal-pod-autoscaler.md)

---

## 📚 Viited

- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress-nginx Controller](https://kubernetes.github.io/ingress-nginx/)
- [Path Types](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types)

---

**Õnnitleme! Oled seadistanud Ingress routing'u! 🎉**
