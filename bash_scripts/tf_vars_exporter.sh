#!/bin/bash

# Script para coletar informações do servidor Hetzner Cloud

echo "========================================="
echo "  COLETA DE INFORMAÇÕES DO SERVIDOR"
echo "========================================="

# 1. Informações básicas do sistema
echo -e "\n=== INFORMAÇÕES BÁSICAS ==="
echo "Hostname: $(hostname)"
echo "Distribution: $(lsb_release -d | cut -f2-)"
echo "Kernel: $(uname -r)"

# 2. CPU e Memória
echo -e "\n=== RECURSOS DO SERVIDOR ==="
CPU_COUNT=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
echo "CPUs: $CPU_COUNT"
echo "CPU Model: $CPU_MODEL"
echo "Memory: $MEM_TOTAL"

# 3. Storage
echo -e "\n=== ARMAZENAMENTO ==="
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
echo -e "\nEspaço em disco:"
df -h /

# 4. Network
echo -e "\n=== REDE ==="
PUBLIC_IP=$(hostname -I | awk '{print $1}')
echo "IP Público: $PUBLIC_IP"
echo "Interfaces de rede:"
ip -o addr show | awk '{print $2, $4}'

# 5. Verificar se é Hetzner Cloud
echo -e "\n=== METADADOS DO CLOUD ==="
if curl -s -f http://169.254.169.254/hetzner/v1/metadata > /dev/null 2>&1; then
    echo "✓ Servidor Hetzner Cloud detectado"
    # Tentar obter metadados
    echo "Tentando obter metadados..."
    curl -s http://169.254.169.254/hetzner/v1/metadata | python3 -m json.tool 2>/dev/null || \
    echo "Metadados disponíveis em formato JSON via API"
else
    echo "✗ Metadados Hetzner não disponíveis ou servidor não é Hetzner Cloud"
fi

# 6. Verificar volumes adicionais
echo -e "\n=== VOLUMES ADICIONAIS ==="
ADDITIONAL_VOLS=$(lsblk | grep -E "sd[b-z]|vd[b-z]" | wc -l)
if [ $ADDITIONAL_VOLS -gt 0 ]; then
    echo "✓ Volumes adicionais encontrados:"
    lsblk | grep -E "sd[b-z]|vd[b-z]"
else
    echo "✗ Nenhum volume adicional encontrado"
fi

# 7. Verificar Docker/CapRover
echo -e "\n=== DOCKER/CAPROVER ==="
if command -v docker &> /dev/null; then
    echo "✓ Docker instalado"
    docker --version
    if docker ps --filter "name=cap" | grep -q .; then
        echo "✓ Containers CapRover encontrados:"
        docker ps --filter "name=cap" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    fi
else
    echo "✗ Docker não instalado"
fi

# 8. Verificar diretórios do CapRover
echo -e "\n=== DIRETÓRIOS DO CAPROVER ==="
CAPTAIN_DIRS=("/captain" "/var/lib/docker/volumes/captain--*" "/root/srv-captain--*")
for dir in "${CAPTAIN_DIRS[@]}"; do
    if ls -d $dir 2>/dev/null; then
        echo "✓ Diretório encontrado: $dir"
    fi
done

# 9. SSH Keys
echo -e "\n=== CHAVES SSH CONFIGURADAS ==="
if [ -f ~/.ssh/authorized_keys ]; then
    echo "Chaves SSH no authorized_keys:"
    cat ~/.ssh/authorized_keys | awk '{print $3 " (" $1 ")"}'
else
    echo "✗ Nenhum authorized_keys encontrado"
fi

echo -e "\n========================================="
echo "Para completar as informações, verifique no painel da Hetzner:"
echo "1. Tipo do servidor (cx21, cx31, etc): Rescale"
echo "2. Network CIDR: Networking → Networks"
echo "3. SSH Key name: Security → SSH Keys"
echo "4. Location: já temos 'hel1'"
echo "========================================="
