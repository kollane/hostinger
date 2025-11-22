# User Service Helm Chart

Production-ready Helm chart for User Service microservice.

## Features

- ✅ Deployment with rolling updates
- ✅ Service (ClusterIP)
- ✅ Ingress (nginx)
- ✅ HorizontalPodAutoscaler (HPA)
- ✅ Secrets management
- ✅ Health probes (liveness & readiness)
- ✅ Resource requests & limits
- ✅ Customizable via values.yaml

## Installation

### Basic Install

```bash
helm install user-service .
```

### Custom Values

```bash
# Development
helm install user-service . -f values-dev.yaml

# Production
helm install user-service . -f values-prod.yaml
```

### Override Specific Values

```bash
helm install user-service . \
  --set replicaCount=5 \
  --set image.tag=1.1 \
  --set ingress.host=api.kirjakast.cloud
```

## Configuration

See `values.yaml` for full configuration options.

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Docker image repository | `user-service` |
| `image.tag` | Docker image tag | `1.0` |
| `service.port` | Service port | `3000` |
| `ingress.enabled` | Enable Ingress | `true` |
| `ingress.host` | Ingress hostname | `kirjakast.cloud` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Min pods | `2` |
| `autoscaling.maxReplicas` | Max pods | `10` |

## Upgrade

```bash
# Upgrade release
helm upgrade user-service .

# View history
helm history user-service
```

## Rollback

```bash
# Rollback to previous version
helm rollback user-service

# Rollback to specific revision
helm rollback user-service 2
```

## Uninstall

```bash
helm uninstall user-service
```

## Development

### Lint Chart

```bash
helm lint .
```

### Dry Run

```bash
helm install user-service . --dry-run --debug
```

### Package Chart

```bash
helm package .
# Creates: user-service-1.0.0.tgz
```

## Multi-Environment Setup

Create environment-specific value files:

**values-dev.yaml:**
```yaml
replicaCount: 1
image:
  tag: "dev"
ingress:
  host: dev.kirjakast.cloud
autoscaling:
  enabled: false
```

**values-prod.yaml:**
```yaml
replicaCount: 3
image:
  tag: "1.0"
ingress:
  host: api.kirjakast.cloud
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
```

Then deploy:
```bash
helm install user-service-dev . -f values-dev.yaml
helm install user-service-prod . -f values-prod.yaml --namespace production
```

## Troubleshooting

### View Generated Manifests

```bash
helm get manifest user-service
```

### View Values

```bash
helm get values user-service
```

### Debug Template Rendering

```bash
helm template user-service . --debug
```

## License

MIT
