# Harjutus 3: Kubernetes Deployment Automatis eerimine

**Kestus:** 60 minutit
**Eesmärk:** Automatiseerida Kubernetes deployment GitHub Actions'iga

---

## 📋 Ülevaade

Selles harjutuses õpid automatiseerima Kubernetes deployment'e GitHub Actions workflow'dega. Iga kord kui Docker image push'itakse Docker Hub'i, deploy'takse see automaatselt Kubernetes clusterisse.

**Continuous Deployment (CD)** tagab, et uued versioonid jõuavad production'i kiiresti ja turvaliselt. Kasutame `kubectl` action'eid ja rolling update strateegiat zero-downtime deployment'iks.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Seadistada kubeconfig secret GitHub Actions's
- ✅ Kasutada kubectl GitHub Actions workflow's
- ✅ Deploy'da Kubernetes Deployment'e automaatselt
- ✅ Teostada rolling update'sid
- ✅ Verifitseerida deployment'i õnnestumist
- ✅ Implementeerida health check'e peale deploy'i
- ✅ Rollback'ida ebaõnnestunud deployment'e

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────────────────────────┐
│           GitHub Repository                     │
│                                                 │
│  Code push → Docker build → Docker Hub          │
│         │                                       │
│         ▼                                       │
│  ┌───────────────────────────────────────────┐ │
│  │  .github/workflows/deploy.yml            │ │
│  │                                           │ │
│  │  1. Setup kubectl                         │ │
│  │  2. Update deployment image               │ │
│  │  3. Wait for rollout                      │ │
│  │  4. Verify health                         │ │
│  └────────────────┬──────────────────────────┘ │
│                   │                             │
└───────────────────┼─────────────────────────────┘
                    │
                    ▼ kubectl apply
        ┌───────────────────────────┐
        │  Kubernetes Cluster       │
        │                           │
        │  ┌─────────────────────┐  │
        │  │ Deployment          │  │
        │  │  user-service       │  │
        │  │                     │  │
        │  │  Pods:              │  │
        │  │  - v1.0.0 (old) ⟳   │  │
        │  │  - v1.1.0 (new) ✓   │  │
        │  │                     │  │
        │  │  Rolling update     │  │
        │  │  Old → New          │  │
        │  └─────────────────────┘  │
        └───────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Valmista Kubernetes Manifest (10 min)

**Loo Kubernetes manifest failid:**

Loo kataloog ja manifest:

```bash
mkdir -p k8s
vim k8s/deployment.yaml
```

**`k8s/deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Mitu uut pod'i lisada korraga
      maxUnavailable: 1  # Mitu pod'i võib olla unavailable
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: your-username/user-service:latest  # Asendatakse CI/CD's
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: PORT
          value: "3000"
        - name: NODE_ENV
          value: "production"
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: user-service-secrets
              key: db-host
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: user-service-secrets
              key: db-user
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: user-service-secrets
              key: db-password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: user-service-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
  selector:
    app: user-service
```

