#!/bin/bash
# =============================================================================
# Trivy Cluster Image Scanner
# Reference solution for Exercise 4
#
# Scans all container images currently running in Kubernetes cluster
# Generates reports for Critical and High severity vulnerabilities
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
NAMESPACES="${NAMESPACES:-production,monitoring}"
SEVERITY="${SEVERITY:-CRITICAL,HIGH}"
OUTPUT_DIR="${OUTPUT_DIR:-./trivy-reports}"
FAIL_ON_CRITICAL="${FAIL_ON_CRITICAL:-true}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Trivy Cluster Image Scanner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# =============================================================================
# Check prerequisites
# =============================================================================
echo -e "${BLUE}1. Checking prerequisites...${NC}"
echo ""

if ! command -v trivy &> /dev/null; then
  echo -e "${RED}✗${NC} Trivy is not installed"
  echo "Install: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
  exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}✗${NC} kubectl is not installed"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}⚠${NC} jq is not installed (optional, for JSON parsing)"
fi

TRIVY_VERSION=$(trivy --version | head -1)
echo -e "${GREEN}✓${NC} Trivy: $TRIVY_VERSION"

KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | head -1 || echo "installed")
echo -e "${GREEN}✓${NC} kubectl: $KUBECTL_VERSION"

echo ""

# =============================================================================
# Update Trivy database
# =============================================================================
echo -e "${BLUE}2. Updating Trivy vulnerability database...${NC}"
echo ""

trivy image --download-db-only --quiet
echo -e "${GREEN}✓${NC} Database updated"

echo ""

# =============================================================================
# Create output directory
# =============================================================================
mkdir -p "$OUTPUT_DIR"
echo -e "${GREEN}✓${NC} Output directory: $OUTPUT_DIR"
echo ""

# =============================================================================
# Collect all images
# =============================================================================
echo -e "${BLUE}3. Collecting images from cluster...${NC}"
echo ""

IMAGES=()
for NAMESPACE in ${NAMESPACES//,/ }; do
  echo "Namespace: $NAMESPACE"

  NS_IMAGES=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].spec.containers[*].image}' 2>/dev/null || echo "")

  if [ -n "$NS_IMAGES" ]; then
    for IMAGE in $NS_IMAGES; do
      if [[ ! " ${IMAGES[@]} " =~ " ${IMAGE} " ]]; then
        IMAGES+=("$IMAGE")
        echo "  - $IMAGE"
      fi
    done
  fi
done

TOTAL_IMAGES=${#IMAGES[@]}
echo ""
echo -e "${GREEN}✓${NC} Found $TOTAL_IMAGES unique images"
echo ""

if [ "$TOTAL_IMAGES" -eq 0 ]; then
  echo -e "${YELLOW}⚠${NC} No images found. Check namespaces: $NAMESPACES"
  exit 0
fi

# =============================================================================
# Scan images
# =============================================================================
echo -e "${BLUE}4. Scanning images...${NC}"
echo ""

CURRENT=0
CRITICAL_TOTAL=0
HIGH_TOTAL=0
MEDIUM_TOTAL=0
LOW_TOTAL=0
FAILED_SCANS=0

for IMAGE in "${IMAGES[@]}"; do
  CURRENT=$((CURRENT + 1))

  echo "[$CURRENT/$TOTAL_IMAGES] Scanning: $IMAGE"

  # Sanitize image name for filename
  SAFE_NAME=$(echo "$IMAGE" | tr '/:' '_')

  # Scan image (JSON output)
  if trivy image \
    --severity "$SEVERITY" \
    --format json \
    --output "$OUTPUT_DIR/${SAFE_NAME}.json" \
    --quiet \
    "$IMAGE" 2>/dev/null; then

    # Parse JSON results (if jq is available)
    if command -v jq &> /dev/null; then
      CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$OUTPUT_DIR/${SAFE_NAME}.json")
      HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$OUTPUT_DIR/${SAFE_NAME}.json")
      MEDIUM=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "$OUTPUT_DIR/${SAFE_NAME}.json")
      LOW=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="LOW")] | length' "$OUTPUT_DIR/${SAFE_NAME}.json")

      CRITICAL_TOTAL=$((CRITICAL_TOTAL + CRITICAL))
      HIGH_TOTAL=$((HIGH_TOTAL + HIGH))
      MEDIUM_TOTAL=$((MEDIUM_TOTAL + MEDIUM))
      LOW_TOTAL=$((LOW_TOTAL + LOW))

      # Color-coded output
      if [ "$CRITICAL" -gt 0 ]; then
        echo -e "  ${RED}CRITICAL: $CRITICAL${NC}, ${YELLOW}HIGH: $HIGH${NC}"
      elif [ "$HIGH" -gt 0 ]; then
        echo -e "  ${YELLOW}HIGH: $HIGH${NC}, MEDIUM: $MEDIUM"
      else
        echo -e "  ${GREEN}✓ No critical/high vulnerabilities${NC}"
      fi
    fi

    # Generate human-readable report
    trivy image \
      --severity "$SEVERITY" \
      --format table \
      --output "$OUTPUT_DIR/${SAFE_NAME}.txt" \
      --quiet \
      "$IMAGE" 2>/dev/null

  else
    echo -e "  ${RED}✗ Scan failed${NC}"
    FAILED_SCANS=$((FAILED_SCANS + 1))
  fi

  echo ""
