# LXD Template ja Konteineri Olemus

## Lihtne analoogia

```
Template (Image)     =  Küpsetise vorm / Master koopia
Konteiner            =  Küpsetis / Koopia vormist
```

---

## Template (Image) - "Master koopia"

**Mis see on:**
Template on **salvestatud süsteemi pilt**, mis sisaldab kõike eelseadistatud:
- Operatsioonisüsteem (Ubuntu 24.04)
- Paigaldatud tarkvara (Docker, Java, Node.js, kubectl...)
- Konfiguratsioonid (.bashrc, proxy seaded...)
- Kasutajad (labuser)

**Kuidas see tekib (K8S-INSTALLATION.md näide):**

```bash
# 1. Loo tavaline konteiner Ubuntu baasilt
lxc launch ubuntu:24.04 k8s-template -p default -p devops-lab-k8s

# 2. Logi sisse ja seadista KÕIK mis vaja
lxc exec k8s-template -- bash
apt-get install -y docker-ce openjdk-21-jdk nodejs...
# ... palju seadistamist ...
exit

# 3. PEATA konteiner
lxc stop k8s-template

# 4. "Külmuta" see image'iks (template'iks)
lxc publish k8s-template --alias k8s-lab-base

# 5. Kustuta algne konteiner (enam ei vaja)
lxc delete k8s-template
```

**Tulemus:** `k8s-lab-base` on nüüd template, mida saab kasutada uute konteinerite loomiseks.

---

## Konteiner - "Koopia template'ist"

**Mis see on:**
Konteiner on **töötav instants** template'ist. Iga õpilane saab oma koopia.

**Kuidas see tekib:**

```bash
# Loo konteiner template'ist (sekundid!)
lxc launch k8s-lab-base devops-k8s-student1

# Iga õpilane saab IDENTSE algseisu
lxc launch k8s-lab-base devops-k8s-student2
lxc launch k8s-lab-base devops-k8s-student3
```

**Oluline:** Konteinerid on **iseseisvad**. Kui student1 paigaldab midagi, siis student2 seda ei näe.

---

## Visuaalne ülevaade

```
┌─────────────────────────────────────────────────────────────┐
│                    ubuntu:24.04                              │
│                  (Canonical'i image)                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼ lxc launch
┌─────────────────────────────────────────────────────────────┐
│                   k8s-template                               │
│                 (ajutine konteiner)                          │
│                                                              │
│   + apt install docker, java, nodejs, kubectl, helm...      │
│   + loo labuser kasutaja                                    │
│   + seadista .bashrc, proxy...                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼ lxc stop + lxc publish
┌─────────────────────────────────────────────────────────────┐
│                  k8s-lab-base                                │
│              ⭐ TEMPLATE (image) ⭐                           │
│                                                              │
│   Kõik on sees ja ootab kasutamist                          │
└──────────┬──────────────┬──────────────┬────────────────────┘
           │              │              │
           ▼              ▼              ▼  lxc launch
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ student1 │   │ student2 │   │ student3 │
    │          │   │          │   │          │
    │ Oma K8s  │   │ Oma K8s  │   │ Oma K8s  │
    │ klaster  │   │ klaster  │   │ klaster  │
    └──────────┘   └──────────┘   └──────────┘
      KONTEINER      KONTEINER      KONTEINER
```

---

## Miks see kasulik on?

| Probleem | Lahendus template'iga |
|----------|----------------------|
| Iga õpilase seadistamine võtab 2+ tundi | Template'ist konteiner ~30 sekundit |
| "Mul ei tööta, sul töötab" | Kõik alustavad IDENTSEST seisust |
| Õpilane rikkus keskkonna | Kustuta konteiner, loo uus template'ist |
| Uuendus vaja kõigile | Tee uus template, loo konteinerid uuesti |

---

## Käsud kokkuvõttes

```bash
# TEMPLATE haldus
lxc image list                    # Vaata template'e
lxc image delete k8s-lab-base     # Kustuta template

# KONTEINERI haldus
lxc list                          # Vaata konteinereid
lxc launch k8s-lab-base student1  # Loo konteiner template'ist
lxc stop student1                 # Peata
lxc start student1                # Käivita
lxc delete student1               # Kustuta
lxc exec student1 -- bash         # Logi sisse
```

---

## Seotud juhendid

- [INSTALLATION.md](INSTALLATION.md) - Docker laborite template (Lab 1-2)
- [K8S-INSTALLATION.md](K8S-INSTALLATION.md) - Kubernetes laborite template (Lab 3-10)

---

**Viimane uuendus:** 2025-12-01