**Loo Secrets (local cluster'is):**

```bash
# Loo secrets Kubernetes'es (local testing jaoks)
kubectl create secret generic user-service-secrets \
  --from-literal=db-host=postgres \
  --from-literal=db-user=postgres \
  --from-literal=db-password=postgres \
  --from-literal=jwt-secret=your-jwt-secret

# Kontrolli
kubectl get secret user-service-secrets
```

**Commit:**

```bash
git add k8s/deployment.yaml
git commit -m "Add Kubernetes deployment manifest"
git push origin main
```

---

### Samm 2: Ekspordi Kubeconfig (10 min)

**Kubeconfig** = Kubernetes cluster'i autentimise konfiguratsioon.

**1. Ekspordi kubeconfig:**

```bash
# Variant A: Minikube
kubectl config view --flatten --minify > kubeconfig.yaml

# Variant B: K3s
sudo cat /etc/rancher/k3s/k3s.yaml > kubeconfig.yaml

# Kontrolli
cat kubeconfig.yaml

# Peaks sisaldama:
# - cluster: server URL
# - user: credentials (certificate, token)
# - context: cluster + user binding
```

**2. Kodeer base64 (GitHub Secret jaoks):**

```bash
# Kodeer base64
cat kubeconfig.yaml | base64 -w 0 > kubeconfig-base64.txt

# Kopeeri sisu
cat kubeconfig-base64.txt

# Kopeeris clipboard'i: long-base64-string...
```

**3. Lisa GitHub Secret:**

1. GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Kliki **New repository secret**
3. Name: `KUBECONFIG`
4. Value: (paste base64 string)
5. Kliki **Add secret**

**Puhasta local failid (OLULINE!):**

```bash
# Kustuta kubeconfig failid (ei tohi jääda Git'i!)
rm kubeconfig.yaml kubeconfig-base64.txt

# Veendu, et .gitignore sisaldab
echo "kubeconfig*" >> .gitignore
git add .gitignore
git commit -m "Add kubeconfig to gitignore"
```

---

### Samm 3: Loo Deployment Workflow (15 min)

**Loo workflow Kubernetes deployment'iks:**

Loo fail `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Kubernetes

on:
  workflow_run:
    workflows: ["Docker Build and Push"]
    types:
      - completed
    branches: [main]
  workflow_dispatch:  # Manual trigger

env:
  DEPLOYMENT_NAME: user-service
  IMAGE_NAME: ${{ secrets.DOCKER_USERNAME }}/user-service

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}

    steps:
      # Step 1: Checkout code
      - name: Checkout code
        uses: actions/checkout@v3

      # Step 2: Setup kubectl
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.28.0'

      # Step 3: Configure kubeconfig
      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > $HOME/.kube/config
          chmod 600 $HOME/.kube/config

      # Step 4: Verify cluster connection
      - name: Verify cluster connection
        run: |
          kubectl cluster-info
          kubectl get nodes

      # Step 5: Update deployment image
      - name: Update deployment image
        run: |
          # Get latest image tag from Docker Hub (või SHA)
          IMAGE_TAG="${{ github.sha }}"

          # Set new image
          kubectl set image deployment/${{ env.DEPLOYMENT_NAME }} \
            ${{ env.DEPLOYMENT_NAME }}=${{ env.IMAGE_NAME }}:sha-$IMAGE_TAG \
            --record

          echo "✅ Deployment image updated to ${{ env.IMAGE_NAME }}:sha-$IMAGE_TAG"

      # Step 6: Wait for rollout to complete
      - name: Wait for rollout
        run: |
          kubectl rollout status deployment/${{ env.DEPLOYMENT_NAME }} \
            --timeout=5m

          echo "✅ Rollout completed successfully"

      # Step 7: Verify deployment
      - name: Verify deployment
        run: |
          # Check pods
          kubectl get pods -l app=${{ env.DEPLOYMENT_NAME }}

          # Check deployment
          kubectl get deployment ${{ env.DEPLOYMENT_NAME }}

          # Check replicaset
          kubectl get replicaset -l app=${{ env.DEPLOYMENT_NAME }}

      # Step 8: Health check
      - name: Health check
        run: |
          # Port forward
          kubectl port-forward deployment/${{ env.DEPLOYMENT_NAME }} 3000:3000 &
          PID=$!

          # Wait for port forward
          sleep 5

          # Health check
          HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")

          # Kill port forward
          kill $PID

          if [ "$HTTP_CODE" == "200" ]; then
            echo "✅ Health check passed (HTTP $HTTP_CODE)"
          else
            echo "❌ Health check failed (HTTP $HTTP_CODE)"
            exit 1
          fi

      # Step 9: Deployment summary
      - name: Deployment summary
        run: |
          echo "🎉 Deployment successful!"
          echo "📦 Image: ${{ env.IMAGE_NAME }}:sha-${{ github.sha }}"
          echo "🔢 Replicas: $(kubectl get deployment ${{ env.DEPLOYMENT_NAME }} -o jsonpath='{.spec.replicas}')"
          echo "✅ Available: $(kubectl get deployment ${{ env.DEPLOYMENT_NAME }} -o jsonpath='{.status.availableReplicas}')"
```

**Workflow selgitus:**

- **workflow_run:** Käivitub peale "Docker Build and Push" edukat lõppu
- **Setup kubectl:** Install kubectl binary
- **Configure kubeconfig:** Dekodeerib ja seadistab kubeconfig
- **kubectl set image:** Uuendab deployment'i image'i (rolling update)
- **kubectl rollout status:** Ootab rollout'i lõppu (5min timeout)
- **Health check:** Port forward + curl /health

**Commit ja push:**

```bash
git add .github/workflows/deploy.yml
git commit -m "Add Kubernetes deployment workflow"
git push origin main
```

---

### Samm 4: Vaata Deployment Käivitumist (5 min)

**Workflow käivitub automaatselt:**

1. **Docker Build** workflow lõpetab edukalt
2. **Deploy to Kubernetes** workflow käivitub automaatselt
3. Actions tab → "Deploy to Kubernetes"

**Oodatud väljund:**

```
✅ Checkout code
✅ Setup kubectl
   kubectl version: v1.28.0
✅ Configure kubeconfig
   Kubeconfig configured
✅ Verify cluster connection
   Kubernetes master is running at https://...
   NAME       STATUS   ROLES    AGE
   minikube   Ready    control-plane   10d
✅ Update deployment image
   deployment.apps/user-service image updated
   ✅ Deployment image updated to user-service:sha-abc123
✅ Wait for rollout
   Waiting for deployment "user-service" rollout to finish: 1 out of 3 new replicas have been updated...
   Waiting for deployment "user-service" rollout to finish: 2 out of 3 new replicas have been updated...
   Waiting for deployment "user-service" rollout to finish: 1 old replicas are pending termination...
   deployment "user-service" successfully rolled out
   ✅ Rollout completed successfully
✅ Verify deployment
   NAME                            READY   STATUS    RESTARTS   AGE
   user-service-7d4b8f9c8d-abcde   1/1     Running   0          30s
   user-service-7d4b8f9c8d-fghij   1/1     Running   0          25s
   user-service-7d4b8f9c8d-klmno   1/1     Running   0          20s
✅ Health check
   ✅ Health check passed (HTTP 200)
✅ Deployment summary
   🎉 Deployment successful!
   📦 Image: user-service:sha-abc123
   🔢 Replicas: 3
   ✅ Available: 3
```

---

### Samm 5: Kontrolli Kubernetes Cluster'is (5 min)

**Kontrolli deployment'i local cluster'is:**

```bash
# Vaata deployment'i
kubectl get deployment user-service

# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   3/3     3            3           5m

# Vaata pod'e
kubectl get pods -l app=user-service

# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-7d4b8f9c8d-abcde   1/1     Running   0          2m
# user-service-7d4b8f9c8d-fghij   1/1     Running   0          2m
# user-service-7d4b8f9c8d-klmno   1/1     Running   0          2m

# Vaata rollout history
kubectl rollout history deployment/user-service

# REVISION  CHANGE-CAUSE
# 1         kubectl set image deployment/user-service user-service=user-service:sha-abc123 --record=true
# 2         kubectl set image deployment/user-service user-service=user-service:sha-def456 --record=true

# Vaata image version'i
kubectl get deployment user-service -o jsonpath='{.spec.template.spec.containers[0].image}'

# user-service:sha-abc123
```

---

### Samm 6: Testi Rolling Update (10 min)

**Loo uus code change ja vaata rolling update'i:**

```bash
# Muuda koodi (näiteks server.js)
echo "// Updated $(date)" >> server.js

# Commit ja push
git add server.js
git commit -m "Update code - trigger CI/CD"
git push origin main

# Workflow'd käivituvad:
# 1. Docker Build and Push
# 2. Deploy to Kubernetes (automaatselt peale build'i)
```

**Vaata rolling update'i real-time:**

```bash
# Teises terminalis
watch kubectl get pods -l app=user-service

# Näed:
# NAME                            READY   STATUS              RESTARTS   AGE
# user-service-7d4b8f9c8d-abcde   1/1     Running             0          5m   ← Old
# user-service-7d4b8f9c8d-fghij   1/1     Running             0          5m   ← Old
# user-service-7d4b8f9c8d-klmno   1/1     Terminating         0          5m   ← Old removing
# user-service-9f6c7a2b1e-pqrst   0/1     ContainerCreating   0          5s   ← New creating
# user-service-9f6c7a2b1e-uvwxy   1/1     Running             0          10s  ← New running

# Rolling update protsess:
# 1. Create new pod (v2)
# 2. Wait for ready
# 3. Terminate old pod (v1)
# 4. Repeat until all updated
```

**Zero-downtime kinnitamine:**

```bash
# Continuous requests testiks
while true; do
  curl -s http://user-service/health | jq '.status'
  sleep 1
done

# Peaks alati vastama (ei tohi katkeda rolling update ajal)
```

---

### Samm 7: Implementeeri Rollback (5 min)

**Kui deployment ebaõnnestub, rollback:**

**Manual rollback:**

```bash
# Rollback eelmisele revision'ile
kubectl rollout undo deployment/user-service

# Või specific revision'ile
kubectl rollout undo deployment/user-service --to-revision=1

# Kontrolli
kubectl rollout status deployment/user-service
```

**Automaatne rollback workflow's:**

Lisa `deploy.yml` lõppu:

```yaml
      # Step 10: Rollback on failure
      - name: Rollback on failure
        if: failure()
        run: |
          echo "❌ Deployment failed, rolling back..."
          kubectl rollout undo deployment/${{ env.DEPLOYMENT_NAME }}
          kubectl rollout status deployment/${{ env.DEPLOYMENT_NAME }}
          echo "✅ Rollback completed"
```

---

### Samm 8: Lisa Deployment Notifications (Optional, 5 min)

**Saada Slack/Discord notification peale deployment'i:**

Lisa `deploy.yml` lõppu:

```yaml
      # Step 11: Notify success
      - name: Notify Slack
        if: success()
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
          payload: |
            {
              "text": "✅ Deployment successful!",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Deployment successful!*\n📦 Image: ${{ env.IMAGE_NAME }}:sha-${{ github.sha }}\n🔗 <${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View workflow>"
                  }
                }
              ]
            }
```

(Vajab `SLACK_WEBHOOK_URL` secret'i)

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Kubernetes manifest:**
  - [ ] `k8s/deployment.yaml`
  - [ ] Service + Deployment

- [ ] **GitHub Secret:**
  - [ ] `KUBECONFIG` (base64 encoded)

- [ ] **Workflow:**
  - [ ] `.github/workflows/deploy.yml`
  - [ ] Käivitub peale Docker build'i

- [ ] **Deployment toimib:**
  - [ ] Rolling update zero-downtime
  - [ ] Health check pass
  - [ ] Deployment verified

- [ ] **Cluster'is:**
  - [ ] Deployment: `user-service` (3 replicas)
  - [ ] Service: `user-service`
  - [ ] Pods: 3x running

---

## 🐛 Troubleshooting

### Probleem 1: kubectl ei saa ühendust cluster'iga

**Sümptom:**
```
❌ Verify cluster connection
   error: You must be logged in to the server (Unauthorized)
```

**Diagnoos:**

1. **Kontrolli kubeconfig secret:**

```bash
# Dekodeerib secret local'is
echo "$KUBECONFIG_BASE64" | base64 -d > kubeconfig-test.yaml

# Testi
kubectl --kubeconfig=kubeconfig-test.yaml get nodes
```

2. **Kontrolli kubeconfig expiration:**

```bash
# Mõned kubeconfig'd aeguvad (tokens, certificates)
kubectl config view --minify
```

**Lahendus:**

```bash
# Genereeri uus kubeconfig
kubectl config view --flatten --minify > kubeconfig-new.yaml

# Base64 encode
cat kubeconfig-new.yaml | base64 -w 0

# Uuenda GitHub secret
# Settings → Secrets → KUBECONFIG → Update
```

---

### Probleem 2: Rollout timeout

**Sümptom:**
```
❌ Wait for rollout
   error: timed out waiting for the condition
```

**Põhjused:**

1. **Image pull failed** (ImagePullBackOff)
2. **Pod crash** (CrashLoopBackOff)
3. **Resource limits** (Insufficient CPU/memory)

**Diagnoos:**

```bash
# Vaata pod'ide state
kubectl get pods -l app=user-service

# Describe problematic pod
kubectl describe pod <pod-name>

# Vaata logisid
kubectl logs <pod-name>
```

**Lahendus:**

```yaml
# Workflow's lisa debug step
- name: Debug failed deployment
  if: failure()
  run: |
    kubectl get pods -l app=${{ env.DEPLOYMENT_NAME }}
    kubectl describe deployment ${{ env.DEPLOYMENT_NAME }}
    kubectl logs -l app=${{ env.DEPLOYMENT_NAME }} --tail=50
```

---

### Probleem 3: Health check ebaõnnestub

**Sümptom:**
```
❌ Health check
   ❌ Health check failed (HTTP 000)
```

**Põhjused:**

1. **Port forward failed**
2. **/health endpoint ei vasta**
3. **Pods pole valmis**

**Diagnoos:**

```bash
# Manual health check
kubectl port-forward deployment/user-service 3000:3000
curl http://localhost:3000/health
```

**Lahendus:**

```yaml
# Workflow's lisa retry
- name: Health check with retry
  run: |
    kubectl port-forward deployment/${{ env.DEPLOYMENT_NAME }} 3000:3000 &
    PID=$!
    sleep 5

    # Retry 3 times
    for i in {1..3}; do
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")
      if [ "$HTTP_CODE" == "200" ]; then
        echo "✅ Health check passed"
        kill $PID
        exit 0
      fi
      echo "⏳ Retry $i/3..."
      sleep 5
    done

    kill $PID
    echo "❌ Health check failed"
    exit 1
```

---

## 🎓 Õpitud Mõisted

### Kubernetes Deployment:
- **Rolling Update:** Järkjärguline update (zero-downtime)
- **maxSurge:** Mitu uut pod'i lisada korraga
- **maxUnavailable:** Mitu pod'i võib olla unavailable
- **Rollout:** Deployment update protsess
- **Rollback:** Tagasi eelmisele versioonile

### kubectl Commands:
- **kubectl set image:** Update deployment image
- **kubectl rollout status:** Vaata rollout progressi
- **kubectl rollout history:** Vaata revision history
- **kubectl rollout undo:** Rollback deployment
- **kubectl port-forward:** Local access pod'ile

### GitHub Actions Kubernetes:
- **azure/setup-kubectl:** Install kubectl
- **kubeconfig secret:** Cluster autentimiseks
- **workflow_run:** Trigger peale teise workflow'i

---

## 💡 Parimad Tavad

1. **Kasuta rolling update** - Zero-downtime deployment
2. **Lisa health check'id** - Liveness + readiness probes
3. **Seadista resource limits** - Vältimaks resource exhaustion
4. **Versiooni image'id** - SHA või semantic versioning (mitte `latest`)
5. **Kasuta rollout status** - Kontrolli deployment õnnestumist
6. **Automaatne rollback** - `if: failure()` step
7. **Testi health check** - Verifitseeri /health endpoint peale deploy'i
8. **Kasuta secrets** - Ära harda-code kubeconfig
9. **Record rollout history** - `--record` flag
10. **Monitor pod'e** - Deployment verification step

---

## 🔗 Järgmine Samm

Nüüd sul on täielik CI/CD pipeline: Code push → Build → Deploy! Järgmises harjutuses lisame **automated testing** - testid peavad läbima enne deployment'i.

**Jätka:** [Harjutus 4: Automated Testing](04-automated-testing.md)

---

## 📚 Viited

### Kubernetes:
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)

### GitHub Actions:
- [azure/setup-kubectl](https://github.com/Azure/setup-kubectl)
- [Workflow triggers](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_run)

---

**Õnnitleme! Sul on nüüd automated Kubernetes deployment! 🚀**
