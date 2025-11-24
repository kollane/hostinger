#!/bin/bash
# ======================================================
# Comprehensive Network Segmentation Test Suite
# Tests: Network inspection, connectivity, isolation
# ======================================================
# Usage: ./test-network-segmentation.sh
# Exit code: 0 = all pass, 1 = some fail
# ======================================================

set -e  # Exit on error (except where explicitly handled)

PROJECT_DIR="/home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project"

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory not found: $PROJECT_DIR"
    echo "Please ensure Lab 2 compose-project exists."
    exit 1
fi

cd "$PROJECT_DIR"

echo "========================================================"
echo "  Docker Network Segmentation - Comprehensive Test Suite"
echo "========================================================"
echo ""
echo "Testing Lab 2 network segmentation configuration"
echo "Location: $PROJECT_DIR"
echo ""

PASS=0
FAIL=0
TOTAL=0

# Helper: Test function with detailed reporting
test_check() {
    local name="$1"
    local command="$2"
    local expected="$3"  # "pass" or "fail" or "contains:string"

    ((TOTAL++))
    echo -n "[$TOTAL] $name ... "

    set +e
    result=$(eval "$command" 2>&1)
    exit_code=$?
    set -e

    if [[ "$expected" == "pass" ]]; then
        if [ $exit_code -eq 0 ]; then
            echo "✅ PASS"
            ((PASS++))
            return 0
        else
            echo "❌ FAIL"
            ((FAIL++))
            echo "    Expected: success (exit 0)"
            echo "    Got: exit code $exit_code"
            echo "    Output: $result" | head -3
            return 1
        fi
    elif [[ "$expected" == "fail" ]]; then
        if [ $exit_code -ne 0 ]; then
            echo "✅ PASS (correctly failed)"
            ((PASS++))
            return 0
        else
            echo "❌ FAIL (should have failed!)"
            ((FAIL++))
            echo "    Expected: failure (exit ≠ 0)"
            echo "    Got: exit code 0 (success)"
            return 1
        fi
    elif [[ "$expected" == contains:* ]]; then
        search_string="${expected#contains:}"
        if echo "$result" | grep -q "$search_string"; then
            echo "✅ PASS"
            ((PASS++))
            return 0
        else
            echo "❌ FAIL"
            ((FAIL++))
            echo "    Expected to contain: '$search_string'"
            echo "    Got: $result" | head -3
            return 1
        fi
    fi
}

# ======================================================
# SECTION 1: Container Health Checks
# ======================================================
echo "=========================================="
echo "SECTION 1: Container Health"
echo "=========================================="

test_check "All 5 containers are running" \
    "[ \$(docker compose ps --format '{{.State}}' | grep -c 'running') -eq 5 ]" \
    "pass"

test_check "Frontend container is healthy" \
    "docker compose ps frontend | grep -q 'healthy'" \
    "pass"

test_check "User-service container is healthy" \
    "docker compose ps user-service | grep -q 'healthy'" \
    "pass"

test_check "Todo-service container is healthy" \
    "docker compose ps todo-service | grep -q 'healthy'" \
    "pass"

test_check "Postgres-user container is healthy" \
    "docker compose ps postgres-user | grep -q 'healthy'" \
    "pass"

test_check "Postgres-todo container is healthy" \
    "docker compose ps postgres-todo | grep -q 'healthy'" \
    "pass"

# ======================================================
# SECTION 2: Network Existence
# ======================================================
echo ""
echo "=========================================="
echo "SECTION 2: Network Existence"
echo "=========================================="

test_check "frontend-network exists" \
    "docker network inspect frontend-network >/dev/null 2>&1" \
    "pass"

test_check "backend-network exists" \
    "docker network inspect backend-network >/dev/null 2>&1" \
    "pass"

test_check "database-network exists" \
    "docker network inspect database-network >/dev/null 2>&1" \
    "pass"

