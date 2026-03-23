# 回滚指南

## 备份文件位置
```
/root/.openclaw/workspace/backups/
├── memory_YYYYMMDD_HHMMSS.tar.gz
├── learnings_YYYYMMDD_HHMMSS.tar.gz
├── config_YYYYMMDD_HHMMSS.tar.gz
├── memos_YYYYMMDD_HHMMSS.tar.gz
├── searxng_YYYYMMDD_HHMMSS.tar.gz
└── backup_history.txt
```

## 查看备份历史
```bash
cat /root/.openclaw/workspace/backups/backup_history.txt
ls -lt /root/.openclaw/workspace/backups/*.tar.gz
```

## 回滚操作

### 回滚记忆系统
```bash
cd /root/.openclaw/workspace
# 选择要回滚的备份文件
BACKUP_FILE="backups/memory_20260304_230000.tar.gz"

# 先备份当前状态（安全起见）
tar -czf backups/before_rollback_$(date +%Y%m%d_%H%M%S).tar.gz memory/

# 回滚
tar -xzf "$BACKUP_FILE"

# 验证
ls -la memory/
```

### 回滚学习日志
```bash
cd /root/.openclaw/workspace
BACKUP_FILE="backups/learnings_20260304_230000.tar.gz"
tar -xzf "$BACKUP_FILE"
```

### 回滚配置
```bash
cd /root/.openclaw/workspace
BACKUP_FILE="backups/config_20260304_230000.tar.gz"
tar -xzf "$BACKUP_FILE"
```

### 回滚 Docker 数据
```bash
# Memos
cd ~
BACKUP_FILE="/root/.openclaw/workspace/backups/memos_20260304_230000.tar.gz"
tar -xzf "$BACKUP_FILE"
docker restart memos

# SearXNG
BACKUP_FILE="/root/.openclaw/workspace/backups/searxng_20260304_230000.tar.gz"
tar -xzf "$BACKUP_FILE"
docker restart searxng
```

## 完整系统回滚

### 步骤 1：停止服务
```bash
docker stop memos searxng 2>/dev/null || true
```

### 步骤 2：回滚所有组件
```bash
cd /root/.openclaw/workspace

# 备份当前状态
tar -czf backups/emergency_$(date +%Y%m%d_%H%M%S).tar.gz \
    memory/ .learnings/ AGENTS.md SOUL.md TOOLS.md MEMORY.md 2>/dev/null

# 回滚
for backup in memory learnings config; do
    FILE=$(ls -t backups/${backup}_*.tar.gz | head -1)
    if [ -f "$FILE" ]; then
        echo "回滚 $FILE"
        tar -xzf "$FILE"
    fi
done
```

### 步骤 3：恢复 Docker 数据
```bash
cd ~
for backup in memos searxng; do
    FILE=$(ls -t /root/.openclaw/workspace/backups/${backup}_*.tar.gz | head -1)
    if [ -f "$FILE" ]; then
        echo "回滚 $FILE"
        tar -xzf "$FILE"
    fi
done
```

### 步骤 4：重启服务
```bash
docker start memos searxng
```

### 步骤 5：验证
```bash
# 检查服务状态
docker ps

# 检查记忆系统
ls -la /root/.openclaw/workspace/memory/

# 检查学习日志
ls -la /root/.openclaw/workspace/.learnings/
```

## 紧急恢复

如果系统完全无法启动：

```bash
# 1. 找到最近的完整备份
ls -lt /root/.openclaw/workspace/backups/*.tar.gz

# 2. 解压到临时目录
mkdir -p /tmp/rollback_test
tar -xzf backups/memory_YYYYMMDD_HHMMSS.tar.gz -C /tmp/rollback_test

# 3. 检查内容
ls -la /tmp/rollback_test/memory/

# 4. 确认无误后正式回滚
# （按上面的回滚步骤执行）
```

## 备份验证

定期验证备份完整性：

```bash
cd /root/.openclaw/workspace/backups
for file in *.tar.gz; do
    echo -n "验证 $file: "
    if tar -tzf "$file" >/dev/null 2>&1; then
        echo "✓ OK"
    else
        echo "✗ 损坏"
    fi
done
```