done

# =============================================================================
# Summary report
# =============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SCAN SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "Images scanned:        $TOTAL_IMAGES"
echo "Failed scans:          $FAILED_SCANS"
echo ""

if command -v jq &> /dev/null; then
  echo "Vulnerabilities found:"
  echo -e "  ${RED}CRITICAL:${NC}          $CRITICAL_TOTAL"
  echo -e "  ${YELLOW}HIGH:${NC}              $HIGH_TOTAL"
  echo "  MEDIUM:            $MEDIUM_TOTAL"
  echo "  LOW:               $LOW_TOTAL"
  echo ""
fi

echo "Reports saved to:      $OUTPUT_DIR"
echo ""

# =============================================================================
# Generate summary HTML report (optional)
# =============================================================================
SUMMARY_FILE="$OUTPUT_DIR/summary.html"

cat > "$SUMMARY_FILE" <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Trivy Scan Summary - $(date '+%Y-%m-%d')</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #4CAF50; color: white; }
    .critical { color: #d32f2f; font-weight: bold; }
    .high { color: #f57c00; font-weight: bold; }
    .success { color: #388e3c; }
  </style>
</head>
<body>
  <h1>Trivy Security Scan Summary</h1>
  <p><strong>Date:</strong> $(date)</p>
  <p><strong>Images Scanned:</strong> $TOTAL_IMAGES</p>

  <h2>Summary</h2>
  <table>
    <tr><th>Severity</th><th>Count</th></tr>
    <tr><td class="critical">CRITICAL</td><td>$CRITICAL_TOTAL</td></tr>
    <tr><td class="high">HIGH</td><td>$HIGH_TOTAL</td></tr>
    <tr><td>MEDIUM</td><td>$MEDIUM_TOTAL</td></tr>
    <tr><td>LOW</td><td>$LOW_TOTAL</td></tr>
  </table>

  <h2>Scanned Images</h2>
  <ul>
EOF

for IMAGE in "${IMAGES[@]}"; do
  echo "    <li>$IMAGE</li>" >> "$SUMMARY_FILE"
done

cat >> "$SUMMARY_FILE" <<EOF
  </ul>

  <p><em>Detailed reports available in JSON and TXT format.</em></p>
</body>
</html>
EOF

echo -e "${GREEN}✓${NC} HTML summary: $SUMMARY_FILE"
echo ""

# =============================================================================
# Exit status
# =============================================================================
if [ "$FAIL_ON_CRITICAL" = "true" ] && [ "$CRITICAL_TOTAL" -gt 0 ]; then
  echo -e "${RED}❌ CRITICAL vulnerabilities found!${NC}"
  echo "Action required: Update images within 24 hours"
  exit 1
elif [ "$HIGH_TOTAL" -gt 10 ]; then
  echo -e "${YELLOW}⚠️  WARNING: High number of HIGH vulnerabilities${NC}"
  exit 0
else
  echo -e "${GREEN}✅ PASS: No critical vulnerabilities found${NC}"
  exit 0
fi

# =============================================================================
# USAGE NOTES
# =============================================================================
#
# Basic usage:
# ./scan-cluster-images.sh
#
# Scan specific namespaces:
# NAMESPACES="production,staging" ./scan-cluster-images.sh
#
# Include all severities:
# SEVERITY="CRITICAL,HIGH,MEDIUM,LOW" ./scan-cluster-images.sh
#
# Custom output directory:
# OUTPUT_DIR="./security-reports" ./scan-cluster-images.sh
#
# Don't fail on critical:
# FAIL_ON_CRITICAL=false ./scan-cluster-images.sh
#
# View reports:
# ls -lh trivy-reports/
# cat trivy-reports/user-service_latest.txt
# open trivy-reports/summary.html
#
# =============================================================================
