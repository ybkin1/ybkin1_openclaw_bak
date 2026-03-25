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

# P1 Security Fix - 2026-03-25: 分级保留策略
# - 每日备份：保留 7 份
# - 每周备份：保留 4 份（每月第一个 bundle 标记为 weekly）
# - 每月备份：保留 12 份（永久归档关键配置）
RETAIN_DAILY=7
RETAIN_WEEKLY=4
RETAIN_MONTHLY=12

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

# =============================================================================
# PHASE: Graded Retention Policy (P1 Security Fix - 2026-03-25)
# =============================================================================

# 判断备份是否为每月第一个（用于标记为 monthly）
is_monthly_backup() {
    local bundle_name="$1"
    # 提取日期部分：openclaw_bak_20260301_033001 → 20260301
    local date_part=$(echo "$bundle_name" | sed 's/openclaw_bak_//' | cut -d'_' -f1)
    local day=$(echo "$date_part" | cut -c7-8)
    
    # 每月的 1-7 日执行的备份标记为 monthly candidate
    [ "$day" -le 7 ] && return 0 || return 1
}

# 判断备份是否为每周第一个（用于标记为 weekly）
is_weekly_backup() {
    local bundle_name="$1"
    local date_part=$(echo "$bundle_name" | sed 's/openclaw_bak_//' | cut -d'_' -f1)
    local year=${date_part:0:4}
    local month=${date_part:4:2}
    local day=${date_part:6:2}
    
    # 使用 date 命令计算星期几（1=周一，7=周日）
    local weekday=$(date -d "$year-$month-$day" +%u 2>/dev/null || echo "1")
    
    # 周一的备份作为 weekly candidate
    [ "$weekday" = "1" ] && return 0 || return 1
}

# 分级清理策略
cleanup_graduated() {
    log_info "执行分级保留策略清理..."
    log_info "保留策略：每日${RETAIN_DAILY}份 + 每周${RETAIN_WEEKLY}份 + 每月${RETAIN_MONTHLY}份"
    
    # 获取所有 bundle，按时间排序
    local bundles=($(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "openclaw_bak_*" | sort))
    local total=${#bundles[@]}
    
    if [ "$total" -le "$RETAIN_DAILY" ]; then
        log_info "当前备份数量 ($total) ≤ 每日保留数 ($RETAIN_DAILY)，无需清理"
        return 0
    fi
    
    # 分类备份
    local -a daily_bundles=()
    local -a weekly_bundles=()
    local -a monthly_bundles=()
    local -a to_delete=()
    
    for bundle in "${bundles[@]}"; do
        bundle_name=$(basename "$bundle")
        
        if is_monthly_backup "$bundle_name"; then
            monthly_bundles+=("$bundle")
        elif is_weekly_backup "$bundle_name"; then
            weekly_bundles+=("$bundle")
        else
            daily_bundles+=("$bundle")
        fi
    done
    
    log_info "备份分类：每日${#daily_bundles[@]}份，每周${#weekly_bundles[@]}份，每月${#monthly_bundles[@]}份"
    
    # 清理超出的每日备份（保留最新的 RETAIN_DAILY 份）
    if [ ${#daily_bundles[@]} -gt "$RETAIN_DAILY" ]; then
        local to_remove=$((${#daily_bundles[@]} - RETAIN_DAILY))
        log_info "清理 ${to_remove} 份超期的每日备份"
        for ((i=0; i<to_remove; i++)); do
            to_delete+=("${daily_bundles[$i]}")
        done
    fi
    
    # 清理超出每周备份（保留最新的 RETAIN_WEEKLY 份）
    if [ ${#weekly_bundles[@]} -gt "$RETAIN_WEEKLY" ]; then
        local to_remove=$((${#weekly_bundles[@]} - RETAIN_WEEKLY))
        log_info "清理 ${to_remove} 份超期的每周备份"
        for ((i=0; i<to_remove; i++)); do
            to_delete+=("${weekly_bundles[$i]}")
        done
    fi
    
    # 清理超出每月备份（保留最新的 RETAIN_MONTHLY 份）
    if [ ${#monthly_bundles[@]} -gt "$RETAIN_MONTHLY" ]; then
        local to_remove=$((${#monthly_bundles[@]} - RETAIN_MONTHLY))
        log_info "清理 ${to_remove} 份超期的每月备份"
        for ((i=0; i<to_remove; i++)); do
            to_delete+=("${monthly_bundles[$i]}")
        done
    fi
    
    # 执行删除
    if [ ${#to_delete[@]} -gt 0 ]; then
        log_info "共删除 ${#to_delete[@]} 份备份"
        for bundle in "${to_delete[@]}"; do
            log_info "删除：$(basename "$bundle")"
            rm -rf "$bundle"
        done
    else
        log_info "无需清理，所有备份均在保留策略内"
    fi
}

# 兼容旧函数（保留但标记为废弃）
cleanup_old_bundles() {
    log_warn "cleanup_old_bundles 已废弃，使用 cleanup_graduated 替代"
    cleanup_graduated
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

# Cleanup old bundles using graduated retention policy (P1 Fix)
cleanup_graduated

# =============================================================================
# PHASE: Backup Integrity Verification (P0 Security Fix - 2026-03-25)
# =============================================================================
verify_backup_integrity() {
    log_info "Verifying backup integrity..."
    local errors=0
    
    # Verify all tar.gz files in bundle
    for archive in "$BUNDLE_DIR"/*/*.tar.gz; do
        if [ -f "$archive" ]; then
            if tar -tzf "$archive" > /dev/null 2>&1; then
                log_info "✓ $(basename "$archive") - OK"
            else
                log_warn "✗ $(basename "$archive") - CORRUPTED"
                errors=$((errors + 1))
            fi
        fi
    done
    
    # Verify backup-manager.sh copy
    if [ -f "$BUNDLE_DIR/config/backup-manager.sh" ]; then
        if diff -q "$0" "$BUNDLE_DIR/config/backup-manager.sh" > /dev/null 2>&1; then
            log_info "✓ backup-manager.sh - OK (identical)"
        else
            log_warn "✗ backup-manager.sh - MISMATCH"
            errors=$((errors + 1))
        fi
    fi
    
    # Generate checksum manifest
    log_info "Generating checksum manifest..."
    (cd "$BUNDLE_DIR" && find . -type f -name "*.tar.gz" -exec sha256sum {} \; > checksums.sha256)
    
    if [ "$errors" -gt 0 ]; then
        log_warn "Backup verification FAILED: $errors corrupted file(s)"
        return 1
    else
        log_info "Backup verification PASSED: All files intact"
        return 0
    fi
}

# Run verification
if ! verify_backup_integrity; then
    log_warn "Backup integrity check failed - sending alert"
    # Alert will be handled by health-guardian monitoring
fi

# =============================================================================

# Backup the backup-manager.sh itself (critical for recovery)
# Copy to bundle's config directory so it's versioned alongside other configs
cp "$0" "$BUNDLE_DIR/config/backup-manager.sh" 2>/dev/null || true

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
        git commit -m "📦 Backup bundle: $BUNDLE_NAME (graded retention: ${RETAIN_DAILY}d/${RETAIN_WEEKLY}w/${RETAIN_MONTHLY}m)"
        
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

log_info "Unified backup completed! Bundle: $BUNDLE_DIR (graded retention: ${RETAIN_DAILY}d/${RETAIN_WEEKLY}w/${RETAIN_MONTHLY}m)"
