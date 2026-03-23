#!/bin/bash
# MEMORY.md 备份脚本
# 用法：./backup-memory.sh [备份目录]

set -e

WORKSPACE="${HOME}/.openclaw/workspace"
MEMORY_FILE="${WORKSPACE}/MEMORY.md"
BACKUP_DIR="${WORKSPACE}/backups/memory"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p "${BACKUP_DIR}"

# 检查 MEMORY.md 是否存在
if [ ! -f "${MEMORY_FILE}" ]; then
    echo "❌ MEMORY.md 不存在"
    exit 1
fi

# 创建备份
cp "${MEMORY_FILE}" "${BACKUP_DIR}/MEMORY.md.${TIMESTAMP}.bak"

# 同时更新 MEMORY.md.bak (最新备份)
cp "${MEMORY_FILE}" "${WORKSPACE}/MEMORY.md.bak"

# 清理 7 天前的备份
find "${BACKUP_DIR}" -name "MEMORY.md.*.bak" -mtime +7 -delete 2>/dev/null || true

echo "✅ MEMORY.md 备份完成"
echo "   备份文件：${BACKUP_DIR}/MEMORY.md.${TIMESTAMP}.bak"
echo "   最新备份：${WORKSPACE}/MEMORY.md.bak"
