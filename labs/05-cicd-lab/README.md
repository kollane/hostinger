# Labor 5: CI/CD Pipeline

**Kestus:** 4 tundi
**Eeldused:** Labor 1-4 läbitud, Peatükk 20-21 (CI/CD)
**Eesmärk:** Automatiseerida build ja deploy protsess GitHub Actions'iga

---

## 📋 Ülevaade

Selles laboris lood CI/CD pipeline'i, mis automatiseerib Docker image build'i ja Kubernetes deployment'i.

---

## 🎯 Õpieesmärgid

✅ Luua GitHub Actions workflows
✅ Automatiseerida Docker image build ja push
✅ Auto-deploy Kubernetes'e
✅ Käivitada automated tests
✅ Implementeerida rollback strategy

---

## 📂 Labori Struktuur

```
05-cicd-lab/
├── README.md
├── exercises/
│   ├── 01-github-actions-basics.md
│   ├── 02-docker-build-push.md
│   ├── 03-kubernetes-deploy.md
│   ├── 04-automated-testing.md
│   └── 05-rollback-strategy.md
├── .github/
│   └── workflows/
│       ├── build.yml
│       └── deploy.yml
└── solutions/
```

---

**Staatus:** 📝 Framework valmis, sisu lisatakse
**Viimane uuendus:** 2025-11-15
