#!/bin/bash
# Unified Backup Manager for All Agents
# Implements 4-backup retention policy for local and GitHub

set -euo pipefail

BACKUP_ROOT="/root/.openclaw/backups-unified"
WORKSPACE_ROOT="/root/.openclaw/workspace"
DATE=$(date +%Y%m%d_%H%M%S)
PUSH_TO_GITHUB=false
RETAIN_COUNT=4

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Create backup directories
mkdir -p "$BACKUP_ROOT"/{agents,memory,config,system,logs}

# Parse arguments
BACKUP_TYPE="${1:-full}"
for arg in "$@"; do
    [ "$arg" = "--push" ] && PUSH_TO_GITHUB=true
done

log_info "Starting unified backup - $DATE (type: $BACKUP_TYPE)"

# Function to cleanup old backups (keep only latest N)
cleanup_old_backups() {
    local backup_dir="$1"
    local pattern="$2"
    local retain_count="${3:-4}"
    
    # Count existing backups
    local backup_count=$(find "$backup_dir" -name "$pattern" 2>/dev/null | wc -l)
    
    if [ "$backup_count" -gt "$retain_count" ]; then
        local to_delete=$((backup_count - retain_count))
        log_info "Cleaning up $to_delete old backups in $backup_dir (keeping $retain_count)"
        
        # Delete oldest backups
        find "$backup_dir" -name "$pattern" -printf '%T@ %p\n' 2>/dev/null | \
            sort -n | head -n "$to_delete" | cut -d' ' -f2- | xargs -r rm
    fi
}

