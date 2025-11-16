#!/bin/bash

# ==========================================================================
# Todo App Automaatne Testimine
# ==========================================================================

BASE_URL="http://localhost:3000"
TODO_URL="http://localhost:8081"

echo "🧪 Todo App Testimine"
echo "===================="

# Värvid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Health Check
echo -e "\n${YELLOW}1. Health Check...${NC}"
USER_HEALTH=$(curl -s $BASE_URL/health)
TODO_HEALTH=$(curl -s $TODO_URL/health)

if [[ $USER_HEALTH == *"OK"* ]] || [[ $USER_HEALTH == *"UP"* ]]; then
  echo -e "${GREEN}✅ User Service: UP${NC}"
else
  echo -e "${RED}❌ User Service: DOWN${NC}"
  echo "Response: $USER_HEALTH"
  exit 1
fi

if [[ $TODO_HEALTH == *"UP"* ]] || [[ $TODO_HEALTH == *"OK"* ]]; then
  echo -e "${GREEN}✅ Todo Service: UP${NC}"
else
  echo -e "${RED}❌ Todo Service: DOWN${NC}"
  echo "Response: $TODO_HEALTH"
  exit 1
fi

# 2. Register (võib ebaõnnestuda kui kasutaja on juba olemas - see on OK)
echo -e "\n${YELLOW}2. Registreerimine...${NC}"
REGISTER_RESP=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Auto Test","email":"test@example.com","password":"test123"}')

if [[ $REGISTER_RESP == *"successfully"* ]] || [[ $REGISTER_RESP == *"already exists"* ]]; then
  echo -e "${GREEN}✅ Kasutaja olemas${NC}"
else
  echo -e "${RED}❌ Registreerimine ebaõnnestus${NC}"
  echo "$REGISTER_RESP"
fi

# 3. Login
echo -e "\n${YELLOW}3. Login...${NC}"
LOGIN_RESP=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}')

TOKEN=$(echo $LOGIN_RESP | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo -e "${RED}❌ Login ebaõnnestus!${NC}"
  echo "$LOGIN_RESP"
  exit 1
else
  echo -e "${GREEN}✅ Token saadud: ${TOKEN:0:50}...${NC}"
fi

# 4. Create TODO
echo -e "\n${YELLOW}4. TODO loomine...${NC}"
CREATE_RESP=$(curl -s -X POST $TODO_URL/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Auto test TODO","description":"Created by test script","priority":"high"}')

TODO_ID=$(echo $CREATE_RESP | grep -o '"id":[0-9]*' | cut -d':' -f2)

if [ ! -z "$TODO_ID" ]; then
  echo -e "${GREEN}✅ TODO loodud (ID: $TODO_ID)${NC}"
else
  echo -e "${RED}❌ TODO loomine ebaõnnestus${NC}"
  echo "$CREATE_RESP"
  exit 1
fi

# 5. Get TODOs
echo -e "\n${YELLOW}5. TODOde lugemine...${NC}"
GET_RESP=$(curl -s $TODO_URL/api/todos \
  -H "Authorization: Bearer $TOKEN")

TOTAL=$(echo $GET_RESP | grep -o '"totalElements":[0-9]*' | cut -d':' -f2)

if [ ! -z "$TOTAL" ]; then
  echo -e "${GREEN}✅ Leitud $TOTAL TODO'd${NC}"
else
  echo -e "${RED}❌ TODOde lugemine ebaõnnestus${NC}"
  exit 1
fi

# 6. Complete TODO
echo -e "\n${YELLOW}6. TODO märkimine tehtuks...${NC}"
COMPLETE_RESP=$(curl -s -X PATCH $TODO_URL/api/todos/$TODO_ID/complete \
  -H "Authorization: Bearer $TOKEN")

COMPLETED=$(echo $COMPLETE_RESP | grep -o '"completed":true')

if [ ! -z "$COMPLETED" ]; then
  echo -e "${GREEN}✅ TODO märgitud tehtuks${NC}"
else
  echo -e "${RED}❌ TODO märkimine ebaõnnestus${NC}"
  exit 1
fi

# 7. Stats
echo -e "\n${YELLOW}7. Statistika...${NC}"
STATS_RESP=$(curl -s $TODO_URL/api/todos/stats \
  -H "Authorization: Bearer $TOKEN")

# Try both field names (total/totalTodos, completed/completedTodos)
TOTAL_TODOS=$(echo $STATS_RESP | grep -o '"total":[0-9]*' | head -1 | cut -d':' -f2)
if [ -z "$TOTAL_TODOS" ]; then
  TOTAL_TODOS=$(echo $STATS_RESP | grep -o '"totalTodos":[0-9]*' | cut -d':' -f2)
fi

COMPLETED_TODOS=$(echo $STATS_RESP | grep -o '"completed":[0-9]*' | head -1 | cut -d':' -f2)
if [ -z "$COMPLETED_TODOS" ]; then
  COMPLETED_TODOS=$(echo $STATS_RESP | grep -o '"completedTodos":[0-9]*' | cut -d':' -f2)
fi

if [ ! -z "$TOTAL_TODOS" ]; then
  echo -e "${GREEN}✅ Statistika:${NC}"
  echo "   Kokku: $TOTAL_TODOS"
  echo "   Tehtud: $COMPLETED_TODOS"
else
  echo -e "${RED}❌ Statistika lugemine ebaõnnestus${NC}"
  echo "Response: $STATS_RESP"
  exit 1
fi

# 8. Delete TODO
echo -e "\n${YELLOW}8. TODO kustutamine...${NC}"
DELETE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE $TODO_URL/api/todos/$TODO_ID \
  -H "Authorization: Bearer $TOKEN")

if [ "$DELETE_CODE" == "204" ]; then
  echo -e "${GREEN}✅ TODO kustutatud${NC}"
else
  echo -e "${RED}❌ TODO kustutamine ebaõnnestus (HTTP $DELETE_CODE)${NC}"
fi

# Kokkuvõte
echo -e "\n${GREEN}===================="
echo "✅ Kõik testid läbitud!"
echo "====================${NC}"
