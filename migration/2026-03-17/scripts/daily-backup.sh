#!/bin/bash
# 每日核心文件备份脚本
# 由 cron 每天凌晨 2 点执行

set -e

WORKSPACE="${HOME}/.openclaw/workspace"
BACKUP_DIR="${WORKSPACE}/backups/daily"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y-%m-%d)

# 创建备份目录
mkdir -p "${BACKUP_DIR}"

echo "🔄 开始每日核心文件备份 [${DATE}]"

cd "${WORKSPACE}"

# 1. 备份 MEMORY.md
if [ -f "MEMORY.md" ]; then
    cp "MEMORY.md" "${BACKUP_DIR}/MEMORY.md.${DATE}.bak"
    cp "MEMORY.md" "MEMORY.md.bak"
    echo "✅ MEMORY.md 备份完成"
fi

# 2. 备份其他核心文件
for file in SOUL.md AGENTS.md USER.md; do
    if [ -f "${file}" ]; then
        cp "${file}" "${BACKUP_DIR}/${file}.${DATE}.bak"
        echo "✅ ${file} 备份完成"
    fi
done

# 3. 打包备份
tar -czf "${BACKUP_DIR}/core-files.${DATE}.tar.gz" \
    SOUL.md MEMORY.md AGENTS.md USER.md \
    2>/dev/null || true

echo "✅ 打包完成：${BACKUP_DIR}/core-files.${DATE}.tar.gz"

# 4. 清理 30 天前的备份
find "${BACKUP_DIR}" -name "*.bak" -mtime +30 -delete 2>/dev/null || true
find "${BACKUP_DIR}" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true

echo "✅ 清理旧备份完成"
echo "🎉 每日备份完成"
