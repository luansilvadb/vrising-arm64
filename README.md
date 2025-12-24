# V Rising Dedicated Server on ARM64 (Oracle Cloud Ampere)

This project provides a production-ready, highly optimized Docker setup to run V Rising on ARM64 architectures, specifically tailored for Oracle Cloud Always Free Ampere instances.

## Features

- **High Performance**: Compiles `Box64` (for game) and `Box86` (for SteamCMD) from source with Ampere Altra optimizations (`ARM_DYNAREC`).
- **Secure**: Runs as non-root user (UID 10000), read-only root filesystem, reduced capabilities.
- **Robust**: Automated healthchecks, graceful shutdown, and structured logging.
- **Automated**: Auto-updates via SteamCMD on startup (configurable) and auto-generates server configuration.

## Quick Start

1. **Deploy**:
   ```bash
   docker-compose up -d --build
   ```
   *Note: The first build will take 15-30 minutes to compile Box64/86.*

2. **Monitor**:
   ```bash
   docker-compose logs -f
   ```

3. **Connect**:
   - In-game, connect to `YOUR_ORACLE_IP:27015`.

## Configuration

Edit `docker-compose.yml` environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `VR_SERVER_NAME` | Server Name in Server List | V Rising ARM64 |
| `VR_WORLD_NAME` | Name of the save folder | world1 |
| `VR_PASSWORD` | Server Password | *Empty* |
| `NO_UPDATE` | Set to `1` to skip Steam update on boot | *Unset* |

## Oracle Cloud Specifics

- **Firewall**: Ensure you open UDP ports `27015` and `27016` in your Oracle Cloud VCN Security List AND internal `iptables` (if you are running Ubuntu/Oracle Linux).
  ```bash
  sudo iptables -I INPUT 6 -m state --state NEW -p udp --dport 27015 -j ACCEPT
  sudo iptables -I INPUT 6 -m state --state NEW -p udp --dport 27016 -j ACCEPT
  sudo netfilter-persistent save
  ```
- **Resources**: The `docker-compose.yml` limits are set to 3.5 OCPUs and 20GB RAM, leaving room for the host OS on a standard 4 OCPU / 24GB instance.

## Troubleshooting

### "SteamCMD: command not found" or Exec Format Error
- This means `Box86` is not working correctly. The Dockerfile compiles Box86 specifically to handle the 32-bit `steamcmd` binary on your 64-bit ARM kernel. Ensure the build completed successfully.

### Performance / Lag
- Check logs for `Dynarec Active` messages.
- Ensure `BOX64_DYNAREC_BIGBLOCK=1` is set (default in wrapper).
- If on Oracle Cloud, ensure you aren't CPU throttled (check Cloud Console).

### Permission Denied
- The container runs as UID `10000`. If you bind mount a host directory that is owned by `root`, the server cannot write to it.
- Fix: `chown -R 10000:10000 ./data` on the host.

### Build Fails
- Provide at least 4GB of RAM for the build process (compiling Box64 is memory intensive).
