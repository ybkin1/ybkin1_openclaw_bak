#!/bin/bash
# 本地恢复脚本 - 不依赖 GitHub

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# 配置
BACKUP_SOURCE="/root/.openclaw/backups-unified/openclaw_bak_20260327_174150"
TARGET_ROOT="/root/.openclaw"

echo ""
echo "=========================================="
echo "   OpenClaw 本地恢复（不依赖 GitHub）"
echo "=========================================="
echo ""

# 检查备份源
if [ ! -d "$BACKUP_SOURCE" ]; then
    log_error "备份源不存在：$BACKUP_SOURCE"
    exit 1
fi

log_info "备份源：$BACKUP_SOURCE"
log_info "目标目录：$TARGET_ROOT"
echo ""

# 恢复配置
log_step "恢复配置文件..."
if [ -f "$BACKUP_SOURCE/config/config_"*".tar.gz" ]; then
    tar -xzf "$BACKUP_SOURCE"/config/config_*.tar.gz -C "$TARGET_ROOT/workspace/agents/master/"
    log_info "✓ 配置文件已恢复"
fi

# 恢复 Agent 代码
log_step "恢复 Agent 代码..."
for tar in "$BACKUP_SOURCE"/agents/*.tar.gz; do
    [ -f "$tar" ] || continue
    agent=$(basename "$tar" | cut -d'_' -f1)
    mkdir -p "$TARGET_ROOT/workspace/agents/$agent"
    tar -xzf "$tar" -C "$TARGET_ROOT/workspace/agents/$agent"
done
log_info "✓ Agent 代码已恢复"

# 恢复记忆系统
log_step "恢复记忆系统..."
for tar in "$BACKUP_SOURCE"/memory/*.tar.gz; do
    [ -f "$tar" ] || continue
    tar -xzf "$tar" -C "$TARGET_ROOT/workspace/agents/master/"
done
log_info "✓ 记忆系统已恢复"

# 恢复系统配置
log_step "恢复系统配置..."
if [ -f "$BACKUP_SOURCE"/system/system_"*".tar.gz ]; then
    tar -xzf "$BACKUP_SOURCE"/system/system_*.tar.gz -C "$TARGET_ROOT/workspace/agents/master/"
    log_info "✓ 系统配置已恢复"
fi

# 恢复 crontab
log_step "恢复 Crontab..."
if [ -f "$BACKUP_SOURCE"/system/crontab_"*".txt ]; then
    crontab "$BACKUP_SOURCE"/system/crontab_*.txt
    log_info "✓ Crontab 已恢复"
fi

# 恢复 systemd 服务
log_step "恢复 Systemd 服务..."
if [ -f "$BACKUP_SOURCE"/identity/systemd_services_"*".tar.gz ]; then
    tar -xzf "$BACKUP_SOURCE"/identity/systemd_services_*.tar.gz -C ~/.config/systemd/user/
    systemctl --user daemon-reload
    log_info "✓ Systemd 服务已恢复"
fi

echo ""
echo "=========================================="
echo "   本地恢复完成！"
echo "=========================================="
echo ""
log_info "后续步骤:"
echo "  1. 检查服务状态：systemctl --user status openclaw-gateway"
echo "  2. 启动服务：systemctl --user start openclaw-gateway"
echo "  3. 验证配置：openclaw doctor"
echo ""
