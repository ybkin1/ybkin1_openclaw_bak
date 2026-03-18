#!/bin/bash
set -e
MANIFEST="./monthly-archives/manifest.json"
ARCHIVE=$(jq -r '.archive' "$MANIFEST")
echo "恢复最新备份: $ARCHIVE"
tar -xzf "./monthly-archives/$ARCHIVE" -C /tmp/restore-$$
/root/.openclaw/workspace/agents/backup/scripts/restore-from-backup.js /tmp/restore-$$ || { echo "恢复失败"; exit 1; }
echo "恢复完成"
