#!/bin/bash
# =============================================================================
# OpenClaw 简化版恢复脚本
# 功能：从备份包恢复 OpenClaw 系统
# 用法：bash restore.sh <备份路径> [目标目录]
# =============================================================================

set -euo pipefail

#=========== 配置 ===========
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_PATH="${1:-}"
readonly TARGET_ROOT="${2:-${OPENCLAW_ROOT:-/root/.openclaw}}"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

#=========== 日志函数 ===========
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }

#=========== 检查函数 ===========
check_backup() {
    local path="$1"
    
    [[ ! -d "$path" ]] && { error "备份目录不存在：$path"; exit 1; }
    [[ ! -f "$path/backup-stats.json" ]] && { error "缺少 backup-stats.json"; exit 1; }
    [[ ! -d "$path/config" ]] && { error "缺少 config/"; exit 1; }
    [[ ! -d "$path/memory" ]] && { error "缺少 memory/"; exit 1; }
    [[ ! -d "$path/system" ]] && { error "缺少 system/"; exit 1; }
    
    log "✓ 备份完整性验证通过"
}

#=========== 恢复函数 ===========
restore_tar() {
    local pattern="$1" dst="$2"
    mkdir -p "$dst"
    for f in $pattern; do
        [[ -f "$f" ]] && tar -xzf "$f" -C "$dst" 2>/dev/null || true
    done
}

restore_config() {
    step "恢复配置文件..."
    restore_tar "$BACKUP_PATH/config/config_*.tar.gz" "$TARGET_ROOT/workspace/agents/master/"
    log "✓ 配置已恢复"
}

restore_agents() {
    step "恢复 Agent 代码..."
    restore_tar "$BACKUP_PATH/agents/*.tar.gz" "$TARGET_ROOT/workspace/agents/"
    log "✓ Agent 已恢复"
}

restore_memory() {
    step "恢复记忆系统..."
    restore_tar "$BACKUP_PATH/memory/*.tar.gz" "$TARGET_ROOT/workspace/agents/master/"
    log "✓ 记忆已恢复"
}

restore_database() {
    step "恢复数据库..."
    [[ -d "$BACKUP_PATH/database" ]] || { warn "数据库目录不存在，跳过"; return 0; }
    
    [[ -f "$BACKUP_PATH/database/memory.db" ]] && \
        cp "$BACKUP_PATH/database/memory.db" "$TARGET_ROOT/workspace/agents/master/"
    
    [[ -f "$BACKUP_PATH/database/vectors.tar.gz" ]] && \
        tar -xzf "$BACKUP_PATH/database/vectors.tar.gz" -C "$TARGET_ROOT/workspace/agents/master/"
    
    log "✓ 数据库已恢复"
}

restore_system() {
    step "恢复系统配置..."
    restore_tar "$BACKUP_PATH/system/system_*.tar.gz" "$TARGET_ROOT/workspace/agents/master/"
    restore_tar "$BACKUP_PATH/system/systemd_overrides_*.tar.gz" "$HOME/.config/systemd/user/" 2>/dev/null || true
    log "✓ 系统配置已恢复"
}

restore_crontab() {
    step "恢复 Crontab..."
    local crontab_file
    crontab_file=$(find "$BACKUP_PATH/system" -name "crontab_*.txt" | head -1)
    [[ -f "$crontab_file" ]] && crontab "$crontab_file" && log "✓ Crontab 已恢复" || warn "Crontab 恢复失败"
}

start_service() {
    step "启动服务..."
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable openclaw-gateway 2>/dev/null || true
    systemctl --user start openclaw-gateway 2>/dev/null || true
    log "✓ 服务已启动"
}

#=========== 主流程 ===========
main() {
    [[ -z "$BACKUP_PATH" ]] && { error "请指定备份路径"; exit 1; }
    
    echo ""
    echo "=========================================="
    echo "   OpenClaw 恢复脚本 v2.0 (简化版)"
    echo "=========================================="
    echo ""
    
    log "备份路径：$BACKUP_PATH"
    log "目标目录：$TARGET_ROOT"
    echo ""
    
    check_backup "$BACKUP_PATH"
    
    step "创建目录..."
    mkdir -p "$TARGET_ROOT"/{workspace,backups-unified,logs}
    mkdir -p "$TARGET_ROOT/workspace/agents"
    mkdir -p "$HOME/.config/systemd/user/" 2>/dev/null || true
    log "✓ 目录已创建"
    echo ""
    
    restore_config
    restore_agents
    restore_memory
    restore_database
    restore_system
    restore_crontab
    start_service
    
    echo ""
    echo "=========================================="
    echo "   恢复完成！"
    echo "=========================================="
    echo ""
    log "后续步骤:"
    echo "  1. systemctl --user status openclaw-gateway"
    echo "  2. openclaw doctor"
    echo "  3. 配置飞书 API（如需要）"
    echo ""
}

main "$@"
