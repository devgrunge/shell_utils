#!/bin/bash

# Configure seu token
export HCLOUD_TOKEN="sua_chave_api_aqui"

echo "=== Obtendo IDs dos recursos Hetzner ==="
echo ""

# Servers
echo "Servers:"
curl -s "https://api.hetzner.cloud/v1/servers" \
  -H "Authorization: Bearer $HCLOUD_TOKEN" | \
  jq -r '.servers[] | "ID: \(.id) | Name: \(.name) | IP: \(.public_net.ipv4.ip)"'

echo ""

# SSH Keys
echo "SSH Keys:"
curl -s "https://api.hetzner.cloud/v1/ssh_keys" \
  -H "Authorization: Bearer $HCLOUD_TOKEN" | \
  jq -r '.ssh_keys[] | "ID: \(.id) | Name: \(.name) | Fingerprint: \(.fingerprint)"'

echo ""

# Networks
echo "Networks:"
curl -s "https://api.hetzner.cloud/v1/networks" \
  -H "Authorization: Bearer $HCLOUD_TOKEN" | \
  jq -r '.networks[] | "ID: \(.id) | Name: \(.name) | CIDR: \(.ip_range)"'

echo ""

# Firewalls
echo "Firewalls:"
curl -s "https://api.hetzner.cloud/v1/firewalls" \
  -H "Authorization: Bearer $HCLOUD_TOKEN" | \
  jq -r '.firewalls[] | "ID: \(.id) | Name: \(.name)"'

echo ""

# Volumes
echo "Volumes:"
curl -s "https://api.hetzner.cloud/v1/volumes" \
  -H "Authorization: Bearer $HCLOUD_TOKEN" | \
  jq -r '.volumes[] | "ID: \(.id) | Name: \(.name) | Size: \(.size)GB"'
