# V Rising ARM64 Server Settings

See the official V Rising wiki for detailed configuration options: https://vrising.fandom.com/wiki/V_Rising_Dedicated_Server

## Environment Variables

All server settings can be configured via environment variables. See `.env.example` for the complete list.

### Core Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | V Rising FEX Server | Server name shown in browser |
| `SAVE_NAME` | world1 | Save file name |
| `GAME_PORT` | 9876 | Game port (UDP) |
| `QUERY_PORT` | 9877 | Query port (UDP) |

### Host Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_CONNECTED_USERS` | 100 | Maximum players |
| `MAX_CONNECTED_ADMINS` | 5 | Admin slots |
| `SERVER_FPS` | 60 | Server tick rate |
| `SERVER_PASSWORD` | (empty) | Server password |
| `SECURE` | true | VAC protection |

### Game Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `GAME_SETTINGS_PRESET` | (empty) | Use preset (StandardPvE, StandardPvP) |
| `GAME_DIFFICULTY_PRESET` | (empty) | Difficulty preset |
| `LIST_ON_MASTER_SERVER` | true | List on Steam browser |

### RCON

| Variable | Default | Description |
|----------|---------|-------------|
| `RCON_ENABLED` | true | Enable RCON |
| `RCON_PORT` | 25575 | RCON port |
| `RCON_PASSWORD` | (empty) | RCON password |

## Custom Game Settings

If `GAME_SETTINGS_PRESET` is empty, the server will use `ServerGameSettings.json` from the project root.
Edit this file to customize game rules, castle limits, PvP settings, etc.

## Volumes

| Path | Description |
|------|-------------|
| `/data/server` | Game server files |
| `/data/wineprefix` | Wine configuration |
| `/data/steamcmd` | SteamCMD cache |
| `/data/save-data` | Save files and settings |
