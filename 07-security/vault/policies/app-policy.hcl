# Application Access Policy for Vault
# This policy allows applications to read their secrets

path "secret/data/database/*" {
  capabilities = ["read", "list"]
}

path "secret/data/api-keys/*" {
  capabilities = ["read", "list"]
}

path "secret/data/jwt/*" {
  capabilities = ["read"]
}

path "secret/data/redis/*" {
  capabilities = ["read"]
}

path "secret/data/smtp/*" {
  capabilities = ["read"]
}

path "secret/data/twilio/*" {
  capabilities = ["read"]
}

# Allow applications to renew their tokens
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow applications to look up their own token
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow applications to revoke their own token
path "auth/token/revoke-self" {
  capabilities = ["update"]
}

# Deny all other paths
path "*" {
  capabilities = ["deny"]
}
