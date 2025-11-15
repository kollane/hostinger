#!/bin/bash

# KLIENDIFRONT testimise skript
# Demonstreerib kasutaja autentimist ja märkmete haldamist

API_URL="http://localhost:3000/api"

echo "=========================================="
echo "KLIENDIFRONT Testimine"
echo "=========================================="
echo ""

# 1. Registreeru uus kasutaja
echo "1️⃣  Registreerime uue kasutaja..."
REGISTER_RESPONSE=$(curl -s -X POST $API_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "test123"
  }')

echo "Vastus: $REGISTER_RESPONSE"
echo ""

# 2. Logi sisse
echo "2️⃣  Logime sisse ja saame JWT tokeni..."
LOGIN_RESPONSE=$(curl -s -X POST $API_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123"
  }')

echo "Vastus: $LOGIN_RESPONSE"
echo ""

# Ekstrakti token
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Viga: Tokeni saamine ebaõnnestus!"
  echo "Võimalik, et kasutaja on juba olemas. Proovi sisselogimist uuesti."
  exit 1
fi

echo "✅ Token saadud: ${TOKEN:0:50}..."
echo ""

# 3. Loo märge
echo "3️⃣  Loome uue märkme (kasutades JWT tokenit)..."
CREATE_NOTE=$(curl -s -X POST $API_URL/notes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Esimene test märge",
    "content": "See on test märge, loodud KLIENDIFRONT autentimisega"
  }')

echo "Vastus: $CREATE_NOTE"
echo ""

# 4. Hangi kõik märkmed
echo "4️⃣  Hangime kõik kasutaja märkmed..."
GET_NOTES=$(curl -s -X GET $API_URL/notes \
  -H "Authorization: Bearer $TOKEN")

echo "Vastus: $GET_NOTES"
echo ""

# 5. Proovi ilma tokenita (peaks ebaõnnestuma)
echo "5️⃣  Proovime pärida märkmeid ILMA tokenita (peaks ebaõnnestuma)..."
UNAUTHORIZED=$(curl -s -X GET $API_URL/notes)

echo "Vastus: $UNAUTHORIZED"
echo ""

echo "=========================================="
echo "KLIENDIFRONT testimine lõpetatud!"
echo "=========================================="
