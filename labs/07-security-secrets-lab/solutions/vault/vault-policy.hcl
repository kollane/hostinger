# Vault Policy for user-service
# Reference solution for Exercise 1
#
# This policy grants read access to database secrets
# Follows principle of least privilege

# =============================================================================
# Database Secrets
# =============================================================================
# Allow read access to database credentials

path "secret/data/db" {
  capabilities = ["read"]
}

# Allow list secrets (for debugging)
path "secret/metadata/db" {
  capabilities = ["read", "list"]
}

# =============================================================================
# Additional Secrets (Optional)
# =============================================================================
# Uncomment to grant access to additional secrets

# JWT Secret
# path "secret/data/jwt" {
#   capabilities = ["read"]
# }

# API Keys
# path "secret/data/api-keys/*" {
#   capabilities = ["read"]
# }

# TLS Certificates
# path "pki/issue/user-service" {
#   capabilities = ["create", "update"]
# }

# =============================================================================
# System Paths (Read-Only)
# =============================================================================
# Allow reading auth methods (for debugging)

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

# =============================================================================
# NOTES
# =============================================================================
#
# Capabilities:
# - create: Create new data
# - read: Read existing data
# - update: Update existing data
# - delete: Delete data
# - list: List keys
# - sudo: Special admin operations
# - deny: Explicitly deny access
#
# Path format:
# - secret/data/* - KV v2 secrets (data path)
# - secret/metadata/* - KV v2 metadata
# - secret/* - KV v1 secrets
#
# Best Practices:
# 1. Grant minimum necessary permissions
# 2. Use specific paths (avoid wildcards)
# 3. Regularly audit policies
# 4. Rotate secrets regularly
# 5. Use different policies for different apps
#
# Apply this policy:
# vault policy write user-service vault-policy.hcl
#
# Verify policy:
# vault policy read user-service
#
# =============================================================================