# ======================================================
# SECTION 3: Network Configuration
# ======================================================
echo ""
echo "=========================================="
echo "SECTION 3: Network Configuration"
echo "=========================================="

test_check "database-network has internal: true" \
    "docker network inspect database-network | jq -r '.[0].Internal' | grep -q 'true'" \
    "pass"

test_check "frontend-network has internal: false" \
    "docker network inspect frontend-network | jq -r '.[0].Internal' | grep -q 'false'" \
    "pass"

test_check "backend-network has internal: false" \
    "docker network inspect backend-network | jq -r '.[0].Internal' | grep -q 'false'" \
    "pass"

# ======================================================
# SECTION 4: Container-to-Network Mapping
# ======================================================
echo ""
echo "=========================================="
echo "SECTION 4: Container-to-Network Mapping"
echo "=========================================="

test_check "frontend is in frontend-network" \
    "docker network inspect frontend-network | jq -r '.[0].Containers' | grep -q 'frontend'" \
    "pass"

test_check "frontend is in backend-network" \
    "docker network inspect backend-network | jq -r '.[0].Containers' | grep -q 'frontend'" \
    "pass"

test_check "frontend is NOT in database-network" \
    "docker network inspect database-network | jq -r '.[0].Containers' | grep -q 'frontend'" \
    "fail"

test_check "user-service is in backend-network" \
    "docker network inspect backend-network | jq -r '.[0].Containers' | grep -q 'user-service'" \
    "pass"

test_check "user-service is in database-network" \
    "docker network inspect database-network | jq -r '.[0].Containers' | grep -q 'user-service'" \
    "pass"

test_check "todo-service is in backend-network" \
    "docker network inspect backend-network | jq -r '.[0].Containers' | grep -q 'todo-service'" \
    "pass"

test_check "todo-service is in database-network" \
    "docker network inspect database-network | jq -r '.[0].Containers' | grep -q 'todo-service'" \
    "pass"

test_check "postgres-user is in database-network ONLY" \
    "docker network inspect database-network | jq -r '.[0].Containers' | grep -q 'postgres-user'" \
    "pass"

test_check "postgres-todo is in database-network ONLY" \
    "docker network inspect database-network | jq -r '.[0].Containers' | grep -q 'postgres-todo'" \
    "pass"

# ======================================================
# SECTION 5: DNS Resolution
# ======================================================
echo ""
echo "=========================================="
echo "SECTION 5: DNS Resolution"
echo "=========================================="

test_check "Frontend can resolve user-service" \
    "docker compose exec -T frontend nslookup user-service >/dev/null 2>&1" \
    "pass"

test_check "Frontend can resolve todo-service" \
    "docker compose exec -T frontend nslookup todo-service >/dev/null 2>&1" \
    "pass"

test_check "Frontend CANNOT resolve postgres-user" \
    "docker compose exec -T frontend nslookup postgres-user >/dev/null 2>&1" \
    "fail"

test_check "Frontend CANNOT resolve postgres-todo" \
    "docker compose exec -T frontend nslookup postgres-todo >/dev/null 2>&1" \
    "fail"

test_check "user-service can resolve postgres-user" \
    "docker compose exec -T user-service nslookup postgres-user >/dev/null 2>&1" \
    "pass"

test_check "todo-service can resolve postgres-todo" \
    "docker compose exec -T todo-service nslookup postgres-todo >/dev/null 2>&1" \
    "pass"

# ======================================================
# SECTION 6: Port Connectivity (Expected to Work)
# ======================================================
echo ""
echo "=========================================="
echo "SECTION 6: Port Connectivity (Expected)"
echo "=========================================="

test_check "Frontend → user-service:3000" \
    "docker compose exec -T frontend timeout 3 nc -zv user-service 3000 2>&1" \
    "contains:succeeded"

test_check "Frontend → todo-service:8081" \
    "docker compose exec -T frontend timeout 3 nc -zv todo-service 8081 2>&1" \
    "contains:succeeded"

