# V Rising Server on Oracle Cloud (ARM64)

This project allows you to run a V Rising Dedicated Server on Oracle Cloud's Always Free Ampere (ARM64) instances using Docker, Box64, and Wine.

## Prerequisites
1. **Oracle Cloud Ampere Instance** (Ubuntu 22.04 or Debian recommended).
2. **Docker & Docker Compose** installed on the instance.

## Installation

1. **Clone/Copy Files**:
   Ensure you have the following files in a folder (e.g., `~/vrising-docker`):
   - `Dockerfile`
   - `docker-compose.yml`
   - `start.sh`

2. **Build the Image**:
   ```bash
   docker-compose build
   ```
   *Note: This might take a few minutes as it downloads Wine and installs Box64.*

3. **Configure**:
   Edit `docker-compose.yml` to set your desired `SERVER_NAME` and `SAVE_NAME`.

4. **Run**:
   ```bash
   docker-compose up -d
   ```

5. **Monitor**:
   Check logs to see steamcmd downloading the game (first run takes time):
   ```bash
   docker-compose logs -f
   ```

## Oracle Cloud Firewall
You must open ports in the Oracle Cloud Security List:
- **Ingress Rule**: Protocol UDP, Destination Port Range `9876-9877`, Source `0.0.0.0/0`.
- **System Firewall**:
  ```bash
  sudo iptables -I INPUT -p udp --dport 9876 -j ACCEPT
  sudo iptables -I INPUT -p udp --dport 9877 -j ACCEPT
  sudo netfilter-persistent save
  ```

## Troubleshooting
- **Server not appearing**: Ensure firewall rules are active on both the instance (iptables/ufw) AND the Oracle Cloud VCN Security List.
- **Performance**: While Ampere CPUs are strong, emulation adds overhead. If lag occurs, try reducing view distance in server settings.
