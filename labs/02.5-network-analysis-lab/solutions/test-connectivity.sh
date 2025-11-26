#!/bin/bash
# ======================================================
# Connectivity Testing Script
# Tests connectivity matrix between all services
# ======================================================

PROJECT_DIR="$HOME/labs/02-docker-compose-lab/compose-project"
cd "$PROJECT_DIR"

echo "========================================"
echo "  Connectivity Matrix Test"
echo "========================================"
echo ""

PASS=0
FAIL=0

test_conn() {
    local from=$1
    local to=$2
    local port=$3
    local expected=$4

    echo -n "Testing $from → $to:$port ... "

    result=$(docker compose exec -T $from timeout 2 nc -zv $to $port 2>&1)

    if echo "$result" | grep -q "succeeded\|open"; then
        if [ "$expected" == "pass" ]; then
            echo "✅ PASS"
            ((PASS++))
        else
            echo "❌ FAIL (should be blocked!)"
            ((FAIL++))
        fi
    else
        if [ "$expected" == "fail" ]; then
            echo "✅ PASS (correctly blocked)"
            ((PASS++))
        else
            echo "❌ FAIL (should work!)"
            ((FAIL++))
        fi
    fi
}

echo "Expected Connectivity:"
test_conn "frontend" "user-service" "3000" "pass"
test_conn "frontend" "todo-service" "8081" "pass"
test_conn "user-service" "postgres-user" "5432" "pass"
test_conn "todo-service" "postgres-todo" "5432" "pass"

echo ""
echo "Expected Isolation:"
test_conn "frontend" "postgres-user" "5432" "fail"
test_conn "frontend" "postgres-todo" "5432" "fail"

echo ""
echo "========================================"
echo "Summary: $PASS passed, $FAIL failed"
echo "========================================"

[ $FAIL -eq 0 ] && exit 0 || exit 1
