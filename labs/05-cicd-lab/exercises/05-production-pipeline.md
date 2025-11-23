# Harjutus 5: Production Pipeline

**Kestus:** 60 minutit
**Eesmärk:** Loo production-ready pipeline approval gates ja notificationitega

---

## 📋 Ülevaade

Selles harjutuses **lood production-ready pipeline'i**, mis:
- Nõuab manual approval production deploy'ks
- Saadab notifications (Slack, email)
- Säilitab deployment history
- Võimaldab kiiret rollback'i
- Toetab canary ja blue-green deployments

**Production Pipeline = Safe, controlled, auditable:**
- Manual approval gates
- Deployment notifications
- Audit trail
- Quick rollback capability

---

## 🎯 Õpieesmärgid

- ✅ Seadistada GitHub Environments (production)
- ✅ Luua manual approval gates
- ✅ Implementeerida deployment notifications
- ✅ Luua rollback workflow
- ✅ Deployment history tracking

---

## 🏗️ Arhitektuur

```
Branch: main
   │
   ▼
CI Pipeline ✓
   │
   ▼
CD Pipeline
   │
   ├─ Environment: production
   │   │
   │   ├─ ⏸️ Wait for approval
   │   │   (Reviewers notified)
   │   │
   │   └─ ✅ Approved
   │       │
   │       ▼
   │   Deploy to production
   │   ├─ Helm upgrade --atomic
   │   ├─ Smoke tests
   │   └─ Slack notification ✓
   │
   └─ If failure:
       ├─ Auto rollback
       └─ Alert notification ❌
```

---

## 📝 Sammud

### Samm 1: Loo GitHub Environment (15 min)

**GitHub repository → Settings → Environments → New environment:**

**Environment name:** `production`

**Deployment protection rules:**
- ✅ Required reviewers: (Lisa enda GitHub username)
- ✅ Wait timer: 0 minutes

**Environment secrets (optional):**
```
SLACK_WEBHOOK_URL: <your slack webhook>
```

**Repeat for staging ja development (no approval needed):**

Environment: `staging`
- Deployment protection: None

Environment: `development`
- Deployment protection: None

### Samm 2: Update CD Workflow - Production Approval (20 min)

**Update `.github/workflows/cd.yml` deploy job:**

```yaml
  deploy:
    name: 🚀 Deploy to ${{ needs.determine-environment.outputs.environment }}
    runs-on: ubuntu-latest
    needs: determine-environment
    timeout-minutes: 30  # Increased for approval wait

    environment:
      name: ${{ needs.determine-environment.outputs.environment }}
      url: https://${{ needs.determine-environment.outputs.environment }}.kirjakast.cloud

    steps:
      # ... existing steps ...

      - name: 📢 Notify deployment start
        if: always()
        run: |
          ENV="${{ needs.determine-environment.outputs.environment }}"
          TAG="${{ needs.determine-environment.outputs.image_tag }}"
          
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "📢 Deployment Started"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Environment: $ENV"
          echo "Image: ${{ env.IMAGE_NAME }}:$TAG"
          echo "Triggered by: ${{ github.actor }}"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      # ... existing helm deploy steps ...

      - name: 📢 Notify success
        if: success()
        run: |
          ENV="${{ needs.determine-environment.outputs.environment }}"
          TAG="${{ needs.determine-environment.outputs.image_tag }}"
          
          # Slack notification (if webhook configured)
          if [ -n "${{ secrets.SLACK_WEBHOOK_URL }}" ]; then
            curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
              -H 'Content-Type: application/json' \
              -d '{
                "text": "✅ Deployment Successful",
                "blocks": [
                  {
                    "type": "section",
                    "text": {
                      "type": "mrkdwn",
                      "text": "*Deployment Successful* :white_check_mark:\n\n*Environment:* '"$ENV"'\n*Image:* `'"$TAG"'`\n*Actor:* '"${{ github.actor }}"'"
                    }
                  }
                ]
              }'
          fi

      - name: 📢 Notify failure
        if: failure()
        run: |
          ENV="${{ needs.determine-environment.outputs.environment }}"
          
          # Slack notification
          if [ -n "${{ secrets.SLACK_WEBHOOK_URL }}" ]; then
            curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
              -H 'Content-Type: application/json' \
              -d '{
                "text": "❌ Deployment Failed",
                "blocks": [
                  {
                    "type": "section",
                    "text": {
                      "type": "mrkdwn",
                      "text": "*Deployment Failed* :x:\n\n*Environment:* '"$ENV"'\n*Actor:* '"${{ github.actor }}"'\n*Workflow:* ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
                    }
                  }
                ]
              }'
          fi
```

### Samm 3: Loo Rollback Workflow (15 min)

**Loo `.github/workflows/rollback.yml`:**

