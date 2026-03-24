#!/bin/bash
# Unified Backup Manager v2.0 - Bundle-based retention
# Single backup: openclaw_bak_<timestamp>/
# Keep latest 4 bundles, auto-delete older ones

set -euo pipefail

BACKUP_ROOT="/root/.openclaw/backups-unified"
WORKSPACE_ROOT="/root/.openclaw/workspace"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUNDLE_NAME="openclaw_bak_$TIMESTAMP"
BUNDLE_DIR="$BACKUP_ROOT/$BUNDLE_NAME"
PUSH_TO_GITHUB=false
RETAIN_COUNT=4

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Create bundle directory structure
mkdir -p "$BUNDLE_DIR"/{agents,memory,config,system}

# Parse arguments
BACKUP_TYPE="${1:-full}"
for arg in "$@"; do
    [ "$arg" = "--push" ] && PUSH_TO_GITHUB=true
done

log_info "Starting unified backup - $BUNDLE_NAME (type: $BACKUP_TYPE)"

# Cleanup old backup bundles (keep only latest N)
cleanup_old_bundles() {
    local retain_count="${1:-4}"
    
    # Find all bundle directories sorted by name (timestamp ascending)
    local bundles=($(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "openclaw_bak_*" | sort))
    local total=${#bundles[@]}
    
    if [ "$total" -gt "$retain_count" ]; then
        local to_delete=$((total - retain_count))
        log_info "Cleaning up $to_delete old backup bundles (keeping $retain_count latest)"
        
        # Delete oldest bundles (indices 0 to to_delete-1)
        for i in $(seq 0 $((to_delete-1))); do
            bundle="${bundles[$i]}"
            log_info "Deleting: $(basename "$bundle")"
            rm -rf "$bundle"
        done
    fi
}

# Discover all agent workspaces
discover_agents() {
    local agents=()
    
    # Check workspace/agents/ directory (primary location)
    if [ -d "$WORKSPACE_ROOT/agents" ]; then
        for agent_dir in "$WORKSPACE_ROOT/agents"/*/; do
            agent_name=$(basename "$agent_dir")
            # Skip 'master' since we'll add 'main' (symlink to master)
            if [ "$agent_name" != "master" ] && [ -f "$agent_dir/AGENTS.md" ]; then
                agents+=("$agent_name")
            fi
        done
    fi
    
    # Always include main (symlink to agents/master)
    if [ -d "$WORKSPACE_ROOT/main" ] && [ -f "$WORKSPACE_ROOT/main/AGENTS.md" ]; then
        agents+=("main")
    fi
    
    echo "${agents[@]}"
}

case $BACKUP_TYPE in
    full)
        # Backup all agents into bundle
        AGENTS=($(discover_agents))
        for agent in "${AGENTS[@]}"; do
            log_info "Backing up agent: $agent"
            if [ "$agent" = "main" ]; then
                tar -czf "$BUNDLE_DIR/agents/main_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" main/
            else
                tar -czf "$BUNDLE_DIR/agents/${agent}_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" "agents/$agent/"
            fi
        done
        
        # Backup memory system (main + shared + all agents' private memory)
        if [ -d "$WORKSPACE_ROOT/main/memory" ]; then
            tar -czf "$BUNDLE_DIR/memory/memory_main_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT/main" memory/
        fi
        
        if [ -d "$WORKSPACE_ROOT/memory" ]; then
            tar -czf "$BUNDLE_DIR/memory/memory_shared_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" memory/
        fi
        
        # Backup all agents' private memory
        for agent_dir in "$WORKSPACE_ROOT/agents"/*/; do
            agent_name=$(basename "$agent_dir")
            if [ -d "$agent_dir/memory" ]; then
                tar -czf "$BUNDLE_DIR/memory/memory_${agent_name}_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT/agents" "$agent_name/memory/"
            fi
        done
        
        # Backup configurations
        if [ -d "$WORKSPACE_ROOT/main" ]; then
            tar -czf "$BUNDLE_DIR/config/config_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/main" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md \
                -C /root/.openclaw openclaw.json exec-approvals.json 2>/dev/null || true
        fi
        
        # Backup master agent's config (if separate)
        if [ -d "$WORKSPACE_ROOT/agents/master" ]; then
            tar -czf "$BUNDLE_DIR/config/config_agent_master_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/agents/master" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md 2>/dev/null || true
        fi
        
        # Backup system-wide (skills, scripts, crontab, systemd overrides)
        if [ -d "$WORKSPACE_ROOT/agents/master" ]; then
            tar -czf "$BUNDLE_DIR/system/system_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/agents/master" skills/ scripts/ 2>/dev/null || true
        fi
        # Backup crontab
        if [ -f "/var/spool/cron/crontabs/$(whoami)" ]; then
            tar -czf "$BUNDLE_DIR/system/crontab_$TIMESTAMP.tar.gz" \
                -C "/var/spool/cron/crontabs" "$(whoami)" 2>/dev/null || true
        fi
        # Backup systemd overrides
        if [ -d "$HOME/.config/systemd/user" ]; then
            tar -czf "$BUNDLE_DIR/system/systemd_overrides_$TIMESTAMP.tar.gz" \
                -C "$HOME/.config/systemd/user" . 2>/dev/null || true
        fi
        ;;
        
    agents)
        AGENTS=($(discover_agents))
        for agent in "${AGENTS[@]}"; do
            log_info "Backing up agent: $agent"
            if [ "$agent" = "main" ]; then
                tar -czf "$BUNDLE_DIR/agents/main_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" main/
            else
                tar -czf "$BUNDLE_DIR/agents/${agent}_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" "agents/$agent/"
            fi
        done
        ;;
        
    memory)
        if [ -d "$WORKSPACE_ROOT/main/memory" ]; then
            tar -czf "$BUNDLE_DIR/memory/memory_main_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT/main" memory/
        fi
        if [ -d "$WORKSPACE_ROOT/memory" ]; then
            tar -czf "$BUNDLE_DIR/memory/memory_shared_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" memory/
        fi
        for agent_dir in "$WORKSPACE_ROOT/agents"/*/; do
            agent_name=$(basename "$agent_dir")
            if [ -d "$agent_dir/memory" ]; then
                tar -czf "$BUNDLE_DIR/memory/memory_${agent_name}_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT/agents" "$agent_name/memory/"
            fi
        done
        ;;
        
    config)
        if [ -d "$WORKSPACE_ROOT/main" ]; then
            tar -czf "$BUNDLE_DIR/config/config_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/main" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md \
                -C /root/.openclaw openclaw.json exec-approvals.json 2>/dev/null || true
        fi
        if [ -d "$WORKSPACE_ROOT/agents/master" ]; then
            tar -czf "$BUNDLE_DIR/config/config_agent_master_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/agents/master" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md 2>/dev/null || true
        fi
        ;;

    system)
        if [ -d "$WORKSPACE_ROOT/agents/master" ]; then
            tar -czf "$BUNDLE_DIR/system/system_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/agents/master" skills/ scripts/ 2>/dev/null || true
        fi
        if [ -f "/var/spool/cron/crontabs/$(whoami)" ]; then
            tar -czf "$BUNDLE_DIR/system/crontab_$TIMESTAMP.tar.gz" \
                -C "/var/spool/cron/crontabs" "$(whoami)" 2>/dev/null || true
        fi
        if [ -d "$HOME/.config/systemd/user" ]; then
            tar -czf "$BUNDLE_DIR/system/systemd_overrides_$TIMESTAMP.tar.gz" \
                -C "$HOME/.config/systemd/user" . 2>/dev/null || true
        fi
        ;;
        
    *)
        log_warn "Unknown backup type: $BACKUP_TYPE. Using 'full'."
        ;;
esac

# Cleanup old bundles (after creating new one)
cleanup_old_bundles "$RETAIN_COUNT"

# GitHub sync if requested
if [ "$PUSH_TO_GITHUB" = true ]; then
    cd "$BACKUP_ROOT"
    
    # Initialize git if needed
    if [ ! -d ".git" ]; then
        log_info "Initializing Git repository..."
        git init
        git remote add origin git@github.com:ybkin1/ybkin1_openclaw_bak.git 2>/dev/null || true
    fi
    
    # Add all backup files (including the new bundle directory)
    git add openclaw_bak_*/ 2>/dev/null || true
    
    # Also add any loose tar.gz for backward compatibility
    git add agents/*.tar.gz memory/*.tar.gz config/*.tar.gz system/*.tar.gz 2>/dev/null || true
    
    if ! git diff --cached --quiet; then
        git commit -m "📦 Backup bundle: $BUNDLE_NAME (retention: $RETAIN_COUNT)"
        
        # Push to GitHub
        if git push origin main 2>&1; then
            log_info "✓ GitHub sync successful"
        else
            log_info "⚠ GitHub push failed (network or SSH key issue)"
        fi
    else
        log_info "✓ No new backups, skipping push"
    fi
fi

log_info "Unified backup completed! Bundle: $BUNDLE_DIR (retain latest $RETAIN_COUNT bundles)"
