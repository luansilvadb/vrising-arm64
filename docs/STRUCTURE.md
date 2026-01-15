# Project Structure & EasyPanel Optimization

This project is designed with a **Flat Structure** for maximum simplicity and compatibility with EasyPanel.

## Directory Structure

```
/
├── Dockerfile              # Container definition
├── docker-compose.yml      # Service definition
├── start.sh                # Main Orchestrator
├── env.sh                  # Environment Variables
├── steamcmd.sh             # Update Logic
├── wine.sh                 # Wine Config
├── config.sh               # Settings Generator
└── cleanup.sh              # Maintenance
```

## How it works

1.  **`start.sh`**: The single entrypoint. It imports the other scripts from the same directory.
2.  **Environment Variables**: Controls everything. No hardcoded configs.
3.  **Persistence**: Data is stored in `/data`.

## Modifying Logic

Since the structure is flat, all logic files are in the root.
- To change update behavior -> Edit `steamcmd.sh`
- To change settings map -> Edit `config.sh`
