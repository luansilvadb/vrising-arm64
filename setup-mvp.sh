#!/bin/bash
# setup-mvp.sh - Prepara o host e inicia o deploy do VRising FEX MVP
# Executar como root ou com sudo

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root (sudo ./setup-mvp.sh)"
  exit 1
fi

echo ">>> Step 0: Aplicando Kernel Tuning..."
# Step 0: Kernel tuning
echo "Configuring sysctl..."
tee -a /etc/sysctl.conf <<EOF
# FEX-Emu JIT memory maps
vm.max_map_count=1048576
# Network performance for VRising
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.udp_mem=102400 873800 16777216
# No swap pressure
vm.swappiness=0
# Overcommit for Wine
vm.overcommit_memory=1
EOF

sysctl -p
echo "Kernel tuning aplicado. Nota: Reboot é recomendado para vm.max_map_count ter efeito total em alguns sistemas."

echo ">>> Step 4: Otimizações de Host e Docker..."
# Step 4: Performance optimizations
echo "Setting CPU governor to performance..."
if [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
    echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor || echo "Falha ao definir governor (pode não estar disponível)"
else
    echo "CPU freq scaling não detectado, pulando governor."
fi

# IRQ affinity (simple attempt)
echo "Setting IRQ affinity..."
echo 1 > /proc/irq/default_smp_affinity || echo "Falha ao definir IRQ affinity (pode não ser permitido)"

# Docker runtime tuning
echo "Configuring Docker daemon..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {"max-size": "100m"},
  "storage-driver": "overlay2",
  "default-ulimits": {
    "memlock": {"Hard": -1, "Soft": -1},
    "nofile": {"Hard": 65535, "Soft": 65535}
  }
}
EOF
systemctl restart docker || echo "Falha ao reiniciar Docker. Verifique se está instalado."

# Transparent Huge Pages
echo "Enabling Transparent Huge Pages..."
echo always | tee /sys/kernel/mm/transparent_hugepage/enabled

echo ">>> Step 3: Preparando Volumes e Diretórios..."
# Step 3: Directories and Volumes
# Supondo que block storage esteja em /mnt/block, se não, cria diretórios locais
BASE_DIR="/mnt/block"
if [ ! -d "$BASE_DIR" ]; then
    echo "AVISO: /mnt/block não existe. Criando diretórios em /var/lib/vrising-data ao invés disso."
    BASE_DIR="/var/lib/vrising-data"
fi

mkdir -p $BASE_DIR/{vrising,steam,fex-jit,logs}
chown -R 10000:10000 $BASE_DIR/*

echo "Criando Docker Volumes..."
# Remove volumes if they exist to recreate with correct path
docker volume rm vrising_saves steam_cache fex_jit_cache 2>/dev/null || true

docker volume create --opt type=none --opt device=$BASE_DIR/vrising --opt o=bind vrising_saves
docker volume create --opt type=none --opt device=$BASE_DIR/steam --opt o=bind steam_cache
docker volume create --opt type=none --opt device=$BASE_DIR/fex-jit --opt o=bind fex_jit_cache

echo ">>> Setup Concluído!"
echo "Próximos passos:"
echo "1. Se ainda não reiniciou após alterar vm.max_map_count, REINICIE AGORA: 'sudo reboot'"
echo "2. Construa a imagem Docker:"
echo "   docker build -f Dockerfile.vrising-fex-mvp -t vrising-fex-mvp:latest ."
echo "3. Inicie o servidor:"
echo "   docker-compose up -d"
echo "4. Acompanhe os logs:"
echo "   docker logs -f vrising-server"

