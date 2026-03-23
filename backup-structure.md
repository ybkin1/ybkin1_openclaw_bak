# Unified Backup Structure

## Directory Layout
```
backups-unified/
├── agents/           # All agent workspaces
│   ├── master/      # Master agent backups
│   └── [agent-id]/  # Other agents (when created)
├── memory/          # Memory system backups (4 latest only)
├── config/          # Configuration backups (4 latest only)  
├── system/          # System-wide backups (skills, crontab, etc.)
└── logs/            # Backup operation logs
```

## Retention Policy
- **Local**: Keep only latest 4 backups per category
- **GitHub**: Push only latest 4 backups per category
- **Automatic cleanup**: Remove older backups during each backup cycle

## Agent Discovery
- Scan `/root/.openclaw/workspace/*/` for agent directories
- Each directory with `AGENTS.md` is considered an agent workspace
- Master agent is always included (`/root/.openclaw/workspace/main/`)