#!/bin/bash
# OpenClaw 备份脚本
# 用法：./backup.sh [full|memory|config]

set -e

BACKUP_DIR="/root/.openclaw/workspace/backups"
WORKSPACE="/root/.openclaw/workspace"
DATE=$(date +%Y%m%d_%H%M%S)
RETAIN_COUNT=4  # 保留 4 次备份

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 备份类型
BACKUP_TYPE=${1:-full}

backup_memory() {
    log_info "备份记忆系统..."
    tar -czf "$BACKUP_DIR/memory_$DATE.tar.gz" \
        -C "$WORKSPACE" \
        memory/ \
        --exclude="memory/__pycache__"
    log_info "记忆备份完成：memory_$DATE.tar.gz"
}

backup_learnings() {
    log_info "备份学习日志..."
    tar -czf "$BACKUP_DIR/learnings_$DATE.tar.gz" \
        -C "$WORKSPACE" \
        .learnings/
    log_info "学习日志备份完成：learnings_$DATE.tar.gz"
}

backup_config() {
    log_info "备份配置文件..."
    tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" \
        -C "$WORKSPACE" \
        AGENTS.md \
        SOUL.md \
        TOOLS.md \
        MEMORY.md \
        HEARTBEAT.md \
        2>/dev/null || log_warn "部分配置文件不存在"
    log_info "配置备份完成：config_$DATE.tar.gz"
}

backup_docker_volumes() {
    log_info "备份 Docker 数据卷..."
    # Memos
    if [ -d "$HOME/.memos" ]; then
        tar -czf "$BACKUP_DIR/memos_$DATE.tar.gz" \
            -C "$HOME" \
            .memos/
        log_info "Memos 备份完成：memos_$DATE.tar.gz"
    fi
    
    # SearXNG 配置
    if [ -d "$HOME/.searxng" ]; then
        tar -czf "$BACKUP_DIR/searxng_$DATE.tar.gz" \
            -C "$HOME" \
            .searxng/
        log_info "SearXNG 备份完成：searxng_$DATE.tar.gz"
    fi
}

cleanup_old_backups() {
    log_info "清理旧备份（保留最近 $RETAIN_COUNT 次）..."
    
    # 列出所有备份文件并按时间排序
    for pattern in "memory_" "learnings_" "config_" "memos_" "searxng_"; do
        count=$(ls -t "$BACKUP_DIR"/${pattern}*.tar.gz 2>/dev/null | wc -l)
        if [ "$count" -gt "$RETAIN_COUNT" ]; then
            ls -t "$BACKUP_DIR"/${pattern}*.tar.gz | tail -n +$((RETAIN_COUNT + 1)) | xargs rm -f
            log_info "清理 ${pattern}* 旧备份完成"
        fi
    done
}

verify_backup() {
    local file=$1
    if tar -tzf "$file" >/dev/null 2>&1; then
        log_info "✓ 备份文件验证通过：$file"
        return 0
    else
        log_error "✗ 备份文件损坏：$file"
        return 1
    fi
}

# 主流程
log_info "================================"
log_info "OpenClaw 备份开始 - $DATE"
log_info "备份类型：$BACKUP_TYPE"
log_info "================================"

case $BACKUP_TYPE in
    full)
        backup_memory
        backup_learnings
        backup_config
        backup_docker_volumes
        ;;
    memory)
        backup_memory
        ;;
    learnings)
        backup_learnings
        ;;
    config)
        backup_config
        ;;
    docker)
        backup_docker_volumes
        ;;
    *)
        log_error "未知备份类型：$BACKUP_TYPE"
        echo "用法：$0 [full|memory|learnings|config|docker]"
        exit 1
        ;;
esac

# 验证最新备份
log_info "验证备份文件..."
LATEST=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
    verify_backup "$LATEST"
fi

# 清理旧备份
cleanup_old_backups

# 生成备份清单
echo "$DATE - $BACKUP_TYPE" >> "$BACKUP_DIR/backup_history.txt"

log_info "================================"
log_info "备份完成！"
log_info "备份位置：$BACKUP_DIR"
log_info "================================"

# 显示磁盘使用
log_info "备份目录大小：$(du -sh "$BACKUP_DIR" | cut -f1)"
