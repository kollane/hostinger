# Lab 3 Lahendused

Siin kaustas asuvad Lab 3 harjutuste lahenduste failid.

---

## 📂 Struktuur

Lahendused on organiseeritud vastavalt harjutustele:

```
solutions/
├── README.md                    # See fail
├── 01-pods/                     # Harjutus 1 lahendused
│   ├── user-pod.yaml
│   └── multi-container-pod.yaml
├── 02-deployments/              # Harjutus 2 lahendused
│   ├── user-deployment.yaml
│   └── frontend-deployment.yaml
├── 03-services/                 # Harjutus 3 lahendused
│   ├── user-service-clusterip.yaml
│   ├── frontend-nodeport.yaml
│   └── frontend-loadbalancer.yaml
├── 04-config/                   # Harjutus 4 lahendused
│   ├── app-config.yaml
│   ├── db-config.yaml
│   ├── db-credentials-secret.yaml
│   └── deployment-with-config.yaml
└── 05-storage/                  # Harjutus 5 lahendused
    ├── postgres-pv.yaml
    ├── postgres-pvc.yaml
    ├── postgres-deployment.yaml
    └── postgres-statefulset.yaml
```

---

## 🎯 Kuidas Kasutada

### Variant 1: Proovi ise enne

**Soovitatav õppimiseks!**

1. Loe harjutuse juhised (`exercises/XX-topic.md`)
2. Proovi ise YAML'i kirjutada
3. Kui jääd kinni, vaata `solutions/XX-topic/` kaustast vihjet
4. Testi oma lahendust
5. Võrdle lahendusega

### Variant 2: Kasuta lahendusi otse

Kui soovid kiirelt testida või jääd täiesti kinni:

```bash
# Näide: Deploy user-service Deployment
cd solutions/02-deployments
kubectl apply -f user-deployment.yaml

# Kontrolli
kubectl get deployments
kubectl get pods
```

---

## ⚠️ Tähtis

**Lahendused on näidised!**

- Mõned väärtused (nt image, paths) võivad erineda sinu keskk

onnast
- Konfigureeri vastavalt vajadusele (DB paroolid, resource limits, jne)
- Proovi alati ise enne lahenduse vaatamist!

---

## 📚 Viited

- [Harjutus 1: Pods](../exercises/01-pods.md)
- [Harjutus 2: Deployments](../exercises/02-deployments.md)
- [Harjutus 3: Services](../exercises/03-services.md)
- [Harjutus 4: ConfigMaps & Secrets](../exercises/04-configmaps-secrets.md)
- [Harjutus 5: Persistent Volumes](../exercises/05-persistent-volumes.md)

---

**Edu õppimisega! Proovi alati ise enne lahenduse vaatamist! 🚀**
