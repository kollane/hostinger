#!/bin/bash
# ======================================================
# Isolation Verification Script
# Verifies network isolation is correctly enforced
# ======================================================

PROJECT_DIR="/home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project"
cd "$PROJECT_DIR"

echo "========================================"
echo "  Network Isolation Verification"
echo "========================================"
echo ""

PASS=0
FAIL=0

test_isolation() {
    local from=$1
    local to=$2
    local port=$3
    local reason=$4

    echo -n "Testing $from → $to:$port (should FAIL) ... "

    set +e
    result=$(docker compose exec -T $from timeout 2 nc -zv $to $port 2>&1)
    exit_code=$?
    set -e

    if [ $exit_code -ne 0 ]; then
        echo "✅ PASS (isolated)"
        ((PASS++))
    else
        echo "❌ FAIL (NOT isolated!)"
        echo "  Reason: $reason"
        ((FAIL++))
    fi
}

echo "Frontend Isolation Tests:"
test_isolation "frontend" "postgres-user" "5432" "Frontend not in database-network"
test_isolation "frontend" "postgres-todo" "5432" "Frontend not in database-network"

echo ""
echo "Database Network Internal Flag:"
internal=$(docker network inspect database-network | jq -r '.[0].Internal')
if [ "$internal" == "true" ]; then
    echo "✅ database-network is internal: true"
    ((PASS++))
else
    echo "❌ database-network is NOT internal!"
    ((FAIL++))
fi

echo ""
echo "========================================"
echo "Summary: $PASS passed, $FAIL failed"
echo "========================================"

if [ $FAIL -eq 0 ]; then
    echo "✅ Network isolation is correctly enforced!"
    exit 0
else
    echo "❌ Network isolation has issues!"
    exit 1
fi
