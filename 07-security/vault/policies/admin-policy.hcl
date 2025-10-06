# Admin Policy for Vault
# This policy allows full access for administrators

# Full access to secret paths
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage authentication methods
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage policies
path "sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage audit backends
path "sys/audit/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secret engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Read system health
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# Read system capabilities
path "sys/capabilities" {
  capabilities = ["create", "update"]
}

# Read system seal status
path "sys/seal-status" {
  capabilities = ["read", "sudo"]
}

# Unseal Vault
path "sys/unseal" {
  capabilities = ["create", "update", "sudo"]
}

# Initialize Vault
path "sys/init" {
  capabilities = ["create", "update", "sudo"]
}

# List existing policies
path "sys/policy" {
  capabilities = ["read", "list"]
}

# Manage leases
path "sys/leases/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage tokens
path "auth/token/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# View metrics
path "sys/metrics" {
  capabilities = ["read"]
}