```yaml
name: Rollback Deployment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to rollback'
        required: true
        type: choice
        options:
          - development
          - staging
          - production
      revision:
        description: 'Revision number (0 = previous, or specific revision)'
        required: false
        default: '0'
        type: string

env:
  DEPLOYMENT_NAME: user-service

jobs:
  rollback:
    name: ⏮️ Rollback to Revision
    runs-on: ubuntu-latest
    timeout-minutes: 10

    environment:
      name: ${{ inputs.environment }}

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🔧 Setup kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: 'v1.31.0'

      - name: ⎈ Setup Helm
        uses: azure/setup-helm@v4
        with:
          version: 'v3.16.0'

      - name: 🔐 Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > $HOME/.kube/config
          chmod 600 $HOME/.kube/config

      - name: 📜 Show Helm history
        run: |
          ENV="${{ inputs.environment }}"
          
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "📜 Helm Release History"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          
          helm history ${{ env.DEPLOYMENT_NAME }} --namespace=$ENV

      - name: ⏮️ Perform rollback
        run: |
          ENV="${{ inputs.environment }}"
          REVISION="${{ inputs.revision }}"
          
          if [ "$REVISION" == "0" ]; then
            REVISION_TEXT="previous revision"
          else
            REVISION_TEXT="revision $REVISION"
          fi
          
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "⏮️ Rolling back to $REVISION_TEXT"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          
          helm rollback ${{ env.DEPLOYMENT_NAME }} $REVISION --namespace=$ENV --wait
          
          echo "✅ Rollback completed!"

      - name: ✅ Verify rollback
        run: |
          ENV="${{ inputs.environment }}"
          
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "📊 Post-Rollback Status"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          
          # Show helm status
          helm status ${{ env.DEPLOYMENT_NAME }} --namespace=$ENV
          
          # Show pods
          kubectl get pods -l app=${{ env.DEPLOYMENT_NAME }} --namespace=$ENV
          
          # Current image
          kubectl get deployment ${{ env.DEPLOYMENT_NAME }} --namespace=$ENV \
            -o jsonpath='{.spec.template.spec.containers[0].image}'
          echo ""

      - name: 📢 Notify rollback
        if: always()
        run: |
          ENV="${{ inputs.environment }}"
          STATUS="${{ job.status }}"
          
          if [ -n "${{ secrets.SLACK_WEBHOOK_URL }}" ]; then
            curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
              -H 'Content-Type: application/json' \
              -d '{
                "text": "⏮️ Rollback '"$STATUS"'",
                "blocks": [
                  {
                    "type": "section",
                    "text": {
                      "type": "mrkdwn",
                      "text": "*Rollback '"$STATUS"'* :rewind:\n\n*Environment:* '"$ENV"'\n*Actor:* '"${{ github.actor }}"'"
                    }
                  }
                ]
              }'
          fi
```

### Samm 4: Test Production Deployment (10 min)

**4a. Merge to main:**

```bash
# Ensure you're on main
git checkout main

# Merge develop
git merge develop

# Push
git push
```

**4b. Vaata workflow:**

GitHub → Actions → "Continuous Deployment"

- Näed: "Waiting for approval"
- Approve deployment
- Deploy continues

**4c. Test rollback:**

GitHub → Actions → "Rollback Deployment" → Run workflow
- Environment: production
- Revision: 0 (previous)
- Run workflow

✅ **Kontrolli:** Rollback õnnestub

---

## ✅ Kontrolli Tulemusi

- [ ] GitHub Environments loodud (dev/staging/prod)
- [ ] Production nõuab approval
- [ ] Approval notification saabub
- [ ] Deployment notifications töötavad
- [ ] Rollback workflow loodud
- [ ] Rollback workflow töötab
- [ ] Helm history nähtav

---

## 🎓 Õpitud Mõisted

**GitHub Environments:**
- Environment-specific configs
- Deployment protection rules
- Required reviewers

**Approval Gates:**
- Manual review before deploy
- Production safety
- Audit trail

**Notifications:**
- Slack webhooks
- Deployment alerts
- Status updates

**Helm History:**
- Revision tracking
- Rollback capability
- Deployment audit

---

## 💡 Best Practices

1. **Production approval** - Always require manual review
2. **Notifications** - Alert on success AND failure
3. **Quick rollback** - One-click rollback workflow
4. **Deployment history** - Track all changes
5. **Environment isolation** - Separate namespaces
6. **URL tracking** - Link to deployment in notifications

---

## 🐛 Troubleshooting

### Approval not triggered?

```bash
# Check Environment settings
# Settings → Environments → production → Required reviewers

# Ensure environment name matches workflow
```

### Notifications not working?

```bash
# Check Slack webhook URL
# Settings → Secrets → SLACK_WEBHOOK_URL

# Test webhook manually
curl -X POST $WEBHOOK_URL -H 'Content-Type: application/json' -d '{"text":"Test"}'
```

### Rollback fails?

```bash
# Check Helm history
helm history user-service -n production

# Ensure revision exists
helm rollback user-service <revision> -n production --dry-run
```

---

## 🔗 Järgmine Labor

**Õnnitleme! Lab 5 on valmis!**

Nüüd on sul täielik CI/CD pipeline:
- ✅ Automated testing
- ✅ Docker build & security scan
- ✅ Multi-environment deployment
- ✅ Quality gates
- ✅ Production approvals
- ✅ Quick rollback

**Labor 6: Monitoring & Logging**
- Monitor deployed apps
- Track CI/CD metrics
- Prometheus + Grafana
- Log aggregation

**Jätka:** [Labor 6: Monitoring](../../06-monitoring-logging-lab/README.md)

---

## 📚 Viited

- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Slack Webhooks](https://api.slack.com/messaging/webhooks)
- [Helm History](https://helm.sh/docs/helm/helm_history/)

---

**Õnnitleme! Oled loonud production-ready CI/CD pipeline! 🎉🚀**
