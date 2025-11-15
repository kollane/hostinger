#!/bin/bash

# MACHINEFRONT testimise skript
# Demonstreerib masinatevahelist autentimist (Machine-to-Machine)

API_URL="http://localhost:3000/api"
API_KEY="your-api-key-here"  # Muuda see vastavalt .env failis olevale API_KEY väärtusele

echo "=========================================="
echo "MACHINEFRONT Testimine"
echo "=========================================="
echo ""

echo "⚙️  API võti: ${API_KEY:0:20}..."
echo ""

# 1. Hangi kõik märkmed (admin juurdepääs)
echo "1️⃣  Hangime KÕIK märkmed (admin juurdepääs)..."
ADMIN_NOTES=$(curl -s -X GET $API_URL/admin/notes \
  -H "X-API-Key: $API_KEY")

echo "Vastus: $ADMIN_NOTES"
echo ""

# 2. Hangi statistika
echo "2️⃣  Hangime statistika (kasutajad ja märkmed)..."
STATS=$(curl -s -X GET $API_URL/admin/stats \
  -H "X-API-Key: $API_KEY")

echo "Vastus: $STATS"
echo ""

# 3. Proovi vale API võtmega (peaks ebaõnnestuma)
echo "3️⃣  Proovime VALE API võtmega (peaks ebaõnnestuma)..."
WRONG_KEY=$(curl -s -X GET $API_URL/admin/stats \
  -H "X-API-Key: wrong-key-123")

echo "Vastus: $WRONG_KEY"
echo ""

# 4. Proovi ilma API võtmeta (peaks ebaõnnestuma)
echo "4️⃣  Proovime ILMA API võtmeta (peaks ebaõnnestuma)..."
NO_KEY=$(curl -s -X GET $API_URL/admin/stats)

echo "Vastus: $NO_KEY"
echo ""

echo "=========================================="
echo "MACHINEFRONT testimine lõpetatud!"
echo "=========================================="
echo ""
echo "💡 Näpunäide: Muuda API_KEY muutujat selles skriptis,"
echo "   et see vastaks sinu .env failis olevale API_KEY väärtusele"
