#!/bin/bash
# ======================================================
# Security Audit Script
# Audits network security configuration
# ======================================================

PROJECT_DIR="$HOME/labs/02-docker-compose-lab/compose-project"
cd "$PROJECT_DIR"

echo "========================================"
echo "  Network Security Audit"
echo "========================================"
echo ""

ISSUES=0

echo "=== 1. Public Port Exposure Check ==="
echo "Public ports (should be ONLY :8080):"
public_ports=$(sudo lsof -i -P -n 2>/dev/null | grep LISTEN | grep docker-proxy | grep "\*:" || echo "")

if [ -z "$public_ports" ]; then
    echo "❌ CRITICAL: No public ports found!"
    ((ISSUES++))
else
    echo "$public_ports"
    count=$(echo "$public_ports" | wc -l)
    if [ "$count" -eq 1 ]; then
        if echo "$public_ports" | grep -q ":8080"; then
            echo "✅ PASS: Only port 8080 is public"
        else
            echo "❌ FAIL: Wrong port is public (not 8080)"
            ((ISSUES++))
        fi
    else
        echo "❌ FAIL: $count public ports found (should be 1)"
        ((ISSUES++))
    fi
fi

echo ""
echo "=== 2. Localhost-only Port Binding ==="
echo "Checking backend/database ports (should be 127.0.0.1 only):"
localhost_ports=$(sudo lsof -i -P -n 2>/dev/null | grep LISTEN | grep docker-proxy | grep "127.0.0.1:" || echo "")

if [ -n "$localhost_ports" ]; then
    echo "$localhost_ports"
    echo "✅ PASS: Backend/DB ports are localhost-only"
else
    echo "⚠️  WARNING: No localhost-only ports found"
fi

echo ""
echo "=== 3. Port Scan (nmap) ==="
echo "Scanning localhost for open ports..."
if which nmap >/dev/null 2>&1; then
    nmap_result=$(sudo nmap -sT localhost -p 8080,3000,8081,5432,5433 2>/dev/null | grep "open\|filtered\|closed")
    echo "$nmap_result"

    open_count=$(echo "$nmap_result" | grep -c "open" || echo "0")
    if [ "$open_count" -eq 1 ]; then
        echo "✅ PASS: Only 1 port is open"
    else
        echo "❌ FAIL: $open_count ports are open (should be 1)"
        ((ISSUES++))
    fi
else
    echo "⚠️  nmap not installed, skipping port scan"
fi

echo ""
echo "=== 4. Container Privileges Check ==="
for container in frontend user-service todo-service postgres-user postgres-todo; do
    priv=$(docker inspect $container 2>/dev/null | jq -r '.[0].HostConfig.Privileged')
    if [ "$priv" == "false" ]; then
        echo "✅ $container: Not privileged"
    else
        echo "❌ $container: Privileged mode enabled!"
        ((ISSUES++))
    fi
done

echo ""
echo "=== 5. Network Isolation Check ==="
internal=$(docker network inspect database-network | jq -r '.[0].Internal')
if [ "$internal" == "true" ]; then
    echo "✅ database-network is internal: true"
else
    echo "❌ database-network is NOT internal!"
    ((ISSUES++))
fi

echo ""
echo "=== 6. Docker Image Vulnerability Scan ==="
if docker scout version >/dev/null 2>&1; then
    echo "Scanning user-service:1.0-optimized..."
    docker scout quickview user-service:1.0-optimized 2>&1 | grep -E "vulnerabilities|critical|high" || echo "Scan completed"
else
    echo "⚠️  Docker Scout not available, skipping vulnerability scan"
    echo "    Install: https://docs.docker.com/scout/"
fi

echo ""
echo "========================================"
echo "  Security Audit Summary"
echo "========================================"
echo "Issues found: $ISSUES"
echo ""

if [ $ISSUES -eq 0 ]; then
    echo "✅ Network security audit PASSED!"
    echo "   All security checks passed successfully."
    exit 0
else
    echo "❌ Network security audit FAILED!"
    echo "   $ISSUES issue(s) need attention."
    echo ""
    echo "Recommendations:"
    echo "  - Ensure only port 8080 is publicly exposed"
    echo "  - Use 127.0.0.1 binding for backend/DB ports"
    echo "  - Set database-network internal: true"
    echo "  - Run containers without privileged mode"
    exit 1
fi
