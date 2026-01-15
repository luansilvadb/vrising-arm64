# V Rising ARM64 Dedicated Server - Rust Edition

[![Docker](https://img.shields.io/badge/Docker-ARM64-blue)](https://www.docker.com/)
[![Rust](https://img.shields.io/badge/Rust-1.70+-orange)](https://www.rust-lang.org/)
[![FEX-Emu](https://img.shields.io/badge/FEX--Emu-2409-green)](https://fex-emu.com/)

> 🧛 Run V Rising Dedicated Server on ARM64 devices (Apple Silicon, Raspberry Pi 5, AWS Graviton, Oracle Ampere, etc.)

Based on [luansilvadb/vrising-arm64](https://github.com/luansilvadb/vrising-arm64) - Reimplemented in Rust for better performance and reliability.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Docker Container (ARM64)                      │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │  Rust Launcher  │→ │  FEXInterpreter │→ │  Wine (x86-64)      │  │
│  │  (vrising-      │  │  (x86-64 → ARM) │  │  (Windows API)      │  │
│  │   launcher)     │  │                 │  │                     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────┘  │
│                                                      ↓               │
│                                             ┌─────────────────────┐  │
│                                             │  VRisingServer.exe  │  │
│                                             │  (Windows x86-64)   │  │
│                                             └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Using Docker Compose

1. Clone this repository:
```bash
git clone https://github.com/your-username/vrising-arm64-rust.git
cd vrising-arm64-rust
```

2. Copy and edit environment configuration:
```bash
cp .env.example .env
nano .env
```

3. Build and run:
```bash
docker compose up -d --build
```

4. View logs:
```bash
docker compose logs -f
```

### Environment Variables

See [SERVER_SETTINGS.md](SERVER_SETTINGS.md) for complete configuration options.

Key variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | V Rising FEX Server | Server name |
| `SAVE_NAME` | world1 | World save name |
| `GAME_PORT` | 9876 | Game port (UDP) |
| `QUERY_PORT` | 9877 | Query port (UDP) |
| `MAX_CONNECTED_USERS` | 100 | Max players |
| `DEBUG` | false | Enable debug logging |

## 📁 Project Structure

```
├── Dockerfile              # Multi-stage Docker build
├── docker-compose.yml      # Service definition
├── Cargo.toml              # Rust dependencies
├── src/
│   ├── main.rs             # Main launcher (replaces start.sh)
│   └── config.rs           # Configuration handling
├── .env.example            # Environment template
├── ServerGameSettings.json # Custom game settings
└── SERVER_SETTINGS.md      # Configuration documentation
```

## 🔧 How It Works

1. **Rust Launcher** (`vrising-launcher`): Orchestrates the entire startup process
   - Sets up environment variables
   - Initializes Wine prefix
   - Downloads/updates server via SteamCMD
   - Generates server configuration files
   - Launches the server

2. **FEXInterpreter**: Translates x86-64 instructions to ARM64 at runtime

3. **Wine**: Provides Windows API compatibility layer

4. **VRisingServer.exe**: The actual game server (Windows executable)

## 🛠️ Building Locally

### Prerequisites

- Rust 1.70+ (for local development)
- Docker with ARM64 support

### Build the Docker image

```bash
docker build -t vrising-fex:latest .
```

### Run locally (Rust development)

```bash
cargo build --release
```

Note: The binary is designed to run inside the Docker container on ARM64 Linux.

## 📊 Resource Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 cores | 8+ cores |
| RAM | 4 GB | 8+ GB |
| Storage | 10 GB | 20+ GB |
| Network | 10 Mbps | 100+ Mbps |

## 🐛 Troubleshooting

### Server won't start

1. Check logs: `docker compose logs -f`
2. Enable debug mode: Set `DEBUG=true` in `.env`
3. Ensure ports 9876-9877 are open (UDP)

### FEX errors

FEX-Emu requires a proper RootFS. The Dockerfile downloads Ubuntu 22.04 RootFS automatically. If issues persist:

```bash
docker exec -it vrising-fex /bin/bash
FEXInterpreter --version
```

### Wine errors

Wine prefix is stored in `/data/wineprefix`. If corrupted:

```bash
docker compose down
docker volume rm vrising-data
docker compose up -d --build
```

## 📜 License

This project is provided as-is under the MIT License.

## 🙏 Credits

- [luansilvadb/vrising-arm64](https://github.com/luansilvadb/vrising-arm64) - Original implementation
- [FEX-Emu](https://fex-emu.com/) - x86-64 emulation on ARM64
- [Wine](https://www.winehq.org/) - Windows compatibility layer
- [Stunlock Studios](https://stunlock.com/) - V Rising developers
