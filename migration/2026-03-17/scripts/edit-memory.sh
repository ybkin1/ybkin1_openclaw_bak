#!/bin/bash
# MEMORY.md 安全编辑脚本
# 用法：./edit-memory.sh <操作> [内容]
# 操作: backup | edit | restore

set -e

WORKSPACE="${HOME}/.openclaw/workspace"
MEMORY_FILE="${WORKSPACE}/MEMORY.md"
BACKUP_FILE="${WORKSPACE}/MEMORY.md.bak"
BACKUP_DIR="${WORKSPACE}/backups/memory"

case "${1:-}" in
    backup)
        # 备份 MEMORY.md
        mkdir -p "${BACKUP_DIR}"
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        cp "${MEMORY_FILE}" "${BACKUP_DIR}/MEMORY.md.${TIMESTAMP}.bak"
        cp "${MEMORY_FILE}" "${BACKUP_FILE}"
        echo "✅ 备份完成：${BACKUP_FILE}"
        ;;
    
    edit)
        # 先备份再编辑
        "$0" backup
        
        if [ -n "${2:-}" ]; then
            # 如果有提供内容，追加到文件
            echo -e "\n${2}" >> "${MEMORY_FILE}"
            echo "✅ MEMORY.md 已更新"
        else
            echo "ℹ️ 备份完成，请手动编辑 MEMORY.md"
            echo "   文件：${MEMORY_FILE}"
            echo "   备份：${BACKUP_FILE}"
        fi
        ;;
    
    restore)
        # 从备份恢复
        if [ -f "${BACKUP_FILE}" ]; then
            cp "${BACKUP_FILE}" "${MEMORY_FILE}"
            echo "✅ 已从备份恢复 MEMORY.md"
        else
            echo "❌ 备份文件不存在：${BACKUP_FILE}"
            exit 1
        fi
        ;;
    
    *)
        echo "用法：$0 <backup|edit|restore> [内容]"
        echo ""
        echo "操作:"
        echo "  backup  - 备份 MEMORY.md"
        echo "  edit    - 先备份再编辑"
        echo "  restore - 从备份恢复"
        exit 1
        ;;
esac