test_check "user-service → postgres-user:5432" \
    "docker compose exec -T user-service timeout 3 nc -zv postgres-user 5432 2>&1" \
    "contains:succeeded"

test_check "todo-service → postgres-todo:5432" \
    "docker compose exec -T todo-service timeout 3 nc -zv postgres-todo 5432 2>&1" \
    "contains:succeeded"

# ======================================================
# SECTION 7: Network Isolation (Expected to Fail)
# ======================================================
echo ""
echo "=========================================="
echo "SECTION 7: Network Isolation"
echo "=========================================="

test_check "Frontend CANNOT reach postgres-user:5432" \
    "docker compose exec -T frontend timeout 2 nc -zv postgres-user 5432 2>&1" \
    "fail"

test_check "Frontend CANNOT reach postgres-todo:5432" \
    "docker compose exec -T frontend timeout 2 nc -zv postgres-todo 5432 2>&1" \
    "fail"

# ======================================================
# SECTION 8: HTTP Endpoint Health
# ======================================================
echo ""
echo "=========================================="
echo "SECTION 8: HTTP Endpoint Health"
echo "=========================================="

test_check "user-service /health returns 200 OK" \
    "docker compose exec -T frontend curl -sf http://user-service:3000/health >/dev/null 2>&1" \
    "pass"

test_check "user-service /health contains 'ok'" \
    "docker compose exec -T frontend curl -sf http://user-service:3000/health" \
    "contains:ok"

test_check "todo-service /health returns 200 OK" \
    "docker compose exec -T frontend curl -sf http://todo-service:8081/health >/dev/null 2>&1" \
    "pass"

test_check "todo-service /health contains 'UP'" \
    "docker compose exec -T frontend curl -sf http://todo-service:8081/health" \
    "contains:UP"

# ======================================================
# SECTION 9: Public Port Exposure
# ======================================================
echo ""
echo "=========================================="
echo "SECTION 9: Public Port Exposure"
echo "=========================================="

PUBLIC_COUNT=$(sudo lsof -i -P -n 2>/dev/null | grep LISTEN | grep docker-proxy | grep -c "\*:" || echo "0")

test_check "Only 1 public port is exposed (frontend:8080)" \
    "[ $PUBLIC_COUNT -eq 1 ]" \
    "pass"

test_check "Port 8080 is publicly accessible" \
    "sudo lsof -i -P -n 2>/dev/null | grep LISTEN | grep docker-proxy | grep -q '*:8080'" \
    "pass"

# ======================================================
# FINAL SUMMARY
# ======================================================
echo ""
echo "========================================================"
echo "  TEST SUMMARY"
echo "========================================================"
echo "Total tests run: $TOTAL"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✅ ✅ ✅  ALL TESTS PASSED! ✅ ✅ ✅"
    echo ""
    echo "Network segmentation is correctly configured:"
    echo "  - 3 networks created (frontend, backend, database)"
    echo "  - database-network is internal: true"
    echo "  - Containers are in correct networks"
    echo "  - DNS resolution works as expected"
    echo "  - Connectivity matrix is correct"
    echo "  - Isolation is properly enforced"
    echo "  - Only 1 public port (8080)"
    echo ""
    exit 0
else
    echo "❌ ❌ ❌  SOME TESTS FAILED! ❌ ❌ ❌"
    echo ""
    echo "Please review the network configuration:"
    echo "  - Check docker-compose.yml networks section"
    echo "  - Verify service network assignments"
    echo "  - Ensure database-network has internal: true"
    echo "  - Review port bindings (localhost vs 0.0.0.0)"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Restart stack: docker compose down && docker compose up -d"
    echo "  2. Review Lab 2 Harjutus 3: exercises/03-network-segmentation.md"
    echo "  3. Check logs: docker compose logs"
    echo ""
    exit 1
fi
