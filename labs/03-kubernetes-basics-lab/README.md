# Labor 3: Kubernetes Alused

**Kestus:** 5 tundi
**Eeldused:** Labor 1-2 läbitud, Peatükk 15-16 (Kubernetes alused)
**Eesmärk:** Deploy'da rakendused Kubernetes cluster'isse

---

## 📋 Ülevaade

Selles laboris deploy'ad Labor 1'st loodud Docker image'd Kubernetes cluster'isse (Minikube või K3s).

---

## 🎯 Õpieesmärgid

✅ Luua Kubernetes Pods
✅ Hallata Deployments
✅ Seadistada Services (ClusterIP, NodePort, LoadBalancer)
✅ Kasutada ConfigMaps ja Secrets
✅ Hallata Persistent Volumes

---

## 📂 Labori Struktuur

```
03-kubernetes-basics-lab/
├── README.md
├── exercises/
│   ├── 01-pods.md
│   ├── 02-deployments.md
│   ├── 03-services.md
│   ├── 04-configmaps-secrets.md
│   └── 05-persistent-volumes.md
├── manifests/
│   ├── deployment-nodejs.yaml
│   ├── deployment-java.yaml
│   ├── service-nodejs.yaml
│   └── configmap.yaml
└── solutions/
```

---

**Staatus:** 📝 Framework valmis, sisu lisatakse
**Viimane uuendus:** 2025-11-15
