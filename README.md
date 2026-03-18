# OpenClaw 系统备份仓库

## 内容
- `monthly-archives/` - 月度全量备份
- `restore-scripts/` - 恢复工具

## 最新备份
- 时间戳: 20260318_144214
- 归档: full_20260318_144214.tar.gz
- 文件数: 784

## 恢复
```bash
tar -xzf monthly-archives/full_20260318_144214.tar.gz -C /tmp/restore
/root/.openclaw/workspace/agents/backup/scripts/restore-from-backup.js /tmp/restore
```
