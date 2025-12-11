#!/bin/bash
# Genereeri self-signed SSL certificate (TESTING ONLY!)
# Production: Use Let's Encrypt (certbot)

echo "Generating self-signed SSL certificate..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout key.pem \
  -out cert.pem \
  -subj "/C=EE/ST=Harjumaa/L=Tallinn/O=DevOps Training/OU=IT/CN=localhost"

echo "✅ SSL certificate generated:"
echo "  - cert.pem (certificate)"
echo "  - key.pem (private key)"
echo ""
echo "⚠️  WARNING: This is a self-signed certificate!"
echo "   For production, use Let's Encrypt: https://letsencrypt.org/"