# Discover all agent workspaces
discover_agents() {
    local agents=()
    # Always include master agent
    if [ -d "$WORKSPACE_ROOT/main" ] && [ -f "$WORKSPACE_ROOT/main/AGENTS.md" ]; then
        agents+=("main")
    fi
    
    # Find other agents
    for agent_dir in "$WORKSPACE_ROOT"/*/; do
        agent_name=$(basename "$agent_dir")
        if [ "$agent_name" != "main" ] && [ -f "$agent_dir/AGENTS.md" ]; then
            agents+=("$agent_name")
        fi
    done
    
    echo "${agents[@]}"
}

case $BACKUP_TYPE in
    full)
        # Backup all agents
        AGENTS=($(discover_agents))
        for agent in "${AGENTS[@]}"; do
            log_info "Backing up agent: $agent"
            tar -czf "$BACKUP_ROOT/agents/${agent}_$DATE.tar.gz" -C "$WORKSPACE_ROOT" "$agent/"
            cleanup_old_backups "$BACKUP_ROOT/agents" "${agent}_*.tar.gz" "$RETAIN_COUNT"
        done
        
        # Backup memory system
        if [ -d "$WORKSPACE_ROOT/main/memory" ]; then
            tar -czf "$BACKUP_ROOT/memory/memory_$DATE.tar.gz" -C "$WORKSPACE_ROOT/main" memory/
            cleanup_old_backups "$BACKUP_ROOT/memory" "memory_*.tar.gz" "$RETAIN_COUNT"
        fi
        
        # Backup configurations
        tar -czf "$BACKUP_ROOT/config/config_$DATE.tar.gz" \
            -C "$WORKSPACE_ROOT/main" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md \
            -C /root/.openclaw openclaw.json exec-approvals.json 2>/dev/null || true
        cleanup_old_backups "$BACKUP_ROOT/config" "config_*.tar.gz" "$RETAIN_COUNT"
        
        # Backup system-wide (skills, crontab, etc.)
        tar -czf "$BACKUP_ROOT/system/system_$DATE.tar.gz" \
            -C "$WORKSPACE_ROOT/main" skills/ \
            -C /var/spool/cron crontab 2>/dev/null || true
        cleanup_old_backups "$BACKUP_ROOT/system" "system_*.tar.gz" "$RETAIN_COUNT"
        ;;
        
    agents)
        AGENTS=($(discover_agents))
        for agent in "${AGENTS[@]}"; do
            log_info "Backing up agent: $agent"
            tar -czf "$BACKUP_ROOT/agents/${agent}_$DATE.tar.gz" -C "$WORKSPACE_ROOT" "$agent/"
            cleanup_old_backups "$BACKUP_ROOT/agents" "${agent}_*.tar.gz" "$RETAIN_COUNT"
        done
        ;;
        
    memory)
        # Backup shared memory layer
        if [ -d "$WORKSPACE_ROOT/memory" ]; then
            tar -czf "$BACKUP_ROOT/memory/memory_shared_$DATE.tar.gz" -C "$WORKSPACE_ROOT" memory/
            cleanup_old_backups "$BACKUP_ROOT/memory" "memory_shared_*.tar.gz" "$RETAIN_COUNT"
        fi
        
        # Backup all agents' private memory
        for agent_dir in "$WORKSPACE_ROOT/agents"/*/; do
            agent_name=$(basename "$agent_dir")
            if [ -d "$agent_dir/memory" ]; then
                tar -czf "$BACKUP_ROOT/memory/memory_${agent_name}_$DATE.tar.gz" -C "$WORKSPACE_ROOT/agents" "$agent_name/memory/"
                cleanup_old_backups "$BACKUP_ROOT/memory" "memory_${agent_name}_*.tar.gz" "$RETAIN_COUNT"
            fi
        done
        ;;
        
    config)
        # 备份全局配置文件（从当前架构位置）
        tar -czf "$BACKUP_ROOT/config/config_$DATE.tar.gz" \
            -C "/root/.openclaw" openclaw.json exec-approvals.json 2>/dev/null || true
        # 备份 agents 根目录的配置文件
        if [ -d "$WORKSPACE_ROOT/agents/master" ]; then
            tar -czf "$BACKUP_ROOT/config/config_agent_master_$DATE.tar.gz" \
                -C "$WORKSPACE_ROOT/agents/master" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md 2>/dev/null || true
            cleanup_old_backups "$BACKUP_ROOT/config" "config_agent_master_*.tar.gz" "$RETAIN_COUNT"
        fi
        cleanup_old_backups "$BACKUP_ROOT/config" "config_*.tar.gz" "$RETAIN_COUNT"
        ;;

    system)
        # 备份 system-level 文件
        tar -czf "$BACKUP_ROOT/system/system_$DATE.tar.gz" \
            -C "$WORKSPACE_ROOT/agents/master" skills/ 2>/dev/null || true
        # 备份 crontab（如果有）
        if [ -f "/var/spool/cron/crontabs/$(whoami)" ]; then
            tar -czf "$BACKUP_ROOT/system/crontab_$DATE.tar.gz" \
                -C "/var/spool/cron/crontabs" "$(whoami)" 2>/dev/null || true
        fi
        cleanup_old_backups "$BACKUP_ROOT/system" "system_*.tar.gz" "$RETAIN_COUNT"
        cleanup_old_backups "$BACKUP_ROOT/system" "crontab_*.tar.gz" "$RETAIN_COUNT"
        ;;
        
    *)
        log_warn "Unknown backup type: $BACKUP_TYPE. Using 'full'."
        # Fall through to full backup
        ;;
esac

# GitHub sync if requested
if [ "$PUSH_TO_GITHUB" = true ]; then
    cd "$BACKUP_ROOT"
    
    # Initialize git if needed
    if [ ! -d ".git" ]; then
        log_info "Initializing Git repository..."
        git init
        git remote add origin git@github.com:your-repo/openclaw-backups.git 2>/dev/null || true
    fi
    
    # Add all backup files
    git add agents/*.tar.gz memory/*.tar.gz config/*.tar.gz system/*.tar.gz 2>/dev/null || true
    
    if ! git diff --cached --quiet; then
        git commit -m "📦 Unified backup $DATE (4-retention policy)"
        
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

log_info "Unified backup completed! Retention: $RETAIN_COUNT backups per category"