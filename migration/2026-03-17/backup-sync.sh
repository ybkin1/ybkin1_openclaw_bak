#!/bin/bash
# Legacy Backup Sync Script - Redirects to Unified Backup Manager
# Original: 2026-03-05 | Updated: 2026-03-17 (Unified Backup System)

set -e

BACKUP_DIR="/root/.openclaw/backups-repo"
UNIFIED_BACKUP="/root/.openclaw/backups-unified"
DATE=$(date +%Y%m%d_%H%M%S)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check if unified backup manager exists
if [ -f "$UNIFIED_BACKUP/backup-manager.sh" ]; then
    log_info "Using Unified Backup Manager (v2.0)"
    log_warn "Legacy backup-sync.sh is deprecated. Use backup-manager.sh directly."
    
    # Redirect to unified backup manager
    BACKUP_TYPE="${1:-full}"
    PUSH_FLAG=""
    [ "$2" = "--push" ] && PUSH_FLAG="--push"
    
    exec "$UNIFIED_BACKUP/backup-manager.sh" "$BACKUP_TYPE" $PUSH_FLAG
else
    # Fallback to legacy behavior (for emergency only)
    log_warn "Unified backup manager not found. Using legacy fallback."
    
    WORKSPACE="/root/.openclaw/workspace"
    PUSH_TO_GITHUB=false
    
    for arg in "$@"; do
        [ "$arg" = "--push" ] && PUSH_TO_GITHUB=true
    done
    
    BACKUP_TYPE="${1:-full}"
    
    log_info "Starting legacy backup - $DATE (type: $BACKUP_TYPE)"
    
    case $BACKUP_TYPE in
        full|memory)
            tar -czf "$BACKUP_DIR/memory_$DATE.tar.gz" -C "$WORKSPACE/main" memory/
            log_info "Memory backup completed"
            ;;
        config)
            tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" \
                -C "$WORKSPACE/main" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md \
                -C /root/.openclaw openclaw.json exec-approvals.json 2>/dev/null || true
            log_info "Config backup completed"
            ;;
    esac
    
    if [ "$PUSH_TO_GITHUB" = true ]; then
        cd "$BACKUP_DIR"
        git add *.tar.gz 2>/dev/null || true
        if ! git diff --cached --quiet; then
            git commit -m "📦 Legacy backup $DATE"
            git push origin main 2>&1 || log_warn "GitHub push failed"
        fi
    fi
    
    # Legacy cleanup (30 days)
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
    
    log_info "Legacy backup completed!"
fi